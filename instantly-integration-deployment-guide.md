# Instantly Integration Deployment Guide
## Prospect Intelligence Engine - Email Automation Migration

### Overview

This guide provides comprehensive instructions for migrating the Prospect Intelligence Engine from ConvertKit to Instantly for enhanced email automation capabilities. The new integration offers advanced lead scoring, intelligent campaign assignment, AI-powered reply analysis, and comprehensive deliverability monitoring.

## Migration Benefits

### Enhanced Features
- **Intelligent Campaign Assignment**: Automated assignment based on lead score, ROI potential, and business characteristics
- **Advanced Email Tracking**: Comprehensive tracking of opens, clicks, replies, and bounces with engagement scoring
- **AI-Powered Reply Analysis**: Claude API integration for sentiment analysis and intent classification
- **Real-time Deliverability Monitoring**: Domain health tracking and automatic campaign optimization
- **Industry-Specific Sequences**: Compliance-focused sequences for regulated industries
- **A/B Testing Support**: Built-in support for email template optimization

### Business Logic Improvements
- **Service Tier Targeting**: 
  - Basic Package ($2.5K): Entry-level automation prospects
  - Professional Package ($7.5K): Medium-value prospects with multiple opportunities
  - Enterprise Package ($15K): High-ROI prospects requiring executive-level outreach
- **Lead Temperature Scoring**: Dynamic scoring based on engagement patterns
- **Automated Optimization**: AI-driven recommendations for campaign improvements

## Pre-Migration Requirements

### Infrastructure Setup
1. **Azure Database for PostgreSQL Flexible Server** (Standard_D4s_v5 or higher)
2. **n8n Self-Hosted Instance** with Instantly connector support
3. **Azure Key Vault** for secure API key management
4. **Slack Workspace** for real-time notifications
5. **Claude API Access** for AI-powered analysis

### API Keys and Credentials
```bash
# Required Environment Variables
INSTANTLY_API_KEY=your_instantly_api_key
INSTANTLY_ACCOUNT_ID=your_account_id
INSTANTLY_WEBHOOK_SECRET=your_webhook_secret
CLAUDE_API_KEY=your_claude_api_key
SLACK_WEBHOOK_URL=your_slack_webhook_url
N8N_INTERNAL_API_KEY=your_internal_api_key
```

### Instantly Account Configuration
1. **Campaign Creation**: Set up base campaigns for each service tier
2. **Sequence Templates**: Create email sequences for different prospect types
3. **Webhook Configuration**: Configure webhooks for real-time activity tracking
4. **Domain Setup**: Configure sending domains with proper SPF/DKIM records

## Database Migration Steps

### Step 1: Schema Updates

Execute the updated database schema to replace ConvertKit tables with Instantly integration:

```sql
-- 1. Drop existing ConvertKit tables (backup first!)
DROP TABLE IF EXISTS convertkit_integrations CASCADE;

-- 2. Execute the updated schema
\i prospect_intelligence_schema.sql
```

### Key Schema Changes
- `convertkit_integrations` → `instantly_integrations`
- Added `instantly_campaigns` table for campaign management
- Added `instantly_sequences` table for sequence tracking
- Added `instantly_email_activities` table for detailed activity logging
- Added `instantly_deliverability` table for domain health monitoring

### Step 2: Data Migration

If migrating from existing ConvertKit data:

```sql
-- Migrate existing prospect data to Instantly format
INSERT INTO instantly_integrations (
    tenant_id, company_id, lead_status, sync_status, 
    custom_fields, tags, created_at
)
SELECT 
    ck.tenant_id,
    ck.company_id,
    CASE ck.subscription_status
        WHEN 'active' THEN 'active'
        WHEN 'unsubscribed' THEN 'unsubscribed'
        ELSE 'cold'
    END,
    'pending_migration',
    ck.custom_fields,
    COALESCE(ck.convertkit_tag_ids, '[]'::jsonb),
    ck.created_at
FROM convertkit_integrations ck;
```

## n8n Workflow Deployment

### Step 1: Import New Workflows

Import the following workflow files into your n8n instance:

1. **Primary Integration**: `n8n-prospect-intelligence-crm-integration.json`
2. **Email Activity Monitor**: `n8n-instantly-email-activity-monitor.json`
3. **Campaign Optimization**: `n8n-instantly-campaign-optimization.json`

### Step 2: Configure Webhook Endpoints

Set up webhooks in your Instantly account:

```
Activity Webhook: https://your-n8n-instance.com/webhook/instantly-webhook
CRM Integration: https://your-n8n-instance.com/webhook/crm-integration
```

### Step 3: Workflow Configuration

Update each workflow with your specific credentials and endpoints:

```javascript
// Example credential configuration in n8n
{
  "instantly": {
    "apiKey": "{{ $env.INSTANTLY_API_KEY }}",
    "baseUrl": "https://api.instantly.ai/api/v1"
  },
  "postgres": {
    "host": "your-postgres-server.postgres.database.azure.com",
    "database": "prospect_intelligence",
    "username": "your-username",
    "password": "{{ $env.POSTGRES_PASSWORD }}"
  }
}
```

## Campaign Configuration

### Service Tier Campaign Mapping

Configure the following campaigns in your Instantly account:

#### 1. Enterprise VIP Campaign (`entelech_enterprise_vip`)
- **Target**: Lead score 80+, ROI potential $50K+
- **Sequence**: Executive decision-maker outreach
- **Delay**: 30 minutes (immediate attention)
- **Follow-ups**: 7 emails maximum
- **Personalization**: Company-specific ROI calculations, executive-level messaging

#### 2. Professional Priority Campaign (`entelech_professional_priority`)
- **Target**: Lead score 60-79, ROI potential $25K-$50K
- **Sequence**: Professional service automation focused
- **Delay**: 1 hour
- **Follow-ups**: 6 emails maximum
- **Personalization**: Industry-specific automation opportunities

#### 3. Warm Prospects Campaign (`entelech_warm_prospects`)
- **Target**: Lead score 40-59, identified automation opportunities
- **Sequence**: Educational nurture sequence
- **Delay**: 4 hours
- **Follow-ups**: 5 emails maximum
- **Personalization**: Process-specific automation benefits

#### 4. Cold Outreach Campaign (`entelech_cold_outreach`)
- **Target**: Lead score <40, minimal automation opportunities
- **Sequence**: Educational content series
- **Delay**: 24 hours
- **Follow-ups**: 4 emails maximum
- **Personalization**: Industry trends and automation awareness

### Email Sequence Templates

#### High-Value Prospect Sequence Example
```html
Subject: Quick question about {{company_name}}'s {{top_opportunity}}

Hi {{first_name}},

I noticed {{company_name}} is in the {{industry}} space and likely handling {{top_opportunity}} manually.

Our analysis suggests this could be costing you approximately {{top_opportunity_savings}} annually in time and inefficiencies.

Would you be open to a 15-minute conversation about how we've helped similar {{industry}} companies automate this process and achieve {{total_roi}} in measurable ROI?

Best regards,
[Your Name]

P.S. Happy to share a brief case study of a {{company_size}} {{industry}} company that achieved {{package_price}} worth of automation value.
```

## AI Integration Setup

### Claude API Configuration

The integration uses Claude for advanced reply analysis and optimization recommendations:

```javascript
// Claude API request example
{
  "model": "claude-3-sonnet-20240229",
  "max_tokens": 1000,
  "messages": [
    {
      "role": "user",
      "content": "Analyze this email reply and provide sentiment, intent, and recommended actions..."
    }
  ]
}
```

### AI Analysis Features
- **Sentiment Analysis**: Positive, neutral, negative, interested, not_interested
- **Intent Classification**: Meeting request, pricing inquiry, general inquiry, unsubscribe
- **Lead Qualification**: Automatic updates to prospect status
- **Talking Points Generation**: AI-generated conversation starters for sales team

## Monitoring and Analytics

### Real-Time Dashboards

The integration provides comprehensive monitoring through:

1. **Campaign Performance Views**:
   - `v_instantly_campaign_performance`: Real-time campaign metrics
   - `v_instantly_lead_engagement`: Individual lead engagement analysis
   - `v_instantly_deliverability_trends`: Domain health and deliverability tracking

2. **Slack Notifications**:
   - High-priority lead alerts (score 80+)
   - Campaign deliverability warnings
   - Reply notifications requiring immediate attention
   - Performance optimization recommendations

3. **Automated Optimization**:
   - AI-powered campaign improvement suggestions
   - Automatic pausing of problematic campaigns
   - A/B testing recommendations
   - Scaling opportunities for high-performing campaigns

### Key Performance Indicators (KPIs)

Monitor these critical metrics:

```sql
-- Campaign Performance Summary
SELECT 
    campaign_name,
    target_service_tier,
    overall_reply_rate,
    performance_score,
    delivery_health,
    integrated_leads,
    hot_leads
FROM v_instantly_campaign_performance
ORDER BY performance_score DESC;

-- High-Value Lead Pipeline
SELECT 
    company_name,
    lead_temperature,
    engagement_score,
    service_package_tier,
    roi_potential,
    personal_reply_rate
FROM v_instantly_lead_engagement
WHERE lead_temperature IN ('hot', 'warm')
ORDER BY engagement_score DESC;
```

## Deployment Checklist

### Pre-Deployment
- [ ] Azure PostgreSQL server provisioned and configured
- [ ] n8n instance deployed with required connectors
- [ ] Instantly account configured with campaigns and sequences
- [ ] API keys stored in Azure Key Vault
- [ ] Domain DNS records configured (SPF, DKIM, DMARC)
- [ ] Slack workspace configured for notifications
- [ ] Claude API access verified

### Database Deployment
- [ ] Backup existing ConvertKit data
- [ ] Execute new schema migration
- [ ] Verify all tables and indexes created successfully
- [ ] Test database functions and triggers
- [ ] Run sample queries to validate views

### Workflow Deployment
- [ ] Import all three n8n workflows
- [ ] Configure credentials and environment variables
- [ ] Test webhook endpoints
- [ ] Validate API connections (Instantly, Claude, Slack)
- [ ] Run test executions with sample data

### Campaign Configuration
- [ ] Create base campaigns in Instantly
- [ ] Set up email sequences for each service tier
- [ ] Configure webhook notifications
- [ ] Test lead creation and sequence assignment
- [ ] Verify AI analysis integration

### Post-Deployment Validation
- [ ] Monitor first 24 hours of activity
- [ ] Verify lead scoring calculations
- [ ] Test reply analysis and notification system
- [ ] Validate campaign assignment logic
- [ ] Review deliverability metrics
- [ ] Confirm Slack notifications working

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. API Authentication Failures
```bash
# Verify API keys
curl -H "Authorization: Bearer $INSTANTLY_API_KEY" \
     https://api.instantly.ai/api/v1/campaigns

# Check n8n credential configuration
docker exec n8n-container n8n credentials:list
```

#### 2. Database Connection Issues
```sql
-- Test database connectivity
SELECT current_database(), current_user, now();

-- Verify table creation
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'instantly_%';
```

#### 3. Webhook Delivery Problems
- Verify webhook URLs are accessible from Instantly's servers
- Check n8n workflow is active and properly configured
- Review webhook secret configuration
- Monitor n8n execution logs for errors

#### 4. Campaign Assignment Issues
```sql
-- Test campaign assignment function
SELECT get_optimal_campaign_assignment(75, 35000, 'Technology Services', 'medium', 3);

-- Check lead scoring calculation
SELECT calculate_lead_score('company-uuid-here');
```

#### 5. AI Analysis Failures
- Verify Claude API key and quota
- Check request format and model availability
- Review rate limiting configuration
- Monitor API usage in logs

### Performance Optimization

#### Database Performance
```sql
-- Monitor query performance
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
WHERE query LIKE '%instantly%'
ORDER BY total_time DESC;

-- Rebuild statistics
ANALYZE instantly_integrations;
ANALYZE instantly_email_activities;
ANALYZE instantly_campaigns;
```

#### n8n Workflow Performance
- Monitor execution times in n8n interface
- Optimize database queries with proper indexing
- Implement caching for frequently accessed data
- Use bulk operations where possible

## Support and Maintenance

### Regular Maintenance Tasks

#### Daily
- Monitor campaign performance metrics
- Review high-priority lead notifications
- Check deliverability health status
- Validate webhook activity

#### Weekly  
- Analyze campaign optimization recommendations
- Review AI analysis accuracy
- Update campaign sequences based on performance
- Check database performance metrics

#### Monthly
- Comprehensive campaign performance review
- Update lead scoring criteria based on conversion data
- Review and optimize email sequences
- Analyze ROI and adjust targeting criteria

### Backup and Recovery

#### Database Backups
```bash
# Daily automated backup
pg_dump -h your-postgres-server.postgres.database.azure.com \
        -U your-username \
        -d prospect_intelligence \
        --clean --create --compress=9 \
        > prospect_intelligence_$(date +%Y%m%d).sql.gz
```

#### n8n Workflow Backups
- Export workflows regularly through n8n interface
- Version control workflow files in git repository
- Document any custom changes or configurations

### Support Contacts

For technical support and implementation assistance:
- **Database Issues**: Azure PostgreSQL support
- **n8n Workflow Issues**: n8n community forums
- **Instantly API Issues**: Instantly support documentation
- **Claude API Issues**: Anthropic developer support

## Success Metrics

### Migration Success Criteria

The migration is considered successful when:
- [ ] All prospects successfully migrated to Instantly
- [ ] Campaign assignment logic working correctly
- [ ] Email activity tracking operational
- [ ] AI reply analysis functioning
- [ ] Deliverability monitoring active
- [ ] Notification systems operational
- [ ] Performance metrics showing improvement over ConvertKit

### Expected Performance Improvements

Target improvements over ConvertKit integration:
- **Response Rate**: 25-40% increase due to intelligent campaign assignment
- **Lead Qualification**: 60% improvement in lead scoring accuracy
- **Campaign Optimization**: Real-time optimization vs manual adjustments
- **Deliverability**: Proactive monitoring and automatic issue resolution
- **Sales Team Efficiency**: 50% reduction in manual lead review time

This completes the comprehensive deployment guide for migrating from ConvertKit to Instantly email automation integration.