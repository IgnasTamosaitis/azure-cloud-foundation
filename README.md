# Azure Cloud Foundation

A hands-on Infrastructure as Code (IaC) project for provisioning and managing Azure networking infrastructure using Terraform and GitHub Actions.

The project demonstrates remote Terraform state management, CI/CD automation, passwordless Azure authentication, least-privilege access, infrastructure security scanning, and controlled deployments.

## Architecture

The infrastructure is deployed in **Azure North Europe** using Terraform.

| Resource               | Configuration                                    |
| ---------------------- | ------------------------------------------------ |
| Resource Group         | `rg-cloud-foundation-dev`                      |
| Virtual Network        | `vnet-cloud-foundation-dev` (`10.40.0.0/16`) |
| Application Subnet     | `snet-app` (`10.40.1.0/24`)                  |
| Data Subnet            | `snet-data` (`10.40.2.0/24`)                 |
| Network Security Group | `nsg-data-dev`                                 |

The Network Security Group is associated with the data subnet and denies outbound traffic to the Azure `Internet` service tag.

**Note:** This rule does not isolate the application and data subnets from each other.

## Technology Stack

- **Microsoft Azure** – Cloud infrastructure and networking
- **Terraform** – Infrastructure as Code
- **Azure Blob Storage** – Remote Terraform state
- **GitHub Actions** – CI/CD pipelines
- **Microsoft Entra ID & OIDC** – Passwordless workload authentication
- **Azure RBAC** – Role-based access control
- **Trivy** – Infrastructure configuration security scanning

## Terraform Remote State

Terraform state is stored in an Azure Blob Storage backend, separate from the managed infrastructure.

The backend provides:

- Centralized state storage
- Azure Blob lease-based state locking
- Microsoft Entra ID authentication
- Blob versioning and 7-day soft delete
- Disabled Shared Key authentication and public blob access
- HTTPS-only connections with minimum TLS 1.2

The backend storage account is provisioned separately and must exist before running `terraform init`.

## CI/CD Pipelines

### Terraform CI

Triggered automatically on pushes and pull requests targeting `master`.

The pipeline performs:

1. Terraform initialization without connecting to the remote backend
2. Terraform formatting validation
3. Terraform configuration validation
4. Trivy IaC security scanning (HIGH and CRITICAL findings fail validation)
5. Terraform Plan on pushes to `master`

### Terraform Deploy

Triggered manually through GitHub Actions.

The deployment workflow:

1. Validates Terraform configuration and runs Trivy.
2. Authenticates to Azure using a planning Service Principal and OIDC.
3. Generates a saved Terraform execution plan.
4. Stores the plan in private Azure Blob Storage.
5. Waits for approval through the GitHub `dev` environment.
6. Authenticates using a separate deployment Service Principal.
7. Downloads the previously generated plan and verifies its SHA-256 checksum.
8. Applies the approved execution plan.
9. Attempts to delete the stored plan after execution.

This separates infrastructure planning from deployment permissions and prevents the Apply job from silently generating a different execution plan.

## Identity and Access Management

Two separate Microsoft Entra ID Service Principals are used:

| Identity        | Azure RBAC Permissions                                                                         | Purpose                                                               |
| --------------- | ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Plan identity   | Reader on infrastructure Resource Group; Storage Blob Data Contributor on state container      | Read infrastructure, manage Terraform state and store execution plans |
| Deploy identity | Contributor on infrastructure Resource Group; Storage Blob Data Contributor on state container | Apply approved infrastructure changes                                 |

Both identities authenticate through GitHub Actions OIDC federation without storing long-lived Azure client secrets.

**Known limitation:** The deployment identity cannot recreate the infrastructure Resource Group after deletion because its Contributor role is scoped to the existing Resource Group.

## Running Locally

**Prerequisites:**

- Azure subscription
- Terraform CLI
- Azure CLI
- Access to the existing Terraform state backend

Authenticate to Azure using PowerShell:

    az login
    az account set --subscription "<subscription-id></subscription>"
    $env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
    $env:ARM_USE_CLI = "true"

Initialize and validate Terraform:

    terraform init
    terraform fmt -check -recursive
    terraform validate
    terraform plan

For controlled deployments, use the **Terraform Deploy** GitHub Actions workflow rather than applying changes locally.

## Project Structure

| File                                       | Purpose                                |
| ------------------------------------------ | -------------------------------------- |
| `main.tf`                                | Resource Group                         |
| `network.tf`                             | Virtual Network and subnets            |
| `security.tf`                            | Network Security Group and association |
| `variables.tf`                           | Configurable infrastructure parameters |
| `outputs.tf`                             | Infrastructure outputs                 |
| `versions.tf`                            | Terraform and provider requirements    |
| `backend.tf`                             | Azure remote state configuration       |
| `.github/workflows/terraform-ci.yml`     | Continuous integration                 |
| `.github/workflows/terraform-deploy.yml` | Controlled infrastructure deployment   |

## Limitations and Future Improvements

This project focuses on foundational Azure infrastructure and deployment automation rather than production application hosting.

Potential improvements include:

- Automated cleanup of abandoned Terraform plan blobs
- More granular permissions for Terraform state and plan storage
- Additional Azure networking and security controls
- Automated testing of infrastructure changes

No virtual machines, containers, or application workloads are deployed.

## Learning Outcomes

Through this project, I gained practical experience with:

- Declarative infrastructure provisioning using Terraform
- Remote state management and state locking
- Azure networking and NSG configuration
- GitHub Actions CI/CD automation
- OIDC federation and Azure RBAC
- Security scanning and controlled infrastructure deployments
- Terraform deployment reproducibility and troubleshooting
