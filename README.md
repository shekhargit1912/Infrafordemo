# Infrafordemo

This project contains Terraform code to provision AWS infrastructure for a demo environment, including VPC, subnets, NAT gateway, and EKS cluster.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS CLI configured with appropriate credentials
- An AWS account

## Usage

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd Infrafordemo
   ```

2. **Initialize Terraform:**
   ```sh
   terraform init
   ```

3. **Plan the deployment:**
   ```sh
   terraform plan -var-file="envs/dev/dev.tfvars"
   ```

4. **Apply the deployment:**
   ```sh
   terraform apply -var-file="envs/dev/dev.tfvars"
   ```

5. **Destroy the deployment:**
   ```sh
   terraform destroy -var-file="envs/dev/dev.tfvars"
   ```

## Project Structure

- `main.tf` - Root Terraform configuration
- `modules/` - Reusable Terraform modules (VPC, EKS, etc.)
- `envs/dev/dev.tfvars` - Variable values for the dev environment
- `variables.tf` - Input variable definitions

## Notes

- **Do not commit your `terraform.tfstate` files to version control.**
- Update the variable values in `envs/dev/dev.tfvars` as needed for your environment.

---

Feel free to expand this README with more details about your modules, variables, or


