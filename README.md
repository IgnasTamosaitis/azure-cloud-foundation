
# Azure Cloud Foundation

A hands-on Infrastructure as Code (IaC) project for provisioning and managing Azure networking infrastructure using Terraform and GitHub Actions.

The project demonstrates remote Terraform state management, CI/CD automation, passwordless Azure authentication, role-based access control, infrastructure security scanning, and controlled deployments.

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

**Note:** The backend configuration references an existing Azure Storage Account. To reproduce this project in another subscription, provision your own state storage and update `backend.tf` accordingly.

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
8. Applies the saved execution plan.
9. Attempts to delete the stored plan after execution.

This separates infrastructure planning from deployment permissions and prevents the Apply job from generating a different execution plan.

## Identity and Access Management

Two separate Microsoft Entra ID Service Principals are used:

| Identity        | Azure RBAC Permissions                                                                         | Purpose                                                               |
| --------------- | ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Plan identity   | Reader on infrastructure Resource Group; Storage Blob Data Contributor on state container      | Read infrastructure, access Terraform state and store execution plans |
| Deploy identity | Contributor on infrastructure Resource Group; Storage Blob Data Contributor on state container | Apply approved infrastructure changes                                 |

Both identities authenticate through GitHub Actions OIDC federation without storing long-lived Azure client secrets.

The planning identity cannot modify Azure infrastructure resources. However, its Storage Blob Data Contributor role permits changes to the Terraform state container.

**Known limitation:** The deployment identity cannot recreate the infrastructure Resource Group after deletion because its Contributor role is scoped to the existing Resource Group.

## GitHub Actions Configuration

The workflows require Azure identity configuration and GitHub repository variables.

### Repository Variables

Configure the following under **Settings → Secrets and variables → Actions → Variables**:

| Variable                   | Description                                        |
| -------------------------- | -------------------------------------------------- |
| `AZURE_CLIENT_ID`        | Application (client) ID of the planning identity   |
| `AZURE_DEPLOY_CLIENT_ID` | Application (client) ID of the deployment identity |
| `AZURE_TENANT_ID`        | Microsoft Entra tenant ID                          |
| `AZURE_SUBSCRIPTION_ID`  | Target Azure subscription ID                       |

### OIDC Federation

Configure federated identity credentials in Microsoft Entra ID for both Service Principals.

- The planning identity must trust the appropriate GitHub Actions branch context.
- The deployment identity must trust the GitHub `dev` environment context.
- Federated identity subjects must match the claims issued by GitHub Actions.
- Azure RBAC permissions must be configured separately.

No Azure client secrets are required.

### Deployment Approval

Create a GitHub Environment named `dev` and configure:

- Required reviewer approval
- Deployment branch restriction to `master`

The deployment workflow uses this environment to require approval before Terraform Apply.

## Running Locally

### Prerequisites

- Azure subscription
- Terraform CLI
- Azure CLI
- Access to the existing Terraform state backend

Authenticate to Azure using PowerShell:

```powershell
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
$env:ARM_USE_CLI = "true"
```

Initialize and validate Terraform:

```powershell
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Check infrastructure outputs:

```powershell
terraform output
```

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

Terraform plan blobs may remain in storage if deployments are cancelled before cleanup. Blob versioning and soft delete can also retain deleted plan data temporarily.

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
