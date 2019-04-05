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

This module supports two modes. If you pass a single ECS cluster ID into the `ecs_cluster_ids` the module deploys a single service and deploys to it called "consul-$env". If you pass two ID's into the array, two services will be created, consul-$env-primary and consul-$env-secondary. This allows you to spread consul across two separate ECS clusters, and two separate autoscaling groups, allowing you to redeploy ECS instances without effecting the stability of the Consul cluster.   


----------------------
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


Authors
=======

[Tim Hartmann](https://github.com/tfhartmann)
[Steve Huff](https://github.com/hakamadare)

License
=======


[MIT License](LICENSE)
----
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alb\_log\_bucket | s3 bucket to send ALB Logs | string | n/a | yes |
| alb\_log\_prefix | Prefix for S3 bucket. (default is log/elb). | string | `"logs/elb"` | no |
| cloudwatch\_log\_retention | Specifies the number of days you want to retain log events in the specified log group. (defaults to 30) | string | `"30"` | no |
| cluster\_size | Consul cluster size. This must be greater than 3 | string | `"3"` | no |
| consul\_image | Image to use when deploying consul, defaults to the hashicorp consul image | string | `"fitnesskeeper/consul:latest"` | no |
| consul\_memory\_reservation | The soft limit (in MiB) of memory to reserve for the container, defaults 32 | string | `"32"` | no |
| datacenter\_name | Optional overide for datacenter name | string | `""` | no |
| definitions | List of Consul Service and Health Check Definitions | list | `<list>` | no |
| dns\_zone | Zone where the Consul UI alb will be created. This should *not* be consul.example.com.  Uses the default AWS domain name if not set. | string | `""` | no |
| ecs\_cluster\_ids | List of ARNs of the ECS Cluster IDs | list | n/a | yes |
| enable\_script\_checks | This controls whether health checks that execute scripts are enabled on this agent, and defaults to false | string | `"false"` | no |
| env |  | string | n/a | yes |
| hostname | DNS Hostname for the bastion host. Defaults to ${VPC NAME}.${dns_zone} if hostname is not set | string | `""` | no |
| iam\_path | IAM path, this is useful when creating resources with the same name across multiple regions. Defaults to / | string | `"/"` | no |
| join\_ec2\_tag | EC2 Tags which consul will search for in order to generate a list of IP's to join. See https://github.com/hashicorp/consul-ec2-auto-join-example for more examples. | string | n/a | yes |
| join\_ec2\_tag\_key | EC2 Tag Key which consul uses to search to generate a list of IP's to Join. Defaults to Name | string | `"Name"` | no |
| oauth2\_proxy\_client\_id | the OAuth Client ID: ie: 123456.apps.googleusercontent.com | string | n/a | yes |
| oauth2\_proxy\_client\_secret | the OAuth Client Secret | string | n/a | yes |
| oauth2\_proxy\_github\_org | Github Org | string | n/a | yes |
| oauth2\_proxy\_github\_team | list of teams that should have access defaults to empty list (allow all) | list | `<list>` | no |
| oauth2\_proxy\_htpasswd\_file | Path the htpasswd file | string | `"/conf/htpasswd"` | no |
| oauth2\_proxy\_provider | OAuth provider | string | `"github"` | no |
| prometheus\_retention\_time | Timing for Prometheus metrics, more info can be found here : https://www.consul.io/docs/agent/options.html#telemetry-prometheus_retention_time | string | `"0s"` | no |
| raft\_multiplier | An integer multiplier used by Consul servers to scale key Raft timing parameters https://www.consul.io/docs/guides/performance.html | string | `"5"` | no |
| region | AWS Region, defaults to us-east-1 | string | `"us-east-1"` | no |
| registrator\_image | Image to use when deploying registrator agent, defaults to the gliderlabs registrator:latest image | string | `"gliderlabs/registrator:latest"` | no |
| registrator\_memory\_reservation | The soft limit (in MiB) of memory to reserve for the container, defaults 32 | string | `"32"` | no |
| s3\_backup\_bucket | S3 Bucket to use to store backups of consul snapshots | string | n/a | yes |
| service\_minimum\_healthy\_percent | The minimum healthy percent represents a lower limit on the number of your service's tasks that must remain in the RUNNING state during a deployment (default 66) | string | `"66"` | no |
| sha\_htpasswd\_hash | Entries must be created with htpasswd -s for SHA encryption | string | n/a | yes |
| sidecar\_image | Image to use when deploying health check agent, defaults to fitnesskeeper/consul-sidecar:latest image | string | `"fitnesskeeper/consul-sidecar"` | no |
| sidecar\_memory\_reservation | The soft limit (in MiB) of memory to reserve for the container, defaults 32 | string | `"32"` | no |
| subnets | List of subnets used to deploy the Consul alb | list | n/a | yes |
| vpc\_id |  | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| consul\_url |  |
| custom\_public\_endpoint |  |
| datacenter |  |
| public\_endpoint |  |

