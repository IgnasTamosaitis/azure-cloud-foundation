# Azure Cloud Foundation

A small Azure Terraform project for deploying basic Azure networking infrastructure. Built as hands-on practice with IaC.

## Resources

- Resource Group in North Europe
- Virtual Network (`10.40.0.0/16`)
- Application subnet (`10.40.1.0/24`)
- Data subnet (`10.40.2.0/24`)
- Network Security Group associated with the data subnet, with a rule denying outbound traffic to the Azure `Internet` service tag

The configuration uses input variables for the region, environment tag, and network address ranges. Terraform outputs expose the Resource Group name and network resource IDs.

## Deploy

Requires an Azure subscription, Azure CLI, and Terraform. Commands below use PowerShell.

```powershell
az login
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv

terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Check the deployment:

```powershell
terraform output
terraform plan
```

Remove the resources when finished:

```powershell
terraform destroy
```

## Notes

- Terraform state is currently stored locally.
- The NSG rule restricts outbound Internet traffic from the data subnet. It does not isolate the two subnets from each other.
- No application workloads or network traffic tests are included.
