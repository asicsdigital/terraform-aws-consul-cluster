Consul Cluster terraform module
===========

A terraform module providing an opinionated Consul cluster built on an ECS cluster in AWS.

This module is designed to be used in conjunction with the [Runkeeper ECS Module](https://github.com/FitnessKeeper/terraform-ecs)

This module supports consul 0.9.1 or later.

This module

- creates an alb using the VPC name at the top of the zone ex. rk-dev-infra.examples.com
- searches for a aws_acm_certificate for example.com, if one doesn't exist it should be created outside of this module
- deploys consul containers on top of an existing ECS cluster
- Deploys registrator
- deploys oauth2_proxy containers to proxy oauth requests through to the consul ui


----------------------
#### Required
- `alb_log_bucket` - s3 bucket to send ALB Logs
- `dns_zone` - Zone where the Consul UI alb will be created. This should *not* be consul.tld.com
- `ecs_cluster_id` - ARN of the ECS ID
- `env` - env to deploy into, should typically dev/staging/prod
- `join_ec2_tag` - EC2 Tags which consul will search for in order to generate a list of IP's to join. See https://github.com/hashicorp/consul-ec2-auto-join-example for more examples.
- `subnets` - List of subnets used to deploy the Consul alb
- `vpc_id`  - VPC ID
- `sha_htpasswd_hash` - Entries must be created with htpasswd -s for SHA encryption
- `oauth2_proxy_github_org` - Github Org
- `oauth2_proxy_client_id` - the OAuth Client ID: ie: 123456.apps.googleusercontent.com
- `oauth2_proxy_client_secret` - the OAuth Client Secret
- `s3_backup_bucket` - S3 Bucket to use to store backups of consul snapshots - defaults to backup-bucket

#### Optional

- `cluster_size`  - Consul cluster size. This must be greater the 3, defaults to 3
- `datacenter_name` - Optional overide for datacenter nam
- `enable_script_checks` - description = This controls whether health checks that execute scripts are enabled on this agent, and defaults to false
- `oauth2_proxy_htpasswd_file` - Path the htpasswd file defaults to /conf/htpasswd
- `join_ec2_tag_key` - EC2 Tag Key which consul uses to search to generate a list of IP's to Join. Defaults to Name
- `raft_multiplier" - An integer multiplier used by Consul servers to scale key Raft timing parameters https://www.consul.io/docs/guides/performance.html defaults to 5
- `region` - AWS Region - defaults to us-east-1
- `oauth2_proxy_provider` - OAuth provider defaults to github
- `oauth2_proxy_github_team` - list of teams that should have access defaults to empty list (allow all)

Usage
-----

```hcl
module "consul-cluster" {
  source                     = "./terraform-consul-cluster"
  alb_log_bucket             = "some-bucket-name"             # "some-bucket-name"
  cluster_size               = 3                              # Must be 3 or more
  dns_zone                   = "example.com"                  # "example.com."
  ecs_cluster_id             = "${module.ecs.cluster_id}"
  env                        = "dev"                          # dev/staging/prod
  join_ec2_tag               = "dev-infra ECS Node"           # "dev-infra ECS Node"
  subnets                    = ["10.0.0.0/24", "10.0.1.0/24"] # List of networks
  vpc_id                     = "vpc-e1234567"                 # "vpc-e1234567"
  sha_htpasswd_hash          = "consul:{SHA}zblahblah="       # "consul:{SHA}z...="
  oauth2_proxy_htpasswd_file = "/conf/htpasswd"               # "path to httpsswd file"
  oauth2_proxy_provider      = "github"                       # This module is designed to use github
  oauth2_proxy_github_org    = "FitnessKeeper"                # Github Org
  oauth2_proxy_github_team   = "devops"
  oauth2_proxy_client_id     = "0d440bd55527cfe3149e"
  oauth2_proxy_client_secret = "04b17e65fb10g96ff88fa2a4edad48528777e75b"
}

```

Outputs
=======


Authors
=======

[Tim Hartmann](https://github.com/tfhartmann)
[Steve Huff](https://github.com/hakamadare)

License
=======


[MIT License](LICENSE)
