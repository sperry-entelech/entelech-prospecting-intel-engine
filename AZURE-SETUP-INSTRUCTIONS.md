# Azure Integration Setup Instructions for Entelech Prospect Intelligence Engine

## Overview

This guide provides step-by-step instructions for setting up the complete Azure infrastructure and n8n workflow integration for the Entelech Prospect Intelligence Engine. Follow these instructions carefully to ensure proper deployment and security configuration.

## Prerequisites

- Azure subscription with appropriate permissions
- n8n instance (self-hosted or cloud)
- ConvertKit account for CRM integration
- Basic knowledge of Azure services and n8n workflows

## Phase 1: Azure OpenAI Service Setup

### 1.1 Create Azure OpenAI Resource

```bash
# Create resource group
az group create --name rg-entelech-prospect-intelligence --location eastus

# Create Azure OpenAI service
az cognitiveservices account create \
  --name entelech-openai-service \
  --resource-group rg-entelech-prospect-intelligence \
  --kind OpenAI \
  --sku S0 \
  --location eastus \
  --custom-domain entelech-openai-unique-domain
```

### 1.2 Deploy GPT-4 Model

1. Navigate to Azure OpenAI Studio: https://oai.azure.com/
2. Select your OpenAI resource
3. Go to **Deployments** → **Create new deployment**
4. Configure deployment:
   - **Model**: `gpt-4`
   - **Model version**: Latest available
   - **Deployment name**: `gpt-4`
   - **Tokens per minute rate limit**: `60` (adjust based on usage)

### 1.3 Configure API Access

1. In Azure Portal, navigate to your OpenAI resource
2. Go to **Keys and Endpoint**
3. Copy **Key 1** and **Endpoint URL**
4. Update environment variables:
   ```bash
   AZURE_OPENAI_ENDPOINT=https://entelech-openai-unique-domain.openai.azure.com/
   AZURE_OPENAI_API_KEY=your-copied-api-key-here
   ```

## Phase 2: PostgreSQL Database Setup

### 2.1 Create Azure Database for PostgreSQL

```bash
# Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group rg-entelech-prospect-intelligence \
  --name entelech-postgres-server \
  --location eastus \
  --admin-user postgres_admin \
  --admin-password "YourSecurePassword123!" \
  --sku-name Standard_D2s_v3 \
  --tier GeneralPurpose \
  --storage-size 128 \
  --version 14 \
  --high-availability Enabled
```

### 2.2 Configure Database Security

```bash
# Configure firewall rules for n8n access
az postgres flexible-server firewall-rule create \
  --resource-group rg-entelech-prospect-intelligence \
  --name entelech-postgres-server \
  --rule-name AllowN8NAccess \
  --start-ip-address YOUR_N8N_SERVER_IP \
  --end-ip-address YOUR_N8N_SERVER_IP

# Enable SSL/TLS enforcement
az postgres flexible-server parameter set \
  --resource-group rg-entelech-prospect-intelligence \
  --server-name entelech-postgres-server \
  --name ssl \
  --value on
```

### 2.3 Create Database Schema

Connect to your PostgreSQL instance and run the following SQL:

```sql
-- Create database
CREATE DATABASE entelech_prospect_intelligence;

-- Connect to the database
\c entelech_prospect_intelligence;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Execute the complete schema from our previous database schema file
-- (Include all tables: prospect_analyses, automation_opportunities, reports, etc.)
```

## Phase 3: Azure Blob Storage Setup

### 3.1 Create Storage Account

```bash
# Create storage account
az storage account create \
  --name entelechtprospectdata \
  --resource-group rg-entelech-prospect-intelligence \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --encryption-services blob \
  --https-only true
```

### 3.2 Create Container for Reports

```bash
# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --resource-group rg-entelech-prospect-intelligence \
  --account-name entelechtprospectdata \
  --query '[0].value' --output tsv)

# Create container for PDF reports
az storage container create \
  --name prospect-reports \
  --account-name entelechtprospectdata \
  --account-key $STORAGE_KEY \
  --public-access off
```

### 3.3 Configure CORS (if needed for direct web access)

```bash
# Configure CORS for web access
az storage cors add \
  --account-name entelechtprospectdata \
  --account-key $STORAGE_KEY \
  --services b \
  --methods GET POST PUT \
  --origins https://app.entelech.ai \
  --allowed-headers '*' \
  --exposed-headers '*' \
  --max-age 3600
```

## Phase 4: n8n Configuration

### 4.1 Environment Variables Setup

1. Copy the `n8n-environment-variables.env` file to your n8n installation
2. Update all variables with your actual Azure values:

```bash
# Essential variables to configure
AZURE_OPENAI_ENDPOINT=https://entelech-openai-unique-domain.openai.azure.com/
AZURE_OPENAI_API_KEY=your-actual-api-key
POSTGRES_HOST=entelech-postgres-server.postgres.database.azure.com
POSTGRES_PASSWORD=YourSecurePassword123!
AZURE_STORAGE_ACCOUNT=entelechtprospectdata
AZURE_STORAGE_KEY=your-storage-key
AZURE_STORAGE_CONTAINER=prospect-reports
```

### 4.2 Install Required n8n Nodes

Ensure your n8n instance has these nodes installed:

```bash
# Core nodes (usually pre-installed)
- HTTP Request
- Webhook
- Code (JavaScript)
- PostgreSQL
- If conditions
- Respond to Webhook

# Additional nodes to install
- OpenAI (for Azure OpenAI integration)
- Microsoft Azure (for Blob Storage)
- ConvertKit (for CRM integration)
```

### 4.3 Create Database Credentials in n8n

1. Go to n8n **Settings** → **Credentials**
2. Create **PostgreSQL** credential:
   - **Name**: `Azure PostgreSQL`
   - **Host**: `entelech-postgres-server.postgres.database.azure.com`
   - **Database**: `entelech_prospect_intelligence`
   - **User**: `postgres_admin`
   - **Password**: `YourSecurePassword123!`
   - **Port**: `5432`
   - **SSL**: `require`

3. Create **Microsoft Azure** credential:
   - **Name**: `Azure Storage Account`
   - **Account Name**: `entelechtprospectdata`
   - **Account Key**: `your-storage-key`

4. Create **ConvertKit** credential:
   - **Name**: `ConvertKit API`
   - **API Key**: `your-convertkit-api-key`
   - **API Secret**: `your-convertkit-api-secret`

## Phase 5: PDF Generation Service Setup

### 5.1 Deploy Puppeteer Service (Docker)

Create a `docker-compose.yml` for PDF generation:

```yaml
version: '3.8'
services:
  puppeteer-pdf:
    image: browserless/chrome:latest
    ports:
      - "3001:3000"
    environment:
      - TOKEN=your-pdf-service-token
      - MAX_CONCURRENT_SESSIONS=10
      - KEEP_ALIVE=true
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### 5.2 Create PDF Generation API

Create a simple Express.js service or use existing PDF APIs:

```bash
# Environment variable for PDF service
PUPPETEER_SERVICE_URL=http://localhost:3001
PUPPETEER_SERVICE_TOKEN=your-pdf-service-token
```

## Phase 6: Import n8n Workflows

### 6.1 Import Workflow Files

1. In n8n, go to **Workflows** → **Import from file**
2. Import each workflow file in this order:
   - `n8n-prospect-intelligence-website-scraper.json`
   - `n8n-prospect-intelligence-automation-opportunity.json`
   - `n8n-prospect-intelligence-report-generation.json`
   - `n8n-prospect-intelligence-crm-integration.json`

### 6.2 Configure Workflow Settings

For each imported workflow:

1. **Update Credentials**: Ensure all nodes use the correct credential references
2. **Activate Webhooks**: Activate each workflow to generate webhook URLs
3. **Test Connections**: Use the "Test" feature on each node to verify connectivity

### 6.3 Record Webhook URLs

After activation, record the generated webhook URLs:

```bash
# Example URLs (yours will be different)
WEBHOOK_WEBSITE_SCRAPER=https://your-n8n.com/webhook/website-analysis
WEBHOOK_OPPORTUNITY_DETECTION=https://your-n8n.com/webhook/automation-opportunity-detection
WEBHOOK_REPORT_GENERATION=https://your-n8n.com/webhook/report-generation
WEBHOOK_CRM_INTEGRATION=https://your-n8n.com/webhook/crm-integration
```

## Phase 7: Security Configuration

### 7.1 Network Security

```bash
# Create Network Security Group
az network nsg create \
  --resource-group rg-entelech-prospect-intelligence \
  --name entelech-nsg \
  --location eastus

# Allow HTTPS traffic
az network nsg rule create \
  --resource-group rg-entelech-prospect-intelligence \
  --nsg-name entelech-nsg \
  --name AllowHTTPS \
  --priority 100 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443 \
  --access Allow \
  --protocol Tcp
```

### 7.2 Key Vault Setup (Recommended)

```bash
# Create Key Vault for secure secret storage
az keyvault create \
  --name entelech-keyvault \
  --resource-group rg-entelech-prospect-intelligence \
  --location eastus \
  --sku standard

# Store secrets
az keyvault secret set --vault-name entelech-keyvault --name openai-api-key --value "your-api-key"
az keyvault secret set --vault-name entelech-keyvault --name postgres-password --value "YourSecurePassword123!"
az keyvault secret set --vault-name entelech-keyvault --name storage-key --value "your-storage-key"
```

### 7.3 Enable Monitoring

```bash
# Create Application Insights for monitoring
az monitor app-insights component create \
  --app entelech-prospect-intelligence \
  --location eastus \
  --resource-group rg-entelech-prospect-intelligence \
  --kind web
```

## Phase 8: Testing and Validation

### 8.1 End-to-End Testing

1. **Test Website Scraper**:
   ```bash
   curl -X POST https://your-n8n.com/webhook/website-analysis \
     -H "Content-Type: application/json" \
     -H "x-api-key: your-webhook-api-key" \
     -d '{"url": "https://example-business.com"}'
   ```

2. **Monitor Workflow Execution**: Check n8n execution logs for each workflow

3. **Verify Database Records**: Confirm data is being stored correctly in PostgreSQL

4. **Check File Generation**: Verify PDF reports are created in Azure Blob Storage

5. **Test CRM Integration**: Confirm contacts are being created in ConvertKit

### 8.2 Performance Optimization

```bash
# Monitor PostgreSQL performance
az postgres flexible-server show \
  --resource-group rg-entelech-prospect-intelligence \
  --name entelech-postgres-server

# Check storage metrics
az monitor metrics list \
  --resource "/subscriptions/YOUR_SUBSCRIPTION/resourceGroups/rg-entelech-prospect-intelligence/providers/Microsoft.Storage/storageAccounts/entelechtprospectdata" \
  --metric "UsedCapacity"
```

## Phase 9: Backup and Disaster Recovery

### 9.1 Database Backup Configuration

```bash
# Configure automated backups
az postgres flexible-server parameter set \
  --resource-group rg-entelech-prospect-intelligence \
  --server-name entelech-postgres-server \
  --name backup_retention_days \
  --value 30
```

### 9.2 Storage Backup

```bash
# Create backup storage account
az storage account create \
  --name entelechtbackups \
  --resource-group rg-entelech-prospect-intelligence \
  --location westus2 \
  --sku Standard_GRS \
  --kind StorageV2
```

## Phase 10: Production Deployment Checklist

### Pre-Deployment

- [ ] All environment variables configured
- [ ] Database schema deployed and tested
- [ ] All Azure services provisioned and configured
- [ ] n8n workflows imported and activated
- [ ] Credentials properly configured in n8n
- [ ] PDF generation service running
- [ ] ConvertKit integration tested

### Security Checklist

- [ ] All API keys secured in Azure Key Vault
- [ ] Network security groups properly configured
- [ ] SSL/TLS enabled on all endpoints
- [ ] Database firewall rules configured
- [ ] Webhook authentication enabled

### Monitoring Checklist

- [ ] Application Insights configured
- [ ] Database monitoring enabled
- [ ] Storage metrics configured
- [ ] n8n execution monitoring active
- [ ] Alert rules configured for critical failures

### Performance Checklist

- [ ] Database connection pooling configured
- [ ] OpenAI rate limiting configured
- [ ] Blob storage performance tier optimized
- [ ] n8n execution limits configured

## Troubleshooting Guide

### Common Issues

1. **OpenAI API Errors**:
   - Verify endpoint URL format includes `/` at the end
   - Check API key permissions and quotas
   - Monitor rate limiting

2. **Database Connection Issues**:
   - Verify firewall rules include your n8n server IP
   - Check SSL configuration requirements
   - Validate connection string format

3. **Blob Storage Access Issues**:
   - Confirm storage account key is current
   - Check container permissions
   - Verify CORS configuration if needed

4. **Webhook Failures**:
   - Validate API key configuration
   - Check n8n workflow activation status
   - Monitor execution logs for errors

### Support Resources

- Azure Documentation: https://docs.microsoft.com/azure/
- n8n Documentation: https://docs.n8n.io/
- OpenAI API Documentation: https://platform.openai.com/docs/
- ConvertKit API Documentation: https://developers.convertkit.com/

## Cost Optimization Tips

1. **Right-size PostgreSQL instance** based on actual usage
2. **Use Azure Reserved Instances** for predictable workloads
3. **Configure storage lifecycle policies** for older reports
4. **Monitor OpenAI usage** and adjust rate limits
5. **Use Application Insights sampling** to reduce ingestion costs

## Maintenance Schedule

### Weekly
- Monitor workflow execution success rates
- Check database performance metrics
- Review storage usage and costs

### Monthly
- Update OpenAI model deployments if new versions available
- Review and rotate API keys
- Analyze performance trends and optimize

### Quarterly
- Security audit of all configurations
- Review and update backup retention policies
- Performance testing and optimization review

This completes the comprehensive setup guide for the Entelech Prospect Intelligence Engine Azure integration. Follow each phase carefully and test thoroughly before moving to production.