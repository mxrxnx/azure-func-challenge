# Azure Function App - Technical Challenge
## Architecture
This project deploys an HTTP-triggered Azure Function (Hello World) using
Terraform to provision all required infrastructure on the Azure Consumption
(Free) plan.
### Resources Created
- Resource Group
- Storage Account (LRS, required by Azure Functions runtime)
- Log Analytics Workspace + Application Insights (monitoring)
- App Service Plan (Consumption Y1 - free tier)
- Linux Function App (.NET 8 isolated process)
## Prerequisites
| Tool | Version | Install |
|------|---------|---------|
| Azure CLI | >= 2.50 | [Install guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Terraform | >= 1.5 | [Install guide](https://developer.hashicorp.com/terraform/install) |
| .NET SDK | 8.0 | [Install guide](https://dotnet.microsoft.com/download/dotnet/8.0) |
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

By default every HTTP request must include a secret key, otherwise Azure returns a 401 Unauthorized response. This is a built-in security layer that prevents unauthorized access to your endpoints.

To retrieve the key:

```bash
az functionapp function keys list \
  --resource-group $(terraform -chdir=../terraform output -raw resource_group_name) \
  --name $(terraform -chdir=../terraform output -raw function_app_name) \
  --function-name httpget
```

## Validation

#### List all resources in the resource group

```bash
az resource list --resource-group rg-challange040526-dev --output table
```

#### Check the function app is running

```bash
az functionapp show \
  --resource-group rg-challange040526-dev \
  --name func-challange040526-dev \
  --query "state" -o tsv
```

Expected: Running

### Test the HTTP GET Function

```bash
curl "https://<function-app-name>.azurewebsites.net/api/httpget?code=<function-key>&name=World"
```
Expected response: `Hello, World!`

You can also paste the URL directly into any browser.


## Cleanup

Remove all Azure resources to avoid any charges:

```bash
cd terraform
terraform destroy
```

## Private Endpoint + Vnet (OPTIONAL)

### Limitation

The Consumption (Y1) plan used here does not support Private Endpoints. However the Private Endpoint 
resources are included in `terraform/main.tf` as commented-out code.

### Steps To Implement

To enable Private Endpoints, one change is required in `main.tf`:
```hcl
# Change the Service Plan SKU from:
sku_name = "Y1"      # Consumption (no VNet support)

# To one of:
sku_name = "FC1"     # Flex Consumption (serverless + VNet support)
sku_name = "EP1"     # Premium (always warm + VNet support)
```

Then uncomment the Private Endpoint resources in `main.tf`.

### Architecture with Private Endpoint

The commented code provides five networking resources:

1. **Virtual Network** (10.0.0.0/16) - an isolated private network in Azure
2. **Subnet** (10.0.1.0/24) - a dedicated slice of the VNet for private endpoints
3. **Private DNS Zone** (privatelink.azurewebsites.net) - resolves the 
   function's hostname to a private IP instead of a public one
4. **DNS Zone VNet Link** - connects the DNS zone to the VNet so internal 
   resources use private name resolution
5. **Private Endpoint** - creates a network interface with a private IP 
   that routes traffic to the Function App
