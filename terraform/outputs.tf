output "vpc_id" {
  description = "VPC ID"
  value       = scaleway_vpc.agentops.id
}

output "private_network_id" {
  description = "Private Network ID"
  value       = scaleway_vpc_private_network.agentops.id
}

output "serverless_sql_endpoint" {
  description = "Serverless SQL database endpoint"
  value       = scaleway_sdb_sql_database.agentops.endpoint
  sensitive   = true
}

output "serverless_sql_database" {
  description = "Serverless SQL database name"
  value       = scaleway_sdb_sql_database.agentops.name
}

output "nats_endpoint" {
  description = "NATS messaging endpoint"
  value       = scaleway_mnq_nats_account.agentops.endpoint
  sensitive   = true
}

output "nats_account_id" {
  description = "NATS account ID"
  value       = scaleway_mnq_nats_account.agentops.id
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = length(scaleway_redis_cluster.agentops.private_network) > 0 ? "${tolist(scaleway_redis_cluster.agentops.private_network)[0].ips[0]}:${tolist(scaleway_redis_cluster.agentops.private_network)[0].port}" : "not_available"
  sensitive   = true
}

output "redis_cluster_id" {
  description = "Redis cluster ID"
  value       = scaleway_redis_cluster.agentops.id
}

output "s3_bucket_name" {
  description = "Object Storage bucket name"
  value       = scaleway_object_bucket.artifacts.name
}

output "s3_bucket_endpoint" {
  description = "Object Storage bucket endpoint"
  value       = scaleway_object_bucket.artifacts.endpoint
}

output "container_registry_endpoint" {
  description = "Container Registry endpoint"
  value       = scaleway_registry_namespace.agentops.endpoint
}

output "container_namespace_id" {
  description = "Serverless Containers namespace ID"
  value       = scaleway_container_namespace.agentops.id
}

output "container_namespace_endpoint" {
  description = "Serverless Containers namespace endpoint"
  value       = "https://${scaleway_container_namespace.agentops.id}.containers.fnc.fr-par.scw.cloud"
}

output "cockpit_grafana_url" {
  description = "Cockpit Grafana dashboard URL"
  value       = "https://cockpit.fr-par.scw.cloud"
}

output "secret_manager_ids" {
  description = "Secret Manager secret IDs"
  value = {
    openrouter_api_key = scaleway_secret.openrouter_api_key.id
    db_password        = scaleway_secret.db_password.id
    nats_credentials   = scaleway_secret.nats_credentials.id
  }
  sensitive = true
}
