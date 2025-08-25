# 🚀 Prospect Intelligence Engine - Complete Deployment Guide

## Phase 1: Prerequisites & Account Setup (15 minutes)

### Step 1: Check/Create Azure Account
1. Go to [portal.azure.com](https://portal.azure.com)
2. Sign in or create a Microsoft account
3. If new: Activate free tier ($200 credit for 30 days)
4. **Important**: This system uses ~$50-100/month in Azure costs

### Step 2: Install Required Tools
```bash
# Install Azure CLI
# Windows: Download from https://aka.ms/installazurecliwindows
# Or use PowerShell:
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# Install Node.js (required for n8n)
# Download from https://nodejs.org (LTS version)
```

### Step 3: Check Current Setup
Run these commands in PowerShell to check what you have:
```powershell
# Check if Azure CLI is installed
az --version

# Check if Node.js is installed  
node --version
npm --version

# Login to Azure
az login
```

---

## Phase 2: Azure Infrastructure Deployment (30 minutes)

### Step 4: Deploy Core Infrastructure
```powershell
# Navigate to your project folder
cd "C:\Users\spder\Prospect-Intelligence-Engine"

# Set your deployment variables
$resourceGroup = "prospect-intelligence-rg"
$location = "eastus"  # Change if needed
$subscriptionId = "YOUR_SUBSCRIPTION_ID"  # Get from: az account show --query id

# Create resource group
az group create --name $resourceGroup --location $location

# Deploy the main infrastructure
az deployment group create \
  --resource-group $resourceGroup \
  --template-file azure-security-infrastructure.json \
  --parameters location=$location
```

**This creates:**
- PostgreSQL database with encryption
- Key Vault for secrets
- Application Insights for monitoring  
- Storage account for reports
- Network security groups

### Step 5: Configure Database
```powershell
# Get database connection details
az postgres flexible-server list --resource-group $resourceGroup

# Connect and create database schema
# Replace with your actual server name from above command
$serverName = "prospect-intelligence-db-XXXX"
$adminUser = "entelechadmin"

# Set admin password in Key Vault (replace YOUR_PASSWORD)
az keyvault secret set --vault-name "prospect-kv-XXXX" --name "db-admin-password" --value "YOUR_STRONG_PASSWORD"

# Create database
az postgres flexible-server db create --resource-group $resourceGroup --server-name $serverName --database-name prospect_intelligence

# Import schema (you'll need to do this via Azure portal or psql client)
```

---

## Phase 3: n8n Installation & Setup (20 minutes)

### Step 6: Install n8n
```bash
# Install n8n globally
npm install -g n8n

# Create n8n data directory
mkdir ~/.n8n

# Start n8n (will run on http://localhost:5678)
n8n start
```

### Step 7: Configure n8n Environment
1. Copy `n8n-environment-variables.env` to your n8n data directory
2. Edit the file with your Azure credentials:

```bash
# Open environment file
notepad ~/.n8n/.env

# Add your Azure details (get these from Azure portal):
AZURE_OPENAI_ENDPOINT=https://YOUR-OPENAI-RESOURCE.openai.azure.com/
AZURE_OPENAI_KEY=your_openai_key_here
POSTGRES_HOST=prospect-intelligence-db-XXXX.postgres.database.azure.com
POSTGRES_PASSWORD=your_db_password_here
```

### Step 8: Import Workflows
1. Open n8n at http://localhost:5678
2. Go to "Workflows" → "Import from file"
3. Import each workflow file in this order:
   - `n8n-prospect-intelligence-website-scraper.json`
   - `n8n-prospect-intelligence-automation-opportunity.json`
   - `n8n-prospect-intelligence-report-generation.json`
   - `n8n-prospect-intelligence-crm-integration.json`
   - `n8n-instantly-email-activity-monitor.json`
   - `n8n-instantly-campaign-optimization.json`

---

## Phase 4: Database Setup (10 minutes)

### Step 9: Deploy Database Schema
You have 3 options:

**Option A: Azure Portal Query Editor**
1. Go to Azure portal → PostgreSQL server → Query editor
2. Connect with admin credentials
3. Copy/paste contents of `prospect_intelligence_schema.sql`
4. Execute

**Option B: pgAdmin (Recommended)**
1. Download pgAdmin from https://www.pgadmin.org/
2. Connect to your Azure PostgreSQL server
3. Import `prospect_intelligence_schema.sql`

**Option C: Command Line (Advanced)**
```bash
psql "host=your-server.postgres.database.azure.com port=5432 dbname=prospect_intelligence user=entelechadmin password=your_password sslmode=require" < prospect_intelligence_schema.sql
```

---

## Phase 5: External Service Setup (15 minutes)

### Step 10: Instantly Setup
1. Create account at [instantly.ai](https://instantly.ai)
2. Get your API key from Settings → API
3. Update n8n environment variables:
```
INSTANTLY_API_KEY=your_instantly_api_key
INSTANTLY_WORKSPACE_ID=your_workspace_id
```

### Step 11: Configure Email Campaigns
1. In Instantly, create 4 campaigns:
   - "Enterprise VIP Outreach" 
   - "Professional Priority Follow-up"
   - "Nurture Sequence"
   - "Educational Series"
2. Note the campaign IDs and update in n8n workflows

---

## Phase 6: Testing & Validation (20 minutes)

### Step 12: Test Database Connection
```bash
# In n8n, test the PostgreSQL node with this query:
SELECT version();
```

### Step 13: Test Website Scraper
1. In n8n, find the website scraper workflow
2. Click "Execute Workflow"  
3. Use test URL: https://example-agency.com
4. Check if data appears in PostgreSQL `companies` table

### Step 14: Test Full Pipeline
1. Trigger website scraper with a real service business URL
2. Check PostgreSQL for:
   - New company record
   - Website analysis data
   - Automation opportunities
   - Generated report record
3. Verify Instantly received the lead

---

## Phase 7: Production Configuration (10 minutes)

### Step 15: Security Hardening
```powershell
# Run security hardening script
.\security-hardening-scripts.ps1
```

### Step 16: Monitoring Setup
1. Copy `application-insights-config.js` to your n8n installation
2. Configure Application Insights key in environment variables
3. Enable monitoring dashboards in Azure portal

---

## 🎯 Quick Start Checklist

**Before you start, make sure you have:**
- [ ] Azure account with active subscription
- [ ] Credit card on file (for pay-as-you-go resources)
- [ ] Node.js installed
- [ ] Azure CLI installed
- [ ] Instantly account created
- [ ] 2 hours of setup time

**After deployment, you should have:**
- [ ] n8n running at http://localhost:5678
- [ ] 6 workflows imported and configured
- [ ] PostgreSQL database with schema deployed
- [ ] Azure infrastructure monitoring active
- [ ] Instantly integration connected
- [ ] Test prospect analyzed successfully

---

## 🆘 Common Issues & Solutions

### "Azure CLI not found"
- Download and install from https://aka.ms/installazurecliwindows
- Restart PowerShell after installation

### "PostgreSQL connection failed"
- Check firewall rules in Azure portal
- Add your IP address to allowed connections
- Verify SSL is enabled (sslmode=require)

### "n8n workflows not importing"
- Make sure n8n version is 1.0+ 
- Import workflows one at a time
- Check for JSON syntax errors

### "Instantly API errors"
- Verify API key is correct
- Check workspace ID in Instantly dashboard
- Ensure campaigns exist before assigning leads

### "OpenAI API errors"
- Verify Azure OpenAI resource is deployed
- Check API key and endpoint in environment variables
- Ensure you have GPT-4 model deployed

---

## 💰 Cost Estimates

**Monthly Azure Costs (estimated):**
- PostgreSQL Flexible Server: $25-40/month
- Azure OpenAI Service: $20-50/month (depends on usage)
- Application Insights: $5-15/month
- Storage & networking: $5-10/month
- **Total: ~$55-115/month**

**External Services:**
- Instantly: $37-97/month (depending on plan)
- **Overall Total: ~$92-212/month**

---

## 🔧 Next Steps After Deployment

1. **Test with 5-10 prospect websites** to validate accuracy
2. **Set up monitoring alerts** for workflow failures
3. **Create custom email templates** in Instantly
4. **Configure backup schedule** for PostgreSQL
5. **Set up SSL certificate** if hosting n8n publicly
6. **Review security checklist** before production use

---

## 📞 Support & Documentation

- **Azure Issues**: Azure Support Portal
- **n8n Issues**: n8n Community Forum
- **Instantly Issues**: Instantly Support Chat
- **System Architecture**: See `AZURE-SETUP-INSTRUCTIONS.md`
- **Security Compliance**: See `soc2-compliance-documentation.md`

**Ready to start? Begin with Phase 1: Prerequisites & Account Setup** 👆