provider "aws" {
  region = "ap-south-1"
}

resource "aws_key_pair" "opsflow_key" {
  key_name   = "opsflow-key"
  public_key = file("C:/Users/Anirudh Chawla/.ssh/opsflow-key.pub")
}

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
  ami           = "ami-0ded8326293d3201b" # Ubuntu 24.04 (Mumbai region)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.opsflow_key.key_name
  security_groups = [aws_security_group.opsflow_sg.name]

  tags = {
    Name = "OpsFlow-EC2"
  }
}
