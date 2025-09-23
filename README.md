# 🚀 OpsFlow — CI/CD Pipeline on AWS

OpsFlow is a **Node.js web application** deployed automatically using **AWS CodePipeline, CodeBuild, CodeDeploy, and EC2**.  
The project demonstrates **Infrastructure as Code (Terraform)** and **continuous delivery of a Node.js app** from GitHub to an EC2 instance.

---

## 📌 Features
- Full **CI/CD pipeline** with AWS CodePipeline
- **Terraform** used to provision:
  - S3 (artifacts)
  - IAM roles & policies
  - CodeBuild project
  - CodeDeploy application & deployment group
  - EC2 instance with CodeDeploy agent
- **AppSpec.yml + lifecycle hooks** to manage deployments
- **Node.js app** deployment with scripts:
  - `install_dependencies.sh`
  - `start_server.sh`
  - `stop_server.sh`
  - `clean_old.sh`
- Secure key handling (`.gitignore` excludes private keys)

---

## 🏗️ Architecture

```text
GitHub (Source) → CodePipeline → CodeBuild → S3 Artifacts → CodeDeploy → EC2 (OpsFlow App)
