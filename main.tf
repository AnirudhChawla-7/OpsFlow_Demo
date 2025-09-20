provider "aws" {
  region = "ap-south-1"
}

# ------------------------------
# 1. S3 Bucket for artifacts
# ------------------------------
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "opsflow-artifacts-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# ------------------------------
# 2. IAM Roles
# ------------------------------

# CodePipeline Role
resource "aws_iam_role" "codepipeline_role" {
  name = "OpsFlow-CodePipeline-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS Managed Policies
resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy_attachment" "codepipeline_codestar_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeStarFullAccess"
}

# Inline Policy for GitHub Connection
resource "aws_iam_role_policy" "codepipeline_codestar_policy" {
  name = "OpsFlow-CodePipeline-CodeStarPolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection"]
        Resource = "arn:aws:codeconnections:ap-south-1:977099008804:connection/0a596167-5e51-4e4e-9a01-a8880a219810"
      }
    ]
  })
}

# CodeBuild Role
resource "aws_iam_role" "codebuild_role" {
  name = "OpsFlow-CodeBuild-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

# CodeDeploy Role
resource "aws_iam_role" "codedeploy_role" {
  name = "OpsFlow-CodeDeploy-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

# ------------------------------
# 3. Key Pair (for EC2 SSH)
# ------------------------------
resource "aws_key_pair" "opsflow_key" {
  key_name   = "opsflow-key"
  public_key = file("C:/Users/Anirudh Chawla/.ssh/opsflow-key.pub")
}

# ------------------------------
# 4. EC2 Instance + Security Group
# ------------------------------
resource "aws_security_group" "opsflow_sg" {
  name        = "opsflow-sg"
  description = "Allow SSH and App traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "opsflow_ec2" {
  ami           = "ami-0ded8326293d3201b" # Amazon Linux 2023 in ap-south-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.opsflow_key.key_name

  vpc_security_group_ids = [aws_security_group.opsflow_sg.id]

  tags = {
    Name = "OpsFlow-EC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl start docker
              systemctl enable docker
              EOF
}

# ------------------------------
# 5. CodeBuild Project
# ------------------------------
resource "aws_codebuild_project" "opsflow_build" {
  name          = "OpsFlow-Build"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 5

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type = "CODEPIPELINE"
  }
}

# ------------------------------
# 6. CodeDeploy App + Group
# ------------------------------
resource "aws_codedeploy_app" "opsflow_app" {
  name             = "OpsFlow-App"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "opsflow_group" {
  app_name              = aws_codedeploy_app.opsflow_app.name
  deployment_group_name = "OpsFlow-DeploymentGroup"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "OpsFlow-EC2"
    }
  }
}

# ------------------------------
# 7. CodePipeline (GitHub v2 via CodeStar Connection)
# ------------------------------
resource "aws_codepipeline" "opsflow_pipeline" {
  name     = "OpsFlow-Pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn    = "arn:aws:codeconnections:ap-south-1:977099008804:connection/0a596167-5e51-4e4e-9a01-a8880a219810"
        FullRepositoryId = "AnirudhChawla-7/OpsFlow_Demo"   # ✅ exact repo name
        BranchName       = "main"                          # ✅ branch name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.opsflow_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["BuildOutput"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.opsflow_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.opsflow_group.deployment_group_name
      }
    }
  }
}
