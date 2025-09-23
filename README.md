# 🚀 OpsFlow — CI/CD Pipeline on AWS

OpsFlow is a **CI/CD Pipeline Project** deployed automatically using **AWS CodePipeline, CodeBuild, CodeDeploy, and EC2**.  
The project demonstrates **Infrastructure as Code (Terraform)** and **continuous delivery of a Node.js backend** from GitHub to an EC2 instance.

-------

## 📌 Features
- Full **CI/CD pipeline** with AWS CodePipeline
- **Terraform** used to provision:
  - S3 (artifacts)
  - IAM roles & policies
  - CodeBuild project
  - CodeDeploy application & deployment group
  - EC2 instance with CodeDeploy agent
- **AppSpec.yml + lifecycle hooks** to manage deployments
- **Node.js Backend** deployment with scripts:
  - `install_dependencies.sh`
  - `start_server.sh`
  - `stop_server.sh`
  - `clean_old.sh`
- Secure key handling (`.gitignore` excludes private keys)

---

## 🏗️ Architecture
<img width="1308" height="1175" alt="Architectural_Diagram_OpsFlow" src="https://github.com/user-attachments/assets/a13d9fb0-2f81-4907-8216-549e2e326613" />

```text
GitHub (Source) → CodePipeline → CodeBuild → S3 Artifacts → CodeDeploy → EC2 (OpsFlow App)
