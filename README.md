# Azure Function App — Technical Challenge
## Architecture
This project deploys an HTTP-triggered Azure Function (Hello World) using
Terraform to provision all required infrastructure on the Azure Consumption
(Free) plan.
### Resources Created
- Resource Group
- Storage Account (LRS, required by Azure Functions runtime)
- Log Analytics Workspace + Application Insights (monitoring)
- App Service Plan (Consumption Y1 — free tier)
- Linux Function App (.NET 8 isolated process)
## Prerequisites
| Tool | Version | Install |
|------|---------|---------|
| Azure CLI | >= 2.50 | [Install guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Terraform | >= 1.5 | [Install guide](https://developer.hashicorp.com/terraform/install) |
| .NET SDK | 8.0 | [Download](https://dotnet.microsoft.com/download/dotnet/8.0) |
| Azure Functions Core Tools | v4 | [Install guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) |
## Deployment Steps
### 1. Authenticate to Azure
```bash
az login
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```
### 2. Initialize and Apply Terraform
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```
### 3. Deploy the Function Code
```bash
cd ../function/http
func azure functionapp publish $(terraform -chdir=../terraform output -raw function_app_name)
```
### 4. Get the Function Key

Azure Functions use `AuthorizationLevel.Function` by default, which means every HTTP request must include a secret key — otherwise Azure returns a 401 Unauthorized response. This is a built-in security layer that prevents unauthorized access to your endpoints.

To retrieve the key:

```bash
az functionapp function keys list \
  --resource-group $(terraform -chdir=../terraform output -raw resource_group_name) \
  --name $(terraform -chdir=../terraform output -raw function_app_name) \
  --function-name httpget
```

## Validation
```bash
curl "https://<function-app-name>.azurewebsites.net/api/httpget?code=<function-key>&name=World"
```
Expected response: `Hello, World!`

## Cleanup
```bash
cd terraform
terraform destroy
```
