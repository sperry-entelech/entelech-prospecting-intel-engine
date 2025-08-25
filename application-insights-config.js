/**
 * Application Insights Configuration for Prospect Intelligence Engine
 * Enterprise-grade monitoring with custom telemetry and business intelligence dashboards
 * SOC 2 Type II compliant logging and performance monitoring
 */

const appInsights = require('applicationinsights');
const os = require('os');

class ProspectIntelligenceMonitoring {
  constructor(options = {}) {
    this.connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
    this.instrumentationKey = process.env.APPINSIGHTS_INSTRUMENTATIONKEY;
    this.environment = process.env.NODE_ENV || 'production';
    this.serviceName = options.serviceName || 'prospect-intelligence-engine';
    this.version = options.version || '2.1.0';
    
    this.initializeApplicationInsights();
    this.setupCustomDimensions();
    this.configurePerformanceCounters();
  }

  /**
   * Initialize Application Insights with enterprise configuration
   */
  initializeApplicationInsights() {
    if (!this.connectionString && !this.instrumentationKey) {
      console.warn('Application Insights not configured - monitoring disabled');
      return;
    }

    // Initialize with connection string (preferred) or instrumentation key
    if (this.connectionString) {
      appInsights.setup(this.connectionString);
    } else {
      appInsights.setup(this.instrumentationKey);
    }

    // Configure telemetry
    appInsights
      .setAutoDependencyCorrelation(true)
      .setAutoCollectRequests(true)
      .setAutoCollectPerformance(true, true)
      .setAutoCollectExceptions(true)
      .setAutoCollectDependencies(true)
      .setAutoCollectConsole(true, true)
      .setUseDiskRetriesOnFailure(true)
      .setSendLiveMetrics(true)
      .setDistributedTracingMode(appInsights.DistributedTracingModes.AI_AND_W3C)
      .start();

    // Get telemetry client for custom metrics
    this.client = appInsights.defaultClient;
    
    // Set cloud role name and instance
    this.client.context.tags[this.client.context.keys.cloudRole] = this.serviceName;
    this.client.context.tags[this.client.context.keys.cloudRoleInstance] = os.hostname();
    
    console.log(`Application Insights initialized for ${this.serviceName}`);
  }

  /**
   * Set up global custom dimensions for all telemetry
   */
  setupCustomDimensions() {
    if (!this.client) return;

    // Add global properties to all telemetry
    this.client.commonProperties = {
      environment: this.environment,
      serviceName: this.serviceName,
      version: this.version,
      nodeVersion: process.version,
      platform: process.platform,
      architecture: process.arch
    };
  }

  /**
   * Configure custom performance counters
   */
  configurePerformanceCounters() {
    if (!this.client) return;

    // Track custom performance counters
    setInterval(() => {
      const memUsage = process.memoryUsage();
      const cpuUsage = process.cpuUsage();
      
      // Memory metrics
      this.client.trackMetric({
        name: 'Memory_RSS_MB',
        value: Math.round(memUsage.rss / 1024 / 1024)
      });
      
      this.client.trackMetric({
        name: 'Memory_HeapUsed_MB',
        value: Math.round(memUsage.heapUsed / 1024 / 1024)
      });
      
      this.client.trackMetric({
        name: 'Memory_External_MB',
        value: Math.round(memUsage.external / 1024 / 1024)
      });

      // CPU metrics
      this.client.trackMetric({
        name: 'CPU_User_Microseconds',
        value: cpuUsage.user
      });
      
      this.client.trackMetric({
        name: 'CPU_System_Microseconds',
        value: cpuUsage.system
      });

    }, 30000); // Every 30 seconds
  }

  /**
   * Track n8n workflow execution metrics
   */
  trackWorkflowExecution(workflowData) {
    if (!this.client) return;

    const {
      workflowId,
      workflowName,
      executionId,
      status,
      duration,
      nodeCount,
      triggerType,
      companyId,
      tenantId,
      errorDetails
    } = workflowData;

    // Track execution as custom event
    this.client.trackEvent({
      name: 'WorkflowExecution',
      properties: {
        workflowId,
        workflowName,
        executionId,
        status,
        triggerType,
        companyId,
        tenantId,
        nodeCount: nodeCount?.toString(),
        errorMessage: errorDetails?.message,
        errorStack: errorDetails?.stack
      },
      measurements: {
        duration: duration || 0,
        nodesExecuted: nodeCount || 0
      }
    });

    // Track execution duration
    this.client.trackMetric({
      name: 'WorkflowExecutionDuration',
      value: duration || 0,
      properties: {
        workflowName,
        status,
        triggerType
      }
    });

    // Track success/failure rates
    this.client.trackMetric({
      name: 'WorkflowExecutionCount',
      value: 1,
      properties: {
        workflowName,
        status,
        success: status === 'success' ? 'true' : 'false'
      }
    });
  }

  /**
   * Track Azure OpenAI API usage and costs
   */
  trackOpenAIUsage(usageData) {
    if (!this.client) return;

    const {
      model,
      promptTokens,
      completionTokens,
      totalTokens,
      costUSD,
      responseTime,
      operationType,
      companyId,
      workflowExecutionId,
      errorCode,
      errorMessage
    } = usageData;

    // Track API usage event
    this.client.trackEvent({
      name: 'OpenAIAPIUsage',
      properties: {
        model,
        operationType,
        companyId,
        workflowExecutionId,
        errorCode,
        errorMessage,
        success: errorCode ? 'false' : 'true'
      },
      measurements: {
        promptTokens: promptTokens || 0,
        completionTokens: completionTokens || 0,
        totalTokens: totalTokens || 0,
        costUSD: costUSD || 0,
        responseTimeMs: responseTime || 0
      }
    });

    // Track costs
    this.client.trackMetric({
      name: 'OpenAI_Cost_USD',
      value: costUSD || 0,
      properties: {
        model,
        operationType
      }
    });

    // Track token usage
    this.client.trackMetric({
      name: 'OpenAI_Tokens_Total',
      value: totalTokens || 0,
      properties: {
        model,
        tokenType: 'total'
      }
    });

    this.client.trackMetric({
      name: 'OpenAI_Tokens_Prompt',
      value: promptTokens || 0,
      properties: {
        model,
        tokenType: 'prompt'
      }
    });

    this.client.trackMetric({
      name: 'OpenAI_Tokens_Completion',
      value: completionTokens || 0,
      properties: {
        model,
        tokenType: 'completion'
      }
    });
  }

  /**
   * Track business intelligence metrics
   */
  trackBusinessMetrics(businessData) {
    if (!this.client) return;

    const {
      eventType,
      companyId,
      tenantId,
      leadScore,
      automationOpportunities,
      potentialSavings,
      recommendedPackageTier,
      conversionStage,
      analysisQualityScore
    } = businessData;

    this.client.trackEvent({
      name: 'BusinessIntelligenceEvent',
      properties: {
        eventType,
        companyId,
        tenantId,
        recommendedPackageTier,
        conversionStage
      },
      measurements: {
        leadScore: leadScore || 0,
        automationOpportunities: automationOpportunities || 0,
        potentialSavings: potentialSavings || 0,
        analysisQualityScore: analysisQualityScore || 0
      }
    });

    // Track lead generation pipeline metrics
    if (eventType === 'leadGenerated' || eventType === 'leadQualified') {
      this.client.trackMetric({
        name: 'LeadScore',
        value: leadScore || 0,
        properties: {
          eventType,
          packageTier: recommendedPackageTier
        }
      });
    }

    // Track ROI potential
    if (potentialSavings) {
      this.client.trackMetric({
        name: 'PotentialSavings_USD',
        value: potentialSavings,
        properties: {
          companyId,
          packageTier: recommendedPackageTier
        }
      });
    }
  }

  /**
   * Track database performance metrics
   */
  trackDatabaseMetrics(dbMetrics) {
    if (!this.client) return;

    const {
      operation,
      queryDuration,
      rowsAffected,
      connectionPoolSize,
      activeConnections,
      tableName,
      errorDetails
    } = dbMetrics;

    // Track database operations
    this.client.trackDependency({
      target: process.env.POSTGRES_HOST || 'postgresql',
      name: `${operation}_${tableName}`,
      data: operation,
      duration: queryDuration || 0,
      resultCode: errorDetails ? 'Error' : 'Success',
      success: !errorDetails,
      dependencyTypeName: 'PostgreSQL'
    });

    // Track query performance
    this.client.trackMetric({
      name: 'Database_Query_Duration_Ms',
      value: queryDuration || 0,
      properties: {
        operation,
        tableName,
        success: errorDetails ? 'false' : 'true'
      }
    });

    // Track connection pool metrics
    if (connectionPoolSize !== undefined) {
      this.client.trackMetric({
        name: 'Database_ConnectionPool_Size',
        value: connectionPoolSize
      });
    }

    if (activeConnections !== undefined) {
      this.client.trackMetric({
        name: 'Database_ActiveConnections',
        value: activeConnections
      });
    }
  }

  /**
   * Track ConvertKit integration health
   */
  trackCRMIntegration(crmData) {
    if (!this.client) return;

    const {
      operation,
      success,
      responseTime,
      subscriberCount,
      syncStatus,
      errorDetails,
      companyId
    } = crmData;

    this.client.trackDependency({
      target: 'api.convertkit.com',
      name: `ConvertKit_${operation}`,
      data: operation,
      duration: responseTime || 0,
      resultCode: success ? 'Success' : 'Error',
      success: success,
      dependencyTypeName: 'ConvertKit'
    });

    // Track integration health
    this.client.trackMetric({
      name: 'CRM_Integration_Success_Rate',
      value: success ? 1 : 0,
      properties: {
        operation,
        provider: 'ConvertKit'
      }
    });

    if (subscriberCount !== undefined) {
      this.client.trackMetric({
        name: 'CRM_Subscriber_Count',
        value: subscriberCount,
        properties: {
          companyId
        }
      });
    }
  }

  /**
   * Track report generation metrics
   */
  trackReportGeneration(reportData) {
    if (!this.client) return;

    const {
      reportType,
      companyId,
      tenantId,
      generationTime,
      fileSize,
      success,
      errorDetails,
      templateVersion
    } = reportData;

    this.client.trackEvent({
      name: 'ReportGeneration',
      properties: {
        reportType,
        companyId,
        tenantId,
        templateVersion,
        success: success ? 'true' : 'false',
        errorMessage: errorDetails?.message
      },
      measurements: {
        generationTimeMs: generationTime || 0,
        fileSizeBytes: fileSize || 0
      }
    });

    // Track report generation performance
    this.client.trackMetric({
      name: 'Report_Generation_Duration_Ms',
      value: generationTime || 0,
      properties: {
        reportType,
        success: success ? 'true' : 'false'
      }
    });

    this.client.trackMetric({
      name: 'Report_File_Size_MB',
      value: fileSize ? Math.round(fileSize / 1024 / 1024) : 0,
      properties: {
        reportType
      }
    });
  }

  /**
   * Track security events and anomalies
   */
  trackSecurityEvent(securityData) {
    if (!this.client) return;

    const {
      eventType,
      severity,
      userId,
      ipAddress,
      userAgent,
      resource,
      action,
      success,
      details
    } = securityData;

    this.client.trackEvent({
      name: 'SecurityEvent',
      properties: {
        eventType,
        severity,
        userId,
        ipAddress,
        userAgent,
        resource,
        action,
        success: success ? 'true' : 'false',
        details: JSON.stringify(details)
      }
    });

    // Track security metrics
    this.client.trackMetric({
      name: 'Security_Events_Count',
      value: 1,
      properties: {
        eventType,
        severity,
        success: success ? 'true' : 'false'
      }
    });

    // Alert on high severity events
    if (severity === 'high' || severity === 'critical') {
      this.client.trackTrace({
        message: `High severity security event: ${eventType}`,
        severity: appInsights.Contracts.SeverityLevel.Critical,
        properties: {
          eventType,
          severity,
          userId,
          ipAddress,
          resource,
          action
        }
      });
    }
  }

  /**
   * Create custom availability test
   */
  createAvailabilityTest(testName, url, testLocations = ['us-west-2']) {
    if (!this.client) return;

    // This would be configured in Azure Portal or via ARM templates
    const availabilityTest = {
      name: testName,
      url: url,
      frequency: 300, // 5 minutes
      timeout: 120, // 2 minutes
      locations: testLocations,
      successCriteria: {
        checkHttpStatus: true,
        httpStatusCode: 200
      }
    };

    console.log(`Availability test configured: ${JSON.stringify(availabilityTest)}`);
    return availabilityTest;
  }

  /**
   * Flush all telemetry (useful for serverless functions)
   */
  async flush() {
    if (!this.client) return;

    return new Promise((resolve) => {
      this.client.flush({
        callback: () => {
          resolve();
        }
      });
    });
  }

  /**
   * Create Express middleware for automatic request tracking
   */
  createRequestTrackingMiddleware() {
    if (!this.client) {
      return (req, res, next) => next();
    }

    return (req, res, next) => {
      // Add custom properties to the request telemetry
      if (req.user) {
        req.properties = {
          ...req.properties,
          userId: req.user.id,
          tenantId: req.user.tenant_id,
          userRole: req.user.role
        };
      }

      // Track API endpoint usage
      const startTime = Date.now();
      
      res.on('finish', () => {
        const duration = Date.now() - startTime;
        
        this.client.trackMetric({
          name: 'API_Request_Duration_Ms',
          value: duration,
          properties: {
            method: req.method,
            route: req.route?.path || req.path,
            statusCode: res.statusCode.toString(),
            success: res.statusCode < 400 ? 'true' : 'false'
          }
        });
      });

      next();
    };
  }
}

// Export singleton instance
const monitoring = new ProspectIntelligenceMonitoring({
  serviceName: 'prospect-intelligence-engine',
  version: process.env.npm_package_version || '2.1.0'
});

module.exports = {
  ProspectIntelligenceMonitoring,
  monitoring
};