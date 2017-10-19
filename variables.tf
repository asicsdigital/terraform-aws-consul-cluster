variable "alb_log_bucket" {
  description = "s3 bucket to send ALB Logs"
}

variable "cluster_size" {
  default     = "3"
  description = "Consul cluster size. This must be greater the 3"
}

variable "consul_image" {
  description = "Image to use when deploying consul, defaults to the hashicorp consul image"
  default     = "fitnesskeeper/consul:latest"
}

variable "datacenter_name" {
  description = "Optional overide for datacenter name"
  default     = ""
}

variable "dns_zone" {
  description = "Zone where the Consul UI alb will be created. This should *not* be consul.example.com"
}

variable "ecs_cluster_ids" {
  type        = "list"
  description = "List of ARNs of the ECS Cluster IDs"
}

variable "env" {}

variable "enable_script_checks" {
  description = "This controls whether health checks that execute scripts are enabled on this agent, and defaults to false"
  default     = false
}

variable "hostname" {
  description = "DNS Hostname for the bastion host. Defaults to ${VPC NAME}.${dns_zone} if hostname is not set"
  default     = ""
}

variable "join_ec2_tag_key" {
  description = "EC2 Tag Key which consul uses to search to generate a list of IP's to Join. Defaults to Name"
  default     = "Name"
}

variable "join_ec2_tag" {
  description = "EC2 Tags which consul will search for in order to generate a list of IP's to join. See https://github.com/hashicorp/consul-ec2-auto-join-example for more examples."
}

variable "iam_path" {
  default     = "/"
  description = "IAM path, this is useful when creating resources with the same name across multiple regions. Defaults to /"
}

variable "s3_backup_bucket" {
  description = "S3 Bucket to use to store backups of consul snapshots"
}

variable "subnets" {
  type        = "list"
  description = "List of subnets used to deploy the Consul alb"
}

variable "region" {
  default     = "us-east-1"
  description = "AWS Region, defaults to us-east-1"
}

variable "raft_multiplier" {
  description = "An integer multiplier used by Consul servers to scale key Raft timing parameters https://www.consul.io/docs/guides/performance.html"
  default     = "5"
}

variable "vpc_id" {}

variable "sha_htpasswd_hash" {
  description = "Entries must be created with htpasswd -s for SHA encryption"
}

variable "oauth2_proxy_htpasswd_file" {
  description = "Path the htpasswd file"
  default     = "/conf/htpasswd"
}

variable "oauth2_proxy_provider" {
  description = "OAuth provider"
  default     = "github"
}

variable "oauth2_proxy_github_org" {
  description = "Github Org"
}

variable "oauth2_proxy_github_team" {
  description = "list of teams that should have access defaults to empty list (allow all)"
  type        = "list"
  default     = []
}

variable "oauth2_proxy_client_id" {
  description = "the OAuth Client ID: ie: 123456.apps.googleusercontent.com"
}

variable "oauth2_proxy_client_secret" {
  description = "the OAuth Client Secret"
}
