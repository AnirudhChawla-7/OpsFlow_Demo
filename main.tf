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
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_pipeline_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy_attachment" "codepipeline_codestar_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeStarFullAccess"
}

data "aws_caller_identity" "current" {}

# Inline Policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_inline" {
  name = "OpsFlow-CodePipeline-InlinePolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["codestar-connections:UseConnection"]
        Resource = "arn:aws:codeconnections:ap-south-1:977099008804:connection/0a596167-5e51-4e4e-9a01-a8880a219810"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Resource = "${aws_s3_bucket.artifact_bucket.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.artifact_bucket.arn
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = aws_codebuild_project.opsflow_build.arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetDeploymentConfig"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------
# CodeBuild Role
# ------------------------------
resource "aws_iam_role" "codebuild_role" {
  name = "OpsFlow-CodeBuild-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_dev_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_logs_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy" "codebuild_s3_access" {
  name = "OpsFlow-CodeBuild-S3Access"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Resource = "${aws_s3_bucket.artifact_bucket.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.artifact_bucket.arn
      }
    ]
  })
}

# ------------------------------
# CodeDeploy Role (FINAL FIX)
# ------------------------------
resource "aws_iam_role" "codedeploy_role" {
  name = "OpsFlow-CodeDeploy-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

# Attach Managed Policies
resource "aws_iam_role_policy_attachment" "codedeploy_service_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "codedeploy_ec2_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "codedeploy_s3_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# ------------------------------
# 3. EC2 Key Pair
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
  ami           = "ami-0ded8326293d3201b"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.opsflow_key.key_name
  vpc_security_group_ids = [aws_security_group.opsflow_sg.id]

  tags = {
    Name = "OpsFlow-EC2"
  }

  # Install CodeDeploy Agent also
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git ruby wget
              systemctl start docker
              systemctl enable docker
              cd /home/ec2-user
              wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              systemctl enable codedeploy-agent
              systemctl start codedeploy-agent
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
  app_name               = aws_codedeploy_app.opsflow_app.name
  deployment_group_name  = "OpsFlow-DeploymentGroup"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "OpsFlow-EC2"
    }
  }
}

# ------------------------------
# 7. CodePipeline
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
        FullRepositoryId = "AnirudhChawla-7/OpsFlow_Demo"
        BranchName       = "main"
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
