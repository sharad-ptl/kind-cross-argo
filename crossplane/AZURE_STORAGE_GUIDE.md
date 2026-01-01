# Using Azure Storage Provider with Crossplane

This guide explains how to use the Azure Storage provider to create storage accounts in Azure using Crossplane.

## Prerequisites

1. **Azure Account**: You need an active Azure subscription
2. **Azure CLI**: Install and configure Azure CLI
3. **Service Principal**: Create an Azure Service Principal with appropriate permissions

## Step 1: Install the Provider

The provider is already defined in `provider-azure-storage.yaml`. Apply it:

```bash
kubectl apply -f crossplane/provider-azure-storage.yaml
```

Wait for the provider to be ready:

```bash
kubectl wait --for=condition=healthy provider/upbound-provider-azure-storage --timeout=300s
```

## Step 2: Create Azure Service Principal

You need to create a Service Principal in Azure that Crossplane will use to authenticate:

```bash
# Login to Azure
az login

# Set your subscription (replace with your subscription ID)
az account set --subscription <your-subscription-id>

# Create a service principal with Contributor role
az ad sp create-for-rbac --name crossplane-azure-storage \
  --role contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

This will output JSON with credentials. Save this output.

## Step 3: Create Kubernetes Secret

Create a Kubernetes secret with the Azure credentials. The Upbound provider expects credentials in a specific JSON format.

**Option A: Using the service principal JSON directly** (Recommended):

```bash
# Save the service principal output to a file
az ad sp create-for-rbac --name crossplane-azure-storage \
  --role contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth > azure-credentials.json

# Create the secret from the file
kubectl create secret generic azure-credentials \
  --from-file=credentials=./azure-credentials.json \
  --namespace crossplane-system
```

**Option B: Manual secret creation** (if you have the values separately):

```bash
kubectl create secret generic azure-credentials \
  --from-literal=credentials='{
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "subscriptionId": "your-subscription-id",
    "tenantId": "your-tenant-id",
    "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
    "resourceManagerEndpointUrl": "https://management.azure.com/",
    "activeDirectoryGraphResourceId": "https://graph.windows.net/",
    "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
    "galleryEndpointUrl": "https://gallery.azure.com/",
    "managementEndpointUrl": "https://management.core.windows.net/"
  }' \
  --namespace crossplane-system
```

**Note**: The `--sdk-auth` flag outputs credentials in the exact format needed by the Upbound provider.

## Step 4: Create ProviderConfig

Apply the ProviderConfig that references the secret:

```bash
kubectl apply -f crossplane/providerconfig-azure.yaml
```

Verify it's ready:

```bash
kubectl get providerconfig.azure.upbound.io default
```

## Step 5: Create a Resource Group (Required)

Storage accounts must be created within a resource group. You have two options:

### Option A: Create Resource Group with Crossplane

```bash
# Apply the resource group resource
kubectl apply -f crossplane/azure-resource-group-example.yaml

# Wait for it to be ready
kubectl wait --for=condition=ready resourcegroup/example-resource-group --timeout=300s
```

### Option B: Create Resource Group with Azure CLI

```bash
az group create --name my-resource-group --location "East US"
```

**Note**: If using Option B, make sure the resource group name in your storage account YAML matches the one you created.

## Step 6: Create a Storage Account

### Option A: Direct Resource (Simple)

Create a storage account directly using the managed resource:

```bash
# Apply the storage account resource
kubectl apply -f crossplane/azure-storage-account-example.yaml
```

**Important**: Update `resourceGroupName` in `azure-storage-account-example.yaml` to match your resource group name.

Check the status:

```bash
kubectl get account example-storage-account
kubectl describe account example-storage-account
```

### Option B: Using a Composition (Advanced)

For a more reusable approach, you can create a Composition that abstracts the storage account creation. See the example below.

## Example: Storage Account Resource

The `azure-storage-account-example.yaml` file shows a basic storage account configuration:

```yaml
apiVersion: storage.azure.upbound.io/v1beta1
kind: Account
metadata:
  name: example-storage-account
spec:
  providerConfigRef:
    name: default
  forProvider:
    location: "East US"
    resourceGroupName: "my-resource-group"
    accountTier: "Standard"
    accountReplicationType: "LRS"
    tags:
      environment: "dev"
      managed-by: "crossplane"
```

### Key Fields:

- **location**: Azure region where the storage account will be created
- **resourceGroupName**: Name of the Azure Resource Group (must exist)
- **accountTier**: Storage account tier (`Standard` or `Premium`)
- **accountReplicationType**: Replication type:
  - `LRS` - Locally Redundant Storage
  - `GRS` - Geo-Redundant Storage
  - `RAGRS` - Read-Access Geo-Redundant Storage
  - `ZRS` - Zone Redundant Storage

## Verify Storage Account Creation

1. **In Kubernetes**:
   ```bash
   kubectl get account
   kubectl describe account example-storage-account
   ```

2. **In Azure Portal**:
   - Go to Azure Portal → Storage accounts
   - You should see your storage account listed

3. **Using Azure CLI**:
   ```bash
   az storage account list --resource-group my-resource-group
   ```

## Resource Group Management

If you created the resource group using Crossplane (`azure-resource-group-example.yaml`), you can manage it through Kubernetes:

```bash
# Check resource group status
kubectl get resourcegroup example-resource-group

# View details
kubectl describe resourcegroup example-resource-group

# Delete resource group (will also delete all resources in it)
kubectl delete resourcegroup example-resource-group
```

**Warning**: Deleting a resource group will delete all resources within it, including storage accounts!

## Troubleshooting

### Provider not healthy
```bash
kubectl describe provider upbound-provider-azure-storage
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=upbound-provider-azure-storage
```

### Storage account creation failing
```bash
kubectl describe account example-storage-account
kubectl get events --sort-by='.lastTimestamp' | grep example-storage-account
```

### Authentication issues
- Verify the secret exists: `kubectl get secret azure-credentials -n crossplane-system`
- Check the secret format: `kubectl get secret azure-credentials -n crossplane-system -o jsonpath='{.data.credentials}' | base64 -d`
- Ensure the service principal has Contributor role on the subscription

## Cleanup

To delete the storage account:

```bash
kubectl delete account example-storage-account
```

This will delete the storage account from Azure as well (if the deletion policy allows).

## Additional Resources

- [Upbound Azure Storage Provider Documentation](https://marketplace.upbound.io/providers/upbound/provider-azure-storage/)
- [Crossplane Azure Provider Guide](https://docs.crossplane.io/latest/concepts/providers/)
- [Azure Storage Account Documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)

