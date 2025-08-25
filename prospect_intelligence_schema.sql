-- ============================================================================
-- Prospect Intelligence Engine - PostgreSQL Database Schema
-- Optimized for Azure Database for PostgreSQL Flexible Server
-- Multi-tenant architecture with row-level security support
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- ============================================================================
-- Core Configuration Tables
-- ============================================================================

-- Tenants table for multi-tenant architecture
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) UNIQUE NOT NULL,
    subscription_tier VARCHAR(50) NOT NULL CHECK (subscription_tier IN ('basic', 'professional', 'enterprise')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled')),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Users table for authentication and authorization
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'analyst', 'user')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- Prospect Analysis Core Tables
-- ============================================================================

-- Companies table for prospect information
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(500) NOT NULL,
    website VARCHAR(500),
    domain VARCHAR(255),
    industry VARCHAR(200),
    sub_industry VARCHAR(200),
    country VARCHAR(100),
    state_province VARCHAR(100),
    city VARCHAR(100),
    company_size_category VARCHAR(50) CHECK (company_size_category IN ('startup', 'small', 'medium', 'large', 'enterprise')),
    employee_count_min INTEGER,
    employee_count_max INTEGER,
    annual_revenue_min DECIMAL(15,2),
    annual_revenue_max DECIMAL(15,2),
    founded_year INTEGER,
    business_model VARCHAR(100),
    tech_stack JSONB DEFAULT '[]',
    contact_info JSONB DEFAULT '{}',
    social_profiles JSONB DEFAULT '{}',
    description TEXT,
    notes TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'identified' CHECK (status IN ('identified', 'analyzing', 'analyzed', 'contacted', 'qualified', 'disqualified', 'converted')),
    source VARCHAR(100),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Website analysis results
CREATE TABLE website_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    analysis_version INTEGER NOT NULL DEFAULT 1,
    url_analyzed VARCHAR(500) NOT NULL,
    scraping_status VARCHAR(50) NOT NULL CHECK (scraping_status IN ('pending', 'in_progress', 'completed', 'failed', 'timeout')),
    
    -- Service offerings analysis
    services_identified JSONB DEFAULT '[]',
    service_categories JSONB DEFAULT '[]',
    pricing_model VARCHAR(100),
    pricing_info JSONB DEFAULT '{}',
    
    -- Team structure analysis
    team_size_indicators JSONB DEFAULT '{}',
    team_structure JSONB DEFAULT '{}',
    key_personnel JSONB DEFAULT '[]',
    
    -- Technology and automation level
    current_automation_level VARCHAR(50) CHECK (current_automation_level IN ('minimal', 'basic', 'moderate', 'advanced', 'highly_automated')),
    tech_infrastructure JSONB DEFAULT '{}',
    tools_detected JSONB DEFAULT '[]',
    
    -- Content analysis
    content_quality_score INTEGER CHECK (content_quality_score BETWEEN 1 AND 100),
    seo_indicators JSONB DEFAULT '{}',
    marketing_maturity VARCHAR(50),
    
    -- Technical metrics
    page_load_time_ms INTEGER,
    mobile_friendly BOOLEAN,
    ssl_enabled BOOLEAN,
    
    error_logs JSONB DEFAULT '[]',
    raw_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lead capture and customer journey analysis
CREATE TABLE customer_journey_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    analysis_version INTEGER NOT NULL DEFAULT 1,
    
    -- Lead capture analysis
    lead_capture_forms INTEGER DEFAULT 0,
    lead_magnets JSONB DEFAULT '[]',
    contact_options JSONB DEFAULT '{}',
    response_time_analysis JSONB DEFAULT '{}',
    
    -- Customer journey mapping
    journey_stages JSONB DEFAULT '[]',
    touchpoints JSONB DEFAULT '[]',
    conversion_funnels JSONB DEFAULT '[]',
    drop_off_points JSONB DEFAULT '[]',
    
    -- Communication analysis
    communication_channels JSONB DEFAULT '[]',
    follow_up_processes JSONB DEFAULT '{}',
    personalization_level VARCHAR(50),
    automation_gaps JSONB DEFAULT '[]',
    
    -- Pain points identified
    manual_processes JSONB DEFAULT '[]',
    inefficiencies JSONB DEFAULT '[]',
    bottlenecks JSONB DEFAULT '[]',
    
    journey_quality_score INTEGER CHECK (journey_quality_score BETWEEN 1 AND 100),
    automation_readiness_score INTEGER CHECK (automation_readiness_score BETWEEN 1 AND 100),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- Automation Opportunity Analysis
-- ============================================================================

-- Manual process indicators and automation opportunities
CREATE TABLE automation_opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    analysis_version INTEGER NOT NULL DEFAULT 1,
    
    -- Process identification
    process_name VARCHAR(255) NOT NULL,
    process_category VARCHAR(100) NOT NULL,
    current_method VARCHAR(100),
    frequency VARCHAR(50),
    
    -- Impact analysis
    time_spent_hours_per_week DECIMAL(8,2),
    hourly_cost DECIMAL(10,2),
    annual_cost_current DECIMAL(12,2),
    error_rate_percentage DECIMAL(5,2),
    
    -- Automation recommendations
    automation_type VARCHAR(100),
    automation_complexity VARCHAR(50) CHECK (automation_complexity IN ('low', 'medium', 'high')),
    recommended_tools JSONB DEFAULT '[]',
    implementation_timeline_weeks INTEGER,
    
    -- Cost/benefit analysis
    implementation_cost DECIMAL(12,2),
    annual_savings DECIMAL(12,2),
    roi_percentage DECIMAL(8,2),
    payback_period_months DECIMAL(6,2),
    
    -- Service package mapping
    service_tier VARCHAR(20) CHECK (service_tier IN ('basic_2_5k', 'professional_7_5k', 'enterprise_15k')),
    package_fit_score INTEGER CHECK (package_fit_score BETWEEN 1 AND 100),
    
    priority_score INTEGER CHECK (priority_score BETWEEN 1 AND 100),
    confidence_level VARCHAR(20) CHECK (confidence_level IN ('low', 'medium', 'high')),
    status VARCHAR(50) DEFAULT 'identified' CHECK (status IN ('identified', 'validated', 'recommended', 'proposed', 'accepted', 'rejected')),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Service package definitions and pricing
CREATE TABLE service_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    package_tier VARCHAR(20) NOT NULL CHECK (package_tier IN ('basic_2_5k', 'professional_7_5k', 'enterprise_15k')),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price_usd DECIMAL(10,2) NOT NULL,
    duration_weeks INTEGER,
    
    -- Package features
    features JSONB DEFAULT '[]',
    deliverables JSONB DEFAULT '[]',
    requirements JSONB DEFAULT '[]',
    limitations JSONB DEFAULT '[]',
    
    -- Targeting criteria
    target_company_size JSONB DEFAULT '[]',
    target_industries JSONB DEFAULT '[]',
    complexity_level VARCHAR(20),
    
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ROI calculations and projections
CREATE TABLE roi_projections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    opportunity_id UUID REFERENCES automation_opportunities(id) ON DELETE CASCADE,
    
    -- Financial projections
    year_1_savings DECIMAL(12,2),
    year_2_savings DECIMAL(12,2),
    year_3_savings DECIMAL(12,2),
    total_3year_savings DECIMAL(12,2),
    
    -- Investment breakdown
    initial_investment DECIMAL(12,2),
    ongoing_costs_annual DECIMAL(12,2),
    training_costs DECIMAL(12,2),
    
    -- Risk factors
    implementation_risk VARCHAR(20) CHECK (implementation_risk IN ('low', 'medium', 'high')),
    adoption_risk VARCHAR(20) CHECK (adoption_risk IN ('low', 'medium', 'high')),
    risk_adjustments JSONB DEFAULT '{}',
    
    -- Metrics
    net_present_value DECIMAL(12,2),
    internal_rate_of_return DECIMAL(8,2),
    break_even_months DECIMAL(6,2),
    
    assumptions JSONB DEFAULT '{}',
    scenario VARCHAR(50) DEFAULT 'base' CHECK (scenario IN ('conservative', 'base', 'optimistic')),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- Report Management
-- ============================================================================

-- Generated reports metadata
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    report_type VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    
    -- Generation details
    template_version VARCHAR(50),
    branding_config JSONB DEFAULT '{}',
    custom_sections JSONB DEFAULT '[]',
    
    -- File information
    file_name VARCHAR(500),
    file_path VARCHAR(1000),
    file_size_bytes BIGINT,
    file_format VARCHAR(20) DEFAULT 'pdf',
    
    -- Status tracking
    generation_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (generation_status IN ('pending', 'generating', 'completed', 'failed', 'expired')),
    generation_started_at TIMESTAMPTZ,
    generation_completed_at TIMESTAMPTZ,
    generation_duration_ms INTEGER,
    
    -- Access and delivery
    access_token VARCHAR(255),
    expires_at TIMESTAMPTZ,
    download_count INTEGER DEFAULT 0,
    last_downloaded_at TIMESTAMPTZ,
    
    -- Error tracking
    error_message TEXT,
    error_details JSONB,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Report delivery tracking
CREATE TABLE report_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    
    delivery_method VARCHAR(50) NOT NULL CHECK (delivery_method IN ('email', 'download', 'api', 'webhook')),
    recipient_email VARCHAR(255),
    delivery_status VARCHAR(50) NOT NULL CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    error_message TEXT,
    
    tracking_id VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- CRM Integration
-- ============================================================================

-- Instantly integration data
CREATE TABLE instantly_integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    instantly_lead_id VARCHAR(255),
    instantly_campaign_id VARCHAR(255),
    instantly_sequence_id VARCHAR(255),
    instantly_account_id VARCHAR(255),
    
    -- Lead status and tracking
    lead_status VARCHAR(50) DEFAULT 'active' CHECK (lead_status IN ('active', 'paused', 'completed', 'unsubscribed', 'bounced', 'complained', 'replied')),
    campaign_status VARCHAR(50) DEFAULT 'pending' CHECK (campaign_status IN ('pending', 'active', 'paused', 'completed', 'failed')),
    sequence_step INTEGER DEFAULT 0,
    
    -- Email tracking and deliverability
    emails_sent INTEGER DEFAULT 0,
    emails_opened INTEGER DEFAULT 0,
    emails_clicked INTEGER DEFAULT 0,
    emails_replied INTEGER DEFAULT 0,
    emails_bounced INTEGER DEFAULT 0,
    
    open_rate DECIMAL(5,2) DEFAULT 0.00,
    click_rate DECIMAL(5,2) DEFAULT 0.00,
    reply_rate DECIMAL(5,2) DEFAULT 0.00,
    bounce_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Instantly-specific tracking
    first_email_sent_at TIMESTAMPTZ,
    last_email_sent_at TIMESTAMPTZ,
    first_open_at TIMESTAMPTZ,
    first_click_at TIMESTAMPTZ,
    first_reply_at TIMESTAMPTZ,
    last_activity_at TIMESTAMPTZ,
    
    -- Lead qualification and scoring
    lead_temperature VARCHAR(20) DEFAULT 'cold' CHECK (lead_temperature IN ('cold', 'warm', 'hot', 'interested', 'qualified')),
    engagement_score INTEGER DEFAULT 0 CHECK (engagement_score BETWEEN 0 AND 100),
    qualification_notes TEXT,
    
    -- Campaign assignment logic
    assignment_reason VARCHAR(100),
    roi_potential DECIMAL(12,2),
    service_package_tier VARCHAR(20) CHECK (service_package_tier IN ('basic_2_5k', 'professional_7_5k', 'enterprise_15k')),
    
    -- Synchronization tracking
    last_sync_at TIMESTAMPTZ,
    sync_status VARCHAR(50) DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'error', 'rate_limited')),
    sync_error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Custom fields and tags
    custom_fields JSONB DEFAULT '{}',
    tags JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prospect tracking and status updates
CREATE TABLE prospect_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    current_stage VARCHAR(100) NOT NULL,
    previous_stage VARCHAR(100),
    stage_changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Lead scoring
    lead_score INTEGER CHECK (lead_score BETWEEN 0 AND 100),
    qualification_status VARCHAR(50) CHECK (qualification_status IN ('unqualified', 'marketing_qualified', 'sales_qualified', 'opportunity', 'customer')),
    
    -- Engagement tracking
    last_contact_date TIMESTAMPTZ,
    last_contact_method VARCHAR(50),
    next_follow_up_date TIMESTAMPTZ,
    follow_up_priority VARCHAR(20) CHECK (follow_up_priority IN ('low', 'medium', 'high', 'urgent')),
    
    -- Assignment
    assigned_to UUID REFERENCES users(id),
    assigned_at TIMESTAMPTZ,
    
    notes TEXT,
    tags JSONB DEFAULT '[]',
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Instantly campaigns and sequences
CREATE TABLE instantly_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    instantly_campaign_id VARCHAR(255) UNIQUE NOT NULL,
    campaign_name VARCHAR(500) NOT NULL,
    campaign_type VARCHAR(50) DEFAULT 'outreach' CHECK (campaign_type IN ('outreach', 'follow_up', 'nurture', 'reactivation')),
    
    -- Campaign targeting
    target_service_tier VARCHAR(20) CHECK (target_service_tier IN ('basic_2_5k', 'professional_7_5k', 'enterprise_15k')),
    target_lead_score_min INTEGER CHECK (target_lead_score_min BETWEEN 0 AND 100),
    target_lead_score_max INTEGER CHECK (target_lead_score_max BETWEEN 0 AND 100),
    target_business_types JSONB DEFAULT '[]',
    target_industries JSONB DEFAULT '[]',
    
    -- Campaign configuration
    sequence_steps INTEGER DEFAULT 0,
    delay_between_steps_hours INTEGER DEFAULT 24,
    max_follow_ups INTEGER DEFAULT 5,
    
    -- Performance tracking
    total_leads_added INTEGER DEFAULT 0,
    total_emails_sent INTEGER DEFAULT 0,
    total_replies INTEGER DEFAULT 0,
    total_opens INTEGER DEFAULT 0,
    total_clicks INTEGER DEFAULT 0,
    total_bounces INTEGER DEFAULT 0,
    total_unsubscribes INTEGER DEFAULT 0,
    
    -- Campaign metrics
    overall_open_rate DECIMAL(5,2) DEFAULT 0.00,
    overall_click_rate DECIMAL(5,2) DEFAULT 0.00,
    overall_reply_rate DECIMAL(5,2) DEFAULT 0.00,
    overall_bounce_rate DECIMAL(5,2) DEFAULT 0.00,
    conversion_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Status and lifecycle
    campaign_status VARCHAR(50) DEFAULT 'draft' CHECK (campaign_status IN ('draft', 'active', 'paused', 'completed', 'archived')),
    started_at TIMESTAMPTZ,
    paused_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    -- A/B testing support
    is_ab_test BOOLEAN DEFAULT FALSE,
    ab_test_variant VARCHAR(50),
    ab_test_control_campaign_id VARCHAR(255),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Instantly email sequences and templates
CREATE TABLE instantly_sequences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES instantly_campaigns(id) ON DELETE CASCADE,
    
    instantly_sequence_id VARCHAR(255) UNIQUE NOT NULL,
    sequence_name VARCHAR(500) NOT NULL,
    sequence_type VARCHAR(50) DEFAULT 'linear' CHECK (sequence_type IN ('linear', 'conditional', 'branched')),
    
    -- Sequence configuration
    total_steps INTEGER NOT NULL,
    step_delays JSONB DEFAULT '[]', -- Array of delay hours between steps
    
    -- Email templates (stored as array of template objects)
    email_templates JSONB DEFAULT '[]',
    
    -- Personalization and AI integration
    uses_ai_personalization BOOLEAN DEFAULT FALSE,
    ai_model VARCHAR(50),
    personalization_fields JSONB DEFAULT '[]',
    dynamic_content_rules JSONB DEFAULT '{}',
    
    -- Performance by sequence
    leads_enrolled INTEGER DEFAULT 0,
    avg_completion_rate DECIMAL(5,2) DEFAULT 0.00,
    avg_response_rate DECIMAL(5,2) DEFAULT 0.00,
    best_performing_step INTEGER,
    
    -- Status
    sequence_status VARCHAR(50) DEFAULT 'draft' CHECK (sequence_status IN ('draft', 'active', 'paused', 'archived')),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Instantly email activity log
CREATE TABLE instantly_email_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    integration_id UUID NOT NULL REFERENCES instantly_integrations(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    instantly_activity_id VARCHAR(255),
    email_id VARCHAR(255),
    
    -- Activity details
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN ('sent', 'delivered', 'opened', 'clicked', 'replied', 'bounced', 'unsubscribed', 'complained')),
    activity_timestamp TIMESTAMPTZ NOT NULL,
    
    -- Email details
    subject_line TEXT,
    email_step INTEGER,
    sequence_position INTEGER,
    
    -- Tracking data
    ip_address INET,
    user_agent TEXT,
    location_data JSONB DEFAULT '{}',
    device_type VARCHAR(50),
    
    -- Reply analysis (for replied activities)
    reply_content TEXT,
    reply_sentiment VARCHAR(20) CHECK (reply_sentiment IN ('positive', 'neutral', 'negative', 'interested', 'not_interested')),
    reply_intent VARCHAR(50),
    needs_human_review BOOLEAN DEFAULT FALSE,
    
    -- Claude AI analysis results
    ai_analysis JSONB DEFAULT '{}',
    lead_qualification_update BOOLEAN DEFAULT FALSE,
    suggested_follow_up VARCHAR(500),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Instantly deliverability tracking
CREATE TABLE instantly_deliverability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    -- Time period tracking
    tracking_date DATE NOT NULL,
    tracking_period VARCHAR(20) DEFAULT 'daily' CHECK (tracking_period IN ('hourly', 'daily', 'weekly', 'monthly')),
    
    -- Domain and account tracking
    sending_domain VARCHAR(255),
    instantly_account_id VARCHAR(255),
    
    -- Deliverability metrics
    emails_sent INTEGER DEFAULT 0,
    emails_delivered INTEGER DEFAULT 0,
    emails_bounced INTEGER DEFAULT 0,
    hard_bounces INTEGER DEFAULT 0,
    soft_bounces INTEGER DEFAULT 0,
    spam_complaints INTEGER DEFAULT 0,
    unsubscribes INTEGER DEFAULT 0,
    
    -- Deliverability rates
    delivery_rate DECIMAL(5,2) DEFAULT 0.00,
    bounce_rate DECIMAL(5,2) DEFAULT 0.00,
    spam_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Domain health indicators
    domain_reputation_score INTEGER CHECK (domain_reputation_score BETWEEN 0 AND 100),
    spam_score DECIMAL(4,2),
    blacklist_status JSONB DEFAULT '{}',
    
    -- Recommendations and alerts
    health_status VARCHAR(20) DEFAULT 'good' CHECK (health_status IN ('excellent', 'good', 'warning', 'critical')),
    recommendations JSONB DEFAULT '[]',
    alerts_triggered JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Analysis history and follow-ups
CREATE TABLE analysis_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    analysis_type VARCHAR(100) NOT NULL,
    analysis_trigger VARCHAR(100),
    
    -- Results comparison
    previous_results JSONB,
    current_results JSONB,
    changes_detected JSONB DEFAULT '[]',
    
    -- Quality metrics
    data_quality_score INTEGER CHECK (data_quality_score BETWEEN 1 AND 100),
    confidence_score INTEGER CHECK (confidence_score BETWEEN 1 AND 100),
    completeness_percentage DECIMAL(5,2),
    
    -- Processing details
    processing_time_ms INTEGER,
    tokens_consumed INTEGER,
    api_calls_made INTEGER,
    
    performed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- System Integration Tables
-- ============================================================================

-- n8n workflow execution logs
CREATE TABLE workflow_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    workflow_id VARCHAR(255) NOT NULL,
    workflow_name VARCHAR(500),
    execution_id VARCHAR(255) NOT NULL,
    
    status VARCHAR(50) NOT NULL CHECK (status IN ('running', 'success', 'error', 'canceled', 'waiting', 'unknown')),
    
    -- Timing
    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,
    duration_ms INTEGER,
    
    -- Context
    trigger_type VARCHAR(100),
    trigger_data JSONB,
    input_data JSONB,
    output_data JSONB,
    
    -- Error handling
    error_message TEXT,
    error_stack TEXT,
    failed_node VARCHAR(255),
    
    -- Resource usage
    nodes_executed INTEGER,
    webhook_calls INTEGER,
    api_calls INTEGER,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Azure OpenAI API usage tracking
CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    service_provider VARCHAR(50) NOT NULL,
    api_endpoint VARCHAR(255) NOT NULL,
    model_name VARCHAR(100),
    
    -- Request details
    request_id VARCHAR(255),
    operation_type VARCHAR(100),
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    total_tokens INTEGER,
    
    -- Response details
    response_status INTEGER,
    response_time_ms INTEGER,
    
    -- Cost tracking
    cost_usd DECIMAL(10,6),
    billing_tier VARCHAR(50),
    
    -- Context
    company_id UUID REFERENCES companies(id),
    workflow_execution_id UUID REFERENCES workflow_executions(id),
    user_id UUID REFERENCES users(id),
    
    -- Error tracking
    error_code VARCHAR(100),
    error_message TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Security audit trails
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    
    -- Actor information
    user_id UUID REFERENCES users(id),
    user_email VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    
    -- Action details
    action_details JSONB DEFAULT '{}',
    old_values JSONB,
    new_values JSONB,
    
    -- Context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Security flags
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    requires_review BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance monitoring data
CREATE TABLE performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    metric_type VARCHAR(100) NOT NULL,
    metric_name VARCHAR(200) NOT NULL,
    metric_value DECIMAL(20,6) NOT NULL,
    metric_unit VARCHAR(50),
    
    -- Dimensions
    dimensions JSONB DEFAULT '{}',
    tags JSONB DEFAULT '[]',
    
    -- Timing
    measurement_time TIMESTAMPTZ NOT NULL,
    
    -- Context
    source VARCHAR(100),
    environment VARCHAR(50) DEFAULT 'production',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- Indexes for Performance Optimization
-- ============================================================================

-- Tenants indexes
CREATE INDEX idx_tenants_domain ON tenants(domain);
CREATE INDEX idx_tenants_status ON tenants(status);

-- Users indexes
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- Companies indexes (optimized for read-heavy workloads)
CREATE INDEX idx_companies_tenant_id ON companies(tenant_id);
CREATE INDEX idx_companies_name ON companies USING gin(name gin_trgm_ops);
CREATE INDEX idx_companies_domain ON companies(domain);
CREATE INDEX idx_companies_industry ON companies(industry);
CREATE INDEX idx_companies_status ON companies(status);
CREATE INDEX idx_companies_created_at ON companies(created_at DESC);
CREATE INDEX idx_companies_size_revenue ON companies(company_size_category, annual_revenue_min, annual_revenue_max);

-- Website analyses indexes
CREATE INDEX idx_website_analyses_tenant_id ON website_analyses(tenant_id);
CREATE INDEX idx_website_analyses_company_id ON website_analyses(company_id);
CREATE INDEX idx_website_analyses_version ON website_analyses(company_id, analysis_version DESC);
CREATE INDEX idx_website_analyses_status ON website_analyses(scraping_status);
CREATE INDEX idx_website_analyses_automation_level ON website_analyses(current_automation_level);

-- Customer journey analyses indexes
CREATE INDEX idx_customer_journey_tenant_id ON customer_journey_analyses(tenant_id);
CREATE INDEX idx_customer_journey_company_id ON customer_journey_analyses(company_id);
CREATE INDEX idx_customer_journey_version ON customer_journey_analyses(company_id, analysis_version DESC);
CREATE INDEX idx_customer_journey_scores ON customer_journey_analyses(journey_quality_score, automation_readiness_score);

-- Automation opportunities indexes
CREATE INDEX idx_automation_opps_tenant_id ON automation_opportunities(tenant_id);
CREATE INDEX idx_automation_opps_company_id ON automation_opportunities(company_id);
CREATE INDEX idx_automation_opps_tier ON automation_opportunities(service_tier);
CREATE INDEX idx_automation_opps_roi ON automation_opportunities(roi_percentage DESC);
CREATE INDEX idx_automation_opps_priority ON automation_opportunities(priority_score DESC);
CREATE INDEX idx_automation_opps_category ON automation_opportunities(process_category);

-- Service packages indexes
CREATE INDEX idx_service_packages_tenant_id ON service_packages(tenant_id);
CREATE INDEX idx_service_packages_tier ON service_packages(package_tier);
CREATE INDEX idx_service_packages_active ON service_packages(is_active);

-- ROI projections indexes
CREATE INDEX idx_roi_projections_tenant_id ON roi_projections(tenant_id);
CREATE INDEX idx_roi_projections_company_id ON roi_projections(company_id);
CREATE INDEX idx_roi_projections_opportunity_id ON roi_projections(opportunity_id);
CREATE INDEX idx_roi_projections_npv ON roi_projections(net_present_value DESC);

-- Reports indexes
CREATE INDEX idx_reports_tenant_id ON reports(tenant_id);
CREATE INDEX idx_reports_company_id ON reports(company_id);
CREATE INDEX idx_reports_type ON reports(report_type);
CREATE INDEX idx_reports_status ON reports(generation_status);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);

-- Report deliveries indexes
CREATE INDEX idx_report_deliveries_tenant_id ON report_deliveries(tenant_id);
CREATE INDEX idx_report_deliveries_report_id ON report_deliveries(report_id);
CREATE INDEX idx_report_deliveries_status ON report_deliveries(delivery_status);

-- Instantly integrations indexes
CREATE INDEX idx_instantly_tenant_id ON instantly_integrations(tenant_id);
CREATE INDEX idx_instantly_company_id ON instantly_integrations(company_id);
CREATE INDEX idx_instantly_lead_id ON instantly_integrations(instantly_lead_id);
CREATE INDEX idx_instantly_campaign_id ON instantly_integrations(instantly_campaign_id);
CREATE INDEX idx_instantly_lead_status ON instantly_integrations(lead_status);
CREATE INDEX idx_instantly_sync_status ON instantly_integrations(sync_status);
CREATE INDEX idx_instantly_temperature ON instantly_integrations(lead_temperature);
CREATE INDEX idx_instantly_engagement_score ON instantly_integrations(engagement_score DESC);
CREATE INDEX idx_instantly_last_activity ON instantly_integrations(last_activity_at DESC);

-- Instantly campaigns indexes
CREATE INDEX idx_campaigns_tenant_id ON instantly_campaigns(tenant_id);
CREATE INDEX idx_campaigns_instantly_id ON instantly_campaigns(instantly_campaign_id);
CREATE INDEX idx_campaigns_status ON instantly_campaigns(campaign_status);
CREATE INDEX idx_campaigns_type ON instantly_campaigns(campaign_type);
CREATE INDEX idx_campaigns_tier ON instantly_campaigns(target_service_tier);
CREATE INDEX idx_campaigns_reply_rate ON instantly_campaigns(overall_reply_rate DESC);

-- Instantly sequences indexes
CREATE INDEX idx_sequences_tenant_id ON instantly_sequences(tenant_id);
CREATE INDEX idx_sequences_campaign_id ON instantly_sequences(campaign_id);
CREATE INDEX idx_sequences_instantly_id ON instantly_sequences(instantly_sequence_id);
CREATE INDEX idx_sequences_status ON instantly_sequences(sequence_status);
CREATE INDEX idx_sequences_performance ON instantly_sequences(avg_response_rate DESC);

-- Instantly email activities indexes
CREATE INDEX idx_activities_tenant_id ON instantly_email_activities(tenant_id);
CREATE INDEX idx_activities_integration_id ON instantly_email_activities(integration_id);
CREATE INDEX idx_activities_company_id ON instantly_email_activities(company_id);
CREATE INDEX idx_activities_type ON instantly_email_activities(activity_type);
CREATE INDEX idx_activities_timestamp ON instantly_email_activities(activity_timestamp DESC);
CREATE INDEX idx_activities_sentiment ON instantly_email_activities(reply_sentiment);
CREATE INDEX idx_activities_needs_review ON instantly_email_activities(needs_human_review) WHERE needs_human_review = true;

-- Instantly deliverability indexes
CREATE INDEX idx_deliverability_tenant_id ON instantly_deliverability(tenant_id);
CREATE INDEX idx_deliverability_date ON instantly_deliverability(tracking_date DESC);
CREATE INDEX idx_deliverability_domain ON instantly_deliverability(sending_domain);
CREATE INDEX idx_deliverability_health ON instantly_deliverability(health_status);
CREATE INDEX idx_deliverability_reputation ON instantly_deliverability(domain_reputation_score DESC);

-- Prospect tracking indexes
CREATE INDEX idx_prospect_tracking_tenant_id ON prospect_tracking(tenant_id);
CREATE INDEX idx_prospect_tracking_company_id ON prospect_tracking(company_id);
CREATE INDEX idx_prospect_tracking_stage ON prospect_tracking(current_stage);
CREATE INDEX idx_prospect_tracking_score ON prospect_tracking(lead_score DESC);
CREATE INDEX idx_prospect_tracking_follow_up ON prospect_tracking(next_follow_up_date);
CREATE INDEX idx_prospect_tracking_assigned ON prospect_tracking(assigned_to);

-- Analysis history indexes
CREATE INDEX idx_analysis_history_tenant_id ON analysis_history(tenant_id);
CREATE INDEX idx_analysis_history_company_id ON analysis_history(company_id);
CREATE INDEX idx_analysis_history_type ON analysis_history(analysis_type);
CREATE INDEX idx_analysis_history_created_at ON analysis_history(created_at DESC);

-- Workflow executions indexes
CREATE INDEX idx_workflow_executions_tenant_id ON workflow_executions(tenant_id);
CREATE INDEX idx_workflow_executions_workflow_id ON workflow_executions(workflow_id);
CREATE INDEX idx_workflow_executions_status ON workflow_executions(status);
CREATE INDEX idx_workflow_executions_started_at ON workflow_executions(started_at DESC);

-- API usage logs indexes
CREATE INDEX idx_api_usage_tenant_id ON api_usage_logs(tenant_id);
CREATE INDEX idx_api_usage_service ON api_usage_logs(service_provider);
CREATE INDEX idx_api_usage_company_id ON api_usage_logs(company_id);
CREATE INDEX idx_api_usage_created_at ON api_usage_logs(created_at DESC);
CREATE INDEX idx_api_usage_cost ON api_usage_logs(cost_usd);

-- Audit logs indexes
CREATE INDEX idx_audit_logs_tenant_id ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_risk_level ON audit_logs(risk_level);

-- Performance metrics indexes
CREATE INDEX idx_performance_metrics_tenant_id ON performance_metrics(tenant_id);
CREATE INDEX idx_performance_metrics_type ON performance_metrics(metric_type);
CREATE INDEX idx_performance_metrics_name ON performance_metrics(metric_name);
CREATE INDEX idx_performance_metrics_time ON performance_metrics(measurement_time DESC);

-- ============================================================================
-- Triggers for Automatic Timestamp Updates
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_website_analyses_updated_at BEFORE UPDATE ON website_analyses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customer_journey_analyses_updated_at BEFORE UPDATE ON customer_journey_analyses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_automation_opportunities_updated_at BEFORE UPDATE ON automation_opportunities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_packages_updated_at BEFORE UPDATE ON service_packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roi_projections_updated_at BEFORE UPDATE ON roi_projections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_deliveries_updated_at BEFORE UPDATE ON report_deliveries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_instantly_integrations_updated_at BEFORE UPDATE ON instantly_integrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_instantly_campaigns_updated_at BEFORE UPDATE ON instantly_campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_instantly_sequences_updated_at BEFORE UPDATE ON instantly_sequences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prospect_tracking_updated_at BEFORE UPDATE ON prospect_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Row Level Security (RLS) Setup for Multi-Tenancy
-- ============================================================================

-- Enable RLS on all tenant-scoped tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE website_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_journey_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE automation_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE roi_projections ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE instantly_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE instantly_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE instantly_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE instantly_email_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE instantly_deliverability ENABLE ROW LEVEL SECURITY;
ALTER TABLE prospect_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE analysis_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (example for companies table - replicate pattern for others)
CREATE POLICY tenant_isolation_policy ON companies
    FOR ALL
    TO authenticated
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID);

-- ============================================================================
-- Utility Functions
-- ============================================================================

-- Function to calculate lead score based on multiple factors
CREATE OR REPLACE FUNCTION calculate_lead_score(
    p_company_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_company_size_score INTEGER := 0;
    v_automation_score INTEGER := 0;
    v_engagement_score INTEGER := 0;
    v_fit_score INTEGER := 0;
BEGIN
    -- Company size scoring (0-25 points)
    SELECT CASE 
        WHEN c.company_size_category = 'enterprise' THEN 25
        WHEN c.company_size_category = 'large' THEN 20
        WHEN c.company_size_category = 'medium' THEN 15
        WHEN c.company_size_category = 'small' THEN 10
        ELSE 5
    END INTO v_company_size_score
    FROM companies c WHERE c.id = p_company_id;
    
    -- Automation opportunity scoring (0-35 points)
    SELECT LEAST(35, COALESCE(AVG(priority_score), 0) * 0.35) INTO v_automation_score
    FROM automation_opportunities ao WHERE ao.company_id = p_company_id;
    
    -- Engagement scoring based on analysis completeness (0-25 points)
    SELECT CASE 
        WHEN COUNT(*) >= 3 THEN 25  -- Multiple analyses completed
        WHEN COUNT(*) = 2 THEN 20
        WHEN COUNT(*) = 1 THEN 15
        ELSE 0
    END INTO v_engagement_score
    FROM (
        SELECT 1 FROM website_analyses wa WHERE wa.company_id = p_company_id AND wa.scraping_status = 'completed'
        UNION
        SELECT 1 FROM customer_journey_analyses cja WHERE cja.company_id = p_company_id
    ) analysis_count;
    
    -- Service fit scoring (0-15 points)
    SELECT LEAST(15, COUNT(*) * 5) INTO v_fit_score
    FROM automation_opportunities ao 
    WHERE ao.company_id = p_company_id 
    AND ao.service_tier IS NOT NULL;
    
    v_score := v_company_size_score + v_automation_score + v_engagement_score + v_fit_score;
    
    RETURN LEAST(100, v_score);  -- Cap at 100
END;
$$ LANGUAGE plpgsql;

-- Function to update prospect stage automatically based on analysis completion
CREATE OR REPLACE FUNCTION update_prospect_stage_on_analysis()
RETURNS TRIGGER AS $$
BEGIN
    -- Update prospect stage when analysis is completed
    IF NEW.scraping_status = 'completed' OR NEW.analysis_version > COALESCE(OLD.analysis_version, 0) THEN
        UPDATE companies 
        SET status = CASE 
            WHEN status = 'identified' THEN 'analyzing'
            WHEN status = 'analyzing' THEN 'analyzed'
            ELSE status
        END
        WHERE id = NEW.company_id;
        
        -- Update lead score
        UPDATE prospect_tracking 
        SET lead_score = calculate_lead_score(NEW.company_id)
        WHERE company_id = NEW.company_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to website analyses
CREATE TRIGGER update_prospect_stage_trigger 
    AFTER INSERT OR UPDATE ON website_analyses
    FOR EACH ROW EXECUTE FUNCTION update_prospect_stage_on_analysis();

-- Function to calculate engagement score based on email activities
CREATE OR REPLACE FUNCTION calculate_engagement_score(
    p_integration_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_score INTEGER := 0;
    v_email_metrics RECORD;
    v_activity_metrics RECORD;
    v_time_metrics RECORD;
BEGIN
    -- Get email metrics
    SELECT 
        emails_sent,
        emails_opened,
        emails_clicked,
        emails_replied,
        emails_bounced,
        EXTRACT(EPOCH FROM (NOW() - first_email_sent_at))/86400 as days_since_first_email,
        EXTRACT(EPOCH FROM (NOW() - last_activity_at))/86400 as days_since_last_activity
    INTO v_email_metrics
    FROM instantly_integrations
    WHERE id = p_integration_id;
    
    -- Base scoring from email interactions (0-60 points)
    IF v_email_metrics.emails_sent > 0 THEN
        -- Open rate scoring (0-15 points)
        v_score := v_score + LEAST(15, (v_email_metrics.emails_opened::DECIMAL / v_email_metrics.emails_sent * 100 * 0.6)::INTEGER);
        
        -- Click rate scoring (0-20 points)
        IF v_email_metrics.emails_opened > 0 THEN
            v_score := v_score + LEAST(20, (v_email_metrics.emails_clicked::DECIMAL / v_email_metrics.emails_opened * 100 * 6.67)::INTEGER);
        END IF;
        
        -- Reply scoring (0-25 points)
        v_score := v_score + LEAST(25, v_email_metrics.emails_replied * 25);
        
        -- Penalty for bounces
        v_score := v_score - (v_email_metrics.emails_bounced * 5);
    END IF;
    
    -- Time-based engagement (0-20 points)
    IF v_email_metrics.days_since_last_activity IS NOT NULL THEN
        -- Recent activity bonus
        IF v_email_metrics.days_since_last_activity <= 1 THEN
            v_score := v_score + 20;
        ELSIF v_email_metrics.days_since_last_activity <= 7 THEN
            v_score := v_score + 15;
        ELSIF v_email_metrics.days_since_last_activity <= 30 THEN
            v_score := v_score + 10;
        ELSIF v_email_metrics.days_since_last_activity <= 90 THEN
            v_score := v_score + 5;
        END IF;
    END IF;
    
    -- Activity frequency bonus (0-20 points)
    SELECT COUNT(*), COUNT(DISTINCT DATE(activity_timestamp))
    INTO v_activity_metrics.total_activities, v_activity_metrics.active_days
    FROM instantly_email_activities 
    WHERE integration_id = p_integration_id 
    AND activity_timestamp > NOW() - INTERVAL '30 days';
    
    IF v_activity_metrics.active_days > 0 THEN
        v_score := v_score + LEAST(20, v_activity_metrics.active_days * 2);
    END IF;
    
    -- Cap score between 0 and 100
    RETURN GREATEST(0, LEAST(100, v_score));
END;
$$ LANGUAGE plpgsql;

-- Function to determine optimal campaign assignment
CREATE OR REPLACE FUNCTION get_optimal_campaign_assignment(
    p_lead_score INTEGER,
    p_roi_potential DECIMAL,
    p_industry TEXT,
    p_company_size TEXT,
    p_opportunities_count INTEGER
) RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_campaign_id TEXT;
    v_sequence_id TEXT;
    v_delay_hours DECIMAL;
    v_priority TEXT;
BEGIN
    -- Default values
    v_campaign_id := 'entelech_cold_outreach';
    v_sequence_id := 'seq_cold_education';
    v_delay_hours := 24;
    v_priority := 'low';
    
    -- High-value enterprise leads
    IF p_lead_score >= 80 OR p_roi_potential > 50000 THEN
        v_campaign_id := 'entelech_enterprise_vip';
        v_sequence_id := 'seq_enterprise_executive';
        v_delay_hours := 0.5;
        v_priority := 'high';
    
    -- Professional service prospects  
    ELSIF p_lead_score >= 60 OR (p_roi_potential > 25000 AND p_opportunities_count >= 2) THEN
        v_campaign_id := 'entelech_professional_priority';
        v_sequence_id := 'seq_professional_priority';
        v_delay_hours := 1;
        v_priority := 'medium';
        
    -- Warm prospects with automation needs
    ELSIF p_lead_score >= 40 OR p_opportunities_count >= 1 THEN
        v_campaign_id := 'entelech_warm_prospects';
        v_sequence_id := 'seq_warm_nurture';
        v_delay_hours := 4;
        v_priority := 'medium';
    END IF;
    
    -- Industry-specific adjustments
    IF p_industry ILIKE ANY(ARRAY['%legal%', '%healthcare%', '%financial%']) THEN
        v_sequence_id := v_sequence_id || '_compliance';
        v_delay_hours := GREATEST(v_delay_hours, 2);
    END IF;
    
    -- Company size adjustments
    IF p_company_size IN ('enterprise', 'large') THEN
        v_delay_hours := GREATEST(v_delay_hours, 4);
    END IF;
    
    -- Build result JSON
    v_result := json_build_object(
        'campaign_id', v_campaign_id,
        'sequence_id', v_sequence_id,
        'delay_hours', v_delay_hours,
        'priority', v_priority,
        'assignment_reason', format('Lead Score: %s, ROI: $%sK, Opportunities: %s', 
                                   p_lead_score, 
                                   ROUND(p_roi_potential/1000), 
                                   p_opportunities_count)
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to analyze reply sentiment and intent
CREATE OR REPLACE FUNCTION analyze_reply_basic(
    p_reply_content TEXT
) RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_sentiment TEXT := 'neutral';
    v_intent TEXT := 'general_inquiry';
    v_keywords_positive TEXT[] := ARRAY['interested', 'yes', 'sounds good', 'tell me more', 'schedule', 'call', 'meeting', 'demo', 'pricing', 'learn more'];
    v_keywords_negative TEXT[] := ARRAY['not interested', 'no', 'remove', 'unsubscribe', 'stop', 'spam', 'delete', 'busy', 'no thanks'];
    v_keywords_meeting TEXT[] := ARRAY['meeting', 'call', 'demo', 'schedule', 'chat', 'discuss'];
    v_keywords_pricing TEXT[] := ARRAY['price', 'cost', 'pricing', 'budget', 'quote', 'proposal'];
    v_content_lower TEXT;
BEGIN
    v_content_lower := LOWER(COALESCE(p_reply_content, ''));
    
    -- Sentiment analysis
    IF v_content_lower ~ ANY(v_keywords_positive) THEN
        v_sentiment := 'positive';
    ELSIF v_content_lower ~ ANY(v_keywords_negative) THEN
        v_sentiment := 'negative';
    END IF;
    
    -- Intent classification
    IF v_content_lower ~ ANY(v_keywords_meeting) THEN
        v_intent := 'meeting_request';
    ELSIF v_content_lower ~ ANY(v_keywords_pricing) THEN
        v_intent := 'pricing_inquiry';
    ELSIF v_content_lower ~ 'remove|unsubscribe' THEN
        v_intent := 'unsubscribe_request';
    ELSIF v_sentiment = 'positive' THEN
        v_intent := 'interested';
    ELSIF v_sentiment = 'negative' THEN
        v_intent := 'not_interested';
    END IF;
    
    v_result := json_build_object(
        'sentiment', v_sentiment,
        'intent', v_intent,
        'confidence', CASE 
            WHEN v_content_lower ~ ANY(v_keywords_positive || v_keywords_negative) THEN 'high'
            ELSE 'medium'
        END,
        'requires_human_review', v_sentiment IN ('positive', 'interested') OR v_intent = 'meeting_request'
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update engagement scores
CREATE OR REPLACE FUNCTION update_engagement_on_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Update engagement score when new email activity is recorded
    IF NEW.activity_type IN ('opened', 'clicked', 'replied') THEN
        UPDATE instantly_integrations 
        SET 
            engagement_score = calculate_engagement_score(NEW.integration_id),
            lead_temperature = CASE 
                WHEN NEW.activity_type = 'replied' AND NEW.reply_sentiment = 'positive' THEN 'hot'
                WHEN NEW.activity_type = 'replied' AND NEW.reply_sentiment = 'negative' THEN 'cold'
                WHEN NEW.activity_type = 'clicked' THEN 'warm'
                ELSE lead_temperature
            END,
            last_activity_at = NEW.activity_timestamp
        WHERE id = NEW.integration_id;
        
        -- Update lead status based on activity
        IF NEW.activity_type = 'replied' THEN
            UPDATE instantly_integrations 
            SET lead_status = CASE 
                WHEN NEW.reply_sentiment = 'negative' OR NEW.reply_intent = 'unsubscribe_request' THEN 'unsubscribed'
                WHEN NEW.reply_sentiment = 'positive' OR NEW.reply_intent = 'interested' THEN 'replied'
                ELSE lead_status
            END
            WHERE id = NEW.integration_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the engagement update trigger
CREATE TRIGGER update_engagement_trigger 
    AFTER INSERT ON instantly_email_activities
    FOR EACH ROW EXECUTE FUNCTION update_engagement_on_activity();

-- ============================================================================
-- Views for Common Queries
-- ============================================================================

-- Comprehensive company analysis view
CREATE VIEW v_company_analysis_summary AS
SELECT 
    c.id,
    c.tenant_id,
    c.name,
    c.website,
    c.industry,
    c.company_size_category,
    c.status as company_status,
    
    -- Latest website analysis
    wa.analysis_version as latest_website_analysis_version,
    wa.current_automation_level,
    wa.content_quality_score,
    wa.scraping_status as website_scraping_status,
    
    -- Latest customer journey analysis
    cja.journey_quality_score,
    cja.automation_readiness_score,
    
    -- Automation opportunities summary
    ao_stats.total_opportunities,
    ao_stats.total_annual_savings,
    ao_stats.avg_roi_percentage,
    ao_stats.recommended_service_tier,
    
    -- Prospect tracking
    pt.current_stage,
    pt.lead_score,
    pt.qualification_status,
    pt.next_follow_up_date,
    pt.assigned_to,
    
    c.created_at,
    c.updated_at
FROM companies c
LEFT JOIN LATERAL (
    SELECT * FROM website_analyses wa2 
    WHERE wa2.company_id = c.id 
    ORDER BY wa2.analysis_version DESC 
    LIMIT 1
) wa ON true
LEFT JOIN LATERAL (
    SELECT * FROM customer_journey_analyses cja2 
    WHERE cja2.company_id = c.id 
    ORDER BY cja2.analysis_version DESC 
    LIMIT 1
) cja ON true
LEFT JOIN LATERAL (
    SELECT 
        COUNT(*) as total_opportunities,
        SUM(annual_savings) as total_annual_savings,
        AVG(roi_percentage) as avg_roi_percentage,
        MODE() WITHIN GROUP (ORDER BY service_tier) as recommended_service_tier
    FROM automation_opportunities ao2 
    WHERE ao2.company_id = c.id 
    AND ao2.status = 'identified'
) ao_stats ON true
LEFT JOIN prospect_tracking pt ON pt.company_id = c.id;

-- Instantly campaign performance view
CREATE VIEW v_instantly_campaign_performance AS
SELECT 
    ic.id,
    ic.tenant_id,
    ic.instantly_campaign_id,
    ic.campaign_name,
    ic.campaign_type,
    ic.target_service_tier,
    ic.campaign_status,
    
    -- Performance metrics
    ic.total_leads_added,
    ic.total_emails_sent,
    ic.total_replies,
    ic.total_opens,
    ic.total_clicks,
    ic.total_bounces,
    ic.total_unsubscribes,
    
    -- Calculated rates
    ic.overall_open_rate,
    ic.overall_click_rate,
    ic.overall_reply_rate,
    ic.overall_bounce_rate,
    
    -- Performance scoring (0-100)
    LEAST(100, GREATEST(0, 
        (ic.overall_open_rate * 2) + 
        (ic.overall_click_rate * 5) + 
        (ic.overall_reply_rate * 10) - 
        (ic.overall_bounce_rate * 2) - 
        (CASE WHEN ic.total_unsubscribes > 0 THEN (ic.total_unsubscribes::DECIMAL / NULLIF(ic.total_emails_sent, 0) * 100 * 5) ELSE 0 END)
    )) as performance_score,
    
    -- Health status
    CASE 
        WHEN ic.overall_bounce_rate > 10 OR (ic.total_unsubscribes::DECIMAL / NULLIF(ic.total_emails_sent, 0) * 100) > 3 THEN 'critical'
        WHEN ic.overall_bounce_rate > 5 OR (ic.total_unsubscribes::DECIMAL / NULLIF(ic.total_emails_sent, 0) * 100) > 1.5 THEN 'warning'
        ELSE 'good'
    END as delivery_health,
    
    -- Lead integration stats
    COUNT(ii.id) as integrated_leads,
    COUNT(CASE WHEN ii.lead_status = 'replied' THEN 1 END) as replied_leads,
    COUNT(CASE WHEN ii.lead_temperature = 'hot' THEN 1 END) as hot_leads,
    AVG(ii.engagement_score) as avg_engagement_score,
    
    ic.created_at,
    ic.updated_at
FROM instantly_campaigns ic
LEFT JOIN instantly_integrations ii ON ii.instantly_campaign_id = ic.instantly_campaign_id
GROUP BY ic.id, ic.tenant_id, ic.instantly_campaign_id, ic.campaign_name, ic.campaign_type,
         ic.target_service_tier, ic.campaign_status, ic.total_leads_added, ic.total_emails_sent,
         ic.total_replies, ic.total_opens, ic.total_clicks, ic.total_bounces, ic.total_unsubscribes,
         ic.overall_open_rate, ic.overall_click_rate, ic.overall_reply_rate, ic.overall_bounce_rate,
         ic.created_at, ic.updated_at;

-- Instantly lead engagement analysis view
CREATE VIEW v_instantly_lead_engagement AS
SELECT 
    ii.id,
    ii.tenant_id,
    ii.company_id,
    c.name as company_name,
    c.industry,
    c.company_size_category,
    
    ii.instantly_lead_id,
    ii.instantly_campaign_id,
    ii.lead_status,
    ii.lead_temperature,
    ii.engagement_score,
    ii.service_package_tier,
    ii.roi_potential,
    
    -- Email activity summary
    ii.emails_sent,
    ii.emails_opened,
    ii.emails_clicked,
    ii.emails_replied,
    ii.emails_bounced,
    
    -- Engagement rates
    CASE WHEN ii.emails_sent > 0 THEN (ii.emails_opened::DECIMAL / ii.emails_sent * 100) ELSE 0 END as personal_open_rate,
    CASE WHEN ii.emails_opened > 0 THEN (ii.emails_clicked::DECIMAL / ii.emails_opened * 100) ELSE 0 END as personal_click_rate,
    CASE WHEN ii.emails_sent > 0 THEN (ii.emails_replied::DECIMAL / ii.emails_sent * 100) ELSE 0 END as personal_reply_rate,
    
    -- Timeline analysis
    ii.first_email_sent_at,
    ii.first_open_at,
    ii.first_click_at,
    ii.first_reply_at,
    ii.last_activity_at,
    
    -- Time to engagement metrics
    EXTRACT(EPOCH FROM (ii.first_open_at - ii.first_email_sent_at))/3600 as hours_to_first_open,
    EXTRACT(EPOCH FROM (ii.first_click_at - ii.first_email_sent_at))/3600 as hours_to_first_click,
    EXTRACT(EPOCH FROM (ii.first_reply_at - ii.first_email_sent_at))/3600 as hours_to_first_reply,
    
    -- Recent activity flags
    ii.last_activity_at > NOW() - INTERVAL '7 days' as active_last_week,
    ii.last_activity_at > NOW() - INTERVAL '30 days' as active_last_month,
    
    ii.created_at,
    ii.updated_at
FROM instantly_integrations ii
LEFT JOIN companies c ON c.id = ii.company_id
WHERE ii.lead_status != 'unsubscribed';

-- Instantly deliverability monitoring view  
CREATE VIEW v_instantly_deliverability_trends AS
SELECT 
    tenant_id,
    sending_domain,
    tracking_date,
    
    -- Daily metrics
    emails_sent,
    emails_delivered,
    emails_bounced,
    hard_bounces,
    soft_bounces,
    unsubscribes,
    
    -- Daily rates
    delivery_rate,
    bounce_rate,
    spam_rate,
    
    -- Health indicators
    domain_reputation_score,
    health_status,
    
    -- Weekly rolling averages (7-day window)
    AVG(delivery_rate) OVER (
        PARTITION BY tenant_id, sending_domain 
        ORDER BY tracking_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as weekly_avg_delivery_rate,
    
    AVG(bounce_rate) OVER (
        PARTITION BY tenant_id, sending_domain 
        ORDER BY tracking_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as weekly_avg_bounce_rate,
    
    AVG(domain_reputation_score) OVER (
        PARTITION BY tenant_id, sending_domain 
        ORDER BY tracking_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as weekly_avg_reputation,
    
    -- Trend indicators
    LAG(delivery_rate, 1) OVER (PARTITION BY tenant_id, sending_domain ORDER BY tracking_date) as prev_day_delivery_rate,
    LAG(bounce_rate, 1) OVER (PARTITION BY tenant_id, sending_domain ORDER BY tracking_date) as prev_day_bounce_rate,
    LAG(domain_reputation_score, 1) OVER (PARTITION BY tenant_id, sending_domain ORDER BY tracking_date) as prev_day_reputation,
    
    created_at
FROM instantly_deliverability
ORDER BY tenant_id, sending_domain, tracking_date DESC;

-- Service package performance view
CREATE VIEW v_service_package_performance AS
SELECT 
    sp.package_tier,
    sp.name,
    sp.price_usd,
    COUNT(ao.id) as total_recommendations,
    COUNT(CASE WHEN ao.status = 'accepted' THEN 1 END) as accepted_count,
    COUNT(CASE WHEN ao.status = 'rejected' THEN 1 END) as rejected_count,
    ROUND(
        COUNT(CASE WHEN ao.status = 'accepted' THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(ao.id), 0) * 100, 2
    ) as acceptance_rate,
    AVG(ao.package_fit_score) as avg_fit_score,
    SUM(CASE WHEN ao.status = 'accepted' THEN sp.price_usd ELSE 0 END) as total_revenue
FROM service_packages sp
LEFT JOIN automation_opportunities ao ON ao.service_tier = sp.package_tier
WHERE sp.is_active = true
GROUP BY sp.id, sp.package_tier, sp.name, sp.price_usd;

-- ============================================================================
-- Sample Data Insertion Examples
-- ============================================================================

-- Insert sample tenant
INSERT INTO tenants (id, name, domain, subscription_tier, settings) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Entelech Solutions', 'entelech.com', 'enterprise', 
 '{"branding": {"primary_color": "#1a73e8", "logo_url": "/assets/logo.png"}, "features": {"advanced_analytics": true, "custom_reporting": true}}');

-- Insert sample user
INSERT INTO users (id, tenant_id, email, password_hash, first_name, last_name, role) VALUES
('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 
 'admin@entelech.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeJAMkd/EGczOPhmy', 
 'Admin', 'User', 'admin');

-- Insert sample service packages
INSERT INTO service_packages (tenant_id, package_tier, name, description, price_usd, duration_weeks, features, deliverables) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'basic_2_5k', 'Basic Automation Package', 
 'Entry-level automation for small businesses', 2500.00, 4,
 '["Lead capture automation", "Email sequences", "Basic CRM integration"]',
 '["Automated lead forms", "5 email sequences", "CRM setup guide"]'),
 
('550e8400-e29b-41d4-a716-446655440001', 'professional_7_5k', 'Professional Automation Suite', 
 'Comprehensive automation for growing businesses', 7500.00, 8,
 '["Advanced lead nurturing", "Multi-channel automation", "Custom integrations", "Analytics dashboard"]',
 '["Complete automation setup", "15 email sequences", "Custom integrations", "Monthly reporting"]'),
 
('550e8400-e29b-41d4-a716-446655440001', 'enterprise_15k', 'Enterprise Automation Platform', 
 'Full-scale automation solution for large organizations', 15000.00, 12,
 '["Enterprise-grade automation", "Custom AI integration", "Advanced analytics", "White-label solution"]',
 '["Complete platform setup", "Unlimited sequences", "AI-powered optimization", "Dedicated support"]');

-- Insert sample company
INSERT INTO companies (id, tenant_id, name, website, domain, industry, company_size_category, 
                      employee_count_min, employee_count_max, status, created_by) VALUES
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440001',
 'TechCorp Solutions', 'https://techcorp.example.com', 'techcorp.example.com', 
 'Technology Services', 'medium', 50, 200, 'identified', 
 '550e8400-e29b-41d4-a716-446655440002');

-- Insert sample website analysis
INSERT INTO website_analyses (tenant_id, company_id, analysis_version, url_analyzed, scraping_status, 
                             services_identified, current_automation_level, content_quality_score,
                             tools_detected, tech_infrastructure) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440010', 
 1, 'https://techcorp.example.com', 'completed',
 '["Web Development", "Cloud Migration", "IT Consulting"]',
 'basic', 75,
 '["Google Analytics", "HubSpot", "WordPress"]',
 '{"cms": "WordPress", "hosting": "AWS", "ssl": true, "cdn": "CloudFlare"}');

-- Insert sample automation opportunity
INSERT INTO automation_opportunities (tenant_id, company_id, analysis_version, process_name, 
                                    process_category, time_spent_hours_per_week, annual_cost_current,
                                    automation_type, implementation_cost, annual_savings, roi_percentage,
                                    service_tier, priority_score) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440010',
 1, 'Lead Qualification Process', 'Sales', 15.0, 39000.00,
 'Automated Lead Scoring', 5000.00, 25000.00, 400.0,
 'professional_7_5k', 85);

-- Insert sample prospect tracking
INSERT INTO prospect_tracking (tenant_id, company_id, current_stage, lead_score, 
                              qualification_status, next_follow_up_date, assigned_to, created_by) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440010',
 'analyzed', 78, 'marketing_qualified', CURRENT_DATE + INTERVAL '3 days',
 '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002');

-- Insert sample report
INSERT INTO reports (tenant_id, company_id, report_type, title, generation_status, 
                    template_version, file_name, created_by) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440010',
 'automation_assessment', 'TechCorp Solutions - Automation Assessment Report', 'completed',
 'v2.1', 'techcorp_automation_assessment_20250825.pdf', 
 '550e8400-e29b-41d4-a716-446655440002');

-- Insert sample Instantly campaign
INSERT INTO instantly_campaigns (tenant_id, instantly_campaign_id, campaign_name, campaign_type,
                                target_service_tier, target_lead_score_min, target_lead_score_max,
                                sequence_steps, campaign_status) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'camp_prof_7_5k_001', 
 'Professional Services - $7.5K Package Outreach', 'outreach',
 'professional_7_5k', 60, 85, 5, 'active');

-- Insert sample Instantly sequence
INSERT INTO instantly_sequences (tenant_id, campaign_id, instantly_sequence_id, sequence_name,
                                total_steps, uses_ai_personalization, sequence_status) VALUES
('550e8400-e29b-41d4-a716-446655440001', 
 (SELECT id FROM instantly_campaigns WHERE instantly_campaign_id = 'camp_prof_7_5k_001'),
 'seq_prof_001', 'Professional Service Automation Sequence', 5, TRUE, 'active');

-- Insert sample Instantly integration
INSERT INTO instantly_integrations (tenant_id, company_id, instantly_lead_id, instantly_campaign_id,
                                   instantly_sequence_id, lead_status, lead_temperature, engagement_score,
                                   assignment_reason, roi_potential, service_package_tier) VALUES
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440010',
 'lead_tc001', 'camp_prof_7_5k_001', 'seq_prof_001', 'active', 'warm', 78,
 'High lead score (78) and professional service business model', 25000.00, 'professional_7_5k');

-- ============================================================================
-- Performance and Maintenance Recommendations
-- ============================================================================

/*
PERFORMANCE OPTIMIZATION RECOMMENDATIONS:

1. Partitioning Strategy:
   - Consider partitioning large tables like audit_logs, api_usage_logs, and workflow_executions by date
   - Partition performance_metrics by measurement_time for efficient time-series queries

2. Index Maintenance:
   - Monitor query performance and add composite indexes for frequently used WHERE clauses
   - Consider partial indexes for filtered queries (e.g., WHERE status = 'active')
   - Use EXPLAIN ANALYZE to identify slow queries and optimize accordingly

3. Data Retention Policies:
   - Implement automated cleanup for old audit logs, API usage logs, and performance metrics
   - Archive completed workflow executions older than 90 days
   - Set up log rotation for debugging and monitoring data

4. Connection Pooling:
   - Use connection pooling (PgBouncer) for high-concurrency workloads
   - Configure appropriate pool sizes based on Azure Database for PostgreSQL limits

5. Monitoring and Alerting:
   - Monitor key performance metrics: query duration, connection count, cache hit ratio
   - Set up alerts for unusual patterns in automation opportunities and lead scoring
   - Track API usage costs and implement rate limiting as needed

6. Backup and Recovery:
   - Configure point-in-time recovery with appropriate retention periods
   - Test disaster recovery procedures regularly
   - Consider geo-redundant backups for critical data

7. Security Best Practices:
   - Regularly rotate API keys and connection strings stored in Azure Key Vault
   - Monitor audit logs for suspicious activity patterns
   - Implement IP whitelisting for database access
   - Use SSL/TLS for all database connections

8. Multi-tenant Optimization:
   - Monitor tenant resource usage and implement quotas if needed
   - Consider tenant-specific read replicas for large customers
   - Optimize RLS policies for performance impact
*/