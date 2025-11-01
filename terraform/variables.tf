variable "project_id" {
  description = "Scaleway project ID"
  type        = string
  default     = "077c9bc7-a333-4912-ae07-cd6d997485a0"
}

variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "zone" {
  description = "Scaleway availability zone"
  type        = string
  default     = "fr-par-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "fresh"
}

variable "db_password" {
  description = "Serverless SQL database password"
  type        = string
  sensitive   = true
}

variable "openrouter_api_key" {
  description = "OpenRouter API key for unified LLM access (Groq, OpenAI, Anthropic)"
  type        = string
  sensitive   = true
  default     = "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"
}

variable "redis_password" {
  description = "Redis database password"
  type        = string
  sensitive   = true
  default     = "AgentOps2025!RedisCache"
}
