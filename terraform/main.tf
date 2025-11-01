terraform {
  required_version = ">= 1.0"
  
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

provider "scaleway" {
  region     = var.region
  zone       = var.zone
  project_id = var.project_id
}

# VPC and Private Network
resource "scaleway_vpc" "agentops" {
  name = "${var.environment}-agentops-vpc"
  tags = ["agentops", var.environment]
}

resource "scaleway_vpc_private_network" "agentops" {
  name   = "${var.environment}-agentops-network"
  vpc_id = scaleway_vpc.agentops.id
  tags   = ["agentops", var.environment]
}

# Serverless SQL Database (PostgreSQL) - Pay per query
resource "scaleway_sdb_sql_database" "agentops" {
  name    = "${var.environment}-agentops-db"
  min_cpu = 0    # Scale to zero when idle
  max_cpu = 15   # Max 15 vCPUs for bursts
  region  = var.region
}

# Messaging and Queuing (NATS) - For agent communication
resource "scaleway_mnq_nats_account" "agentops" {
  name = "${var.environment}-agentops-messaging"
}

resource "scaleway_mnq_nats_credentials" "agentops" {
  account_id = scaleway_mnq_nats_account.agentops.id
  name       = "agentops-credentials"
}

# Secret Manager - For API keys and credentials
resource "scaleway_secret" "openrouter_api_key" {
  name        = "${var.environment}-openrouter-api-key"
  description = "OpenRouter API key for LLM access"
  tags        = ["agentops", var.environment, "api-key"]
}

resource "scaleway_secret_version" "openrouter_api_key_v1" {
  secret_id = scaleway_secret.openrouter_api_key.id
  data      = base64encode(var.openrouter_api_key)
}

resource "scaleway_secret" "db_password" {
  name        = "${var.environment}-db-password"
  description = "Serverless SQL database password"
  tags        = ["agentops", var.environment, "database"]
}

resource "scaleway_secret_version" "db_password_v1" {
  secret_id = scaleway_secret.db_password.id
  data      = base64encode(var.db_password)
}

resource "scaleway_secret" "nats_credentials" {
  name        = "${var.environment}-nats-credentials"
  description = "NATS messaging credentials"
  tags        = ["agentops", var.environment, "messaging"]
}

resource "scaleway_secret_version" "nats_credentials_v1" {
  secret_id = scaleway_secret.nats_credentials.id
  data      = base64encode(scaleway_mnq_nats_credentials.agentops.file)
}

# Redis Database for caching and state management
resource "scaleway_redis_cluster" "agentops" {
  name         = "${var.environment}-agentops-redis"
  version      = "7.2.11"
  node_type    = "RED1-MICRO" # Smallest instance: 1 vCPU, 1GB RAM
  cluster_size = 1
  
  user_name = "agentops"
  password  = var.redis_password
  
  private_network {
    id = scaleway_vpc_private_network.agentops.id
  }
  
  tags = ["agentops", "redis", var.environment]
}

# Object Storage Bucket
resource "scaleway_object_bucket" "artifacts" {
  name   = "${var.environment}-agentops-artifacts"
  region = var.region
  
  versioning {
    enabled = true
  }
  
  tags = {
    environment = var.environment
    purpose     = "artifacts"
  }
}

# Container Registry Namespace
resource "scaleway_registry_namespace" "agentops" {
  name        = "${var.environment}-agentops"
  description = "Container images for AgentOps system"
  is_public   = false
  region      = var.region
}

# Serverless Containers Namespace
resource "scaleway_container_namespace" "agentops" {
  name        = "${var.environment}-agentops"
  description = "Serverless containers for AgentOps system"
  region      = var.region
  
  # Non-sensitive environment variables
  environment_variables = {
    ENVIRONMENT = var.environment
    
    # Database Configuration
    DB_TYPE = "serverless-sql"
    DB_NAME = scaleway_sdb_sql_database.agentops.name
    
    # Messaging Configuration
    NATS_ENABLED = "true"
    NATS_ACCOUNT_ID = scaleway_mnq_nats_account.agentops.id
    
    # Redis Configuration
    REDIS_ENABLED = "true"
    REDIS_DB = "0"
    REDIS_MAX_CONNECTIONS = "50"
    
    # Model Selection Strategy
    LLM_STRATEGY = "auto-latest"
    LLM_AUTO_DISCOVERY = "true"
    LLM_CACHE_TTL = "3600"
    LLM_ZERO_KNOWLEDGE_ONLY = "true"
    
    # Provider Hierarchy
    LLM_PRIMARY_PROVIDER = "groq"
    LLM_SECONDARY_PROVIDER = "openai"
    LLM_TERTIARY_PROVIDER = "anthropic"
    
    # Model Selection Patterns
    LLM_GROQ_PATTERN = "groq/llama-3.*"
    LLM_OPENAI_PATTERN = "openai/gpt-4o.*"
    LLM_ANTHROPIC_PATTERN = "anthropic/claude-3.5-sonnet.*"
    
    # Fallback Models
    LLM_GROQ_FALLBACK = "groq/llama-3.3-70b-versatile"
    LLM_OPENAI_FALLBACK = "openai/gpt-4o-mini"
    LLM_ANTHROPIC_FALLBACK = "anthropic/claude-3.5-sonnet"
    
    # OpenRouter Configuration
    OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
    OPENROUTER_ZDR_ENDPOINT = "https://openrouter.ai/api/v1/endpoints/zdr"
    OPENROUTER_USE_ZDR_ONLY = "true"
    OPENROUTER_MODELS_REFRESH_INTERVAL = "3600"
    
    # Object Storage
    S3_BUCKET = scaleway_object_bucket.artifacts.name
    S3_ENDPOINT = scaleway_object_bucket.artifacts.endpoint
    S3_REGION = var.region
  }
  
  # Sensitive environment variables (injected from Secret Manager)
  secret_environment_variables = {
    # Database credentials
    DB_HOST     = scaleway_sdb_sql_database.agentops.endpoint
    DB_PASSWORD = var.db_password
    
    # Messaging credentials
    NATS_URL         = scaleway_mnq_nats_account.agentops.endpoint
    NATS_CREDENTIALS = scaleway_mnq_nats_credentials.agentops.file
    
    # Redis credentials
    REDIS_HOST     = tolist(scaleway_redis_cluster.agentops.private_network)[0].ips[0]
    REDIS_PORT     = tolist(scaleway_redis_cluster.agentops.private_network)[0].port
    REDIS_PASSWORD = var.redis_password
    
    # API keys
    OPENROUTER_API_KEY = var.openrouter_api_key
  }
}

# Note: Cockpit is automatically enabled for all Scaleway projects
# Access at: https://cockpit.fr-par.scw.cloud
# No explicit resource needed - it's included with your project
