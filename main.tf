data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

data "aws_route53_zone" "zone" {
  name = "${var.dns_zone}"
}

data "aws_acm_certificate" "cert" {
  domain = "${replace(var.dns_zone, "/.$/","")}" # dirty hack to strip off trailing dot
}

data "template_file" "consul" {
  template = "${file("${path.module}/files/consul.json")}"

  vars {
    datacenter                 = "${data.aws_vpc.vpc.tags["Name"]}"
    env                        = "${var.env}"
    enable_script_checks       = "${var.enable_script_checks}"
    enable_script_checks       = "${var.enable_script_checks ? "true" : "false"}"
    image                      = "${var.consul_image}"
    join_ec2_tag_key           = "${var.join_ec2_tag_key}"
    join_ec2_tag               = "${var.join_ec2_tag}"
    awslogs_group              = "consul-${var.env}"
    awslogs_stream_prefix      = "consul-${var.env}"
    awslogs_region             = "${var.region}"
    sha_htpasswd_hash          = "${var.sha_htpasswd_hash}"
    oauth2_proxy_htpasswd_file = "${var.oauth2_proxy_htpasswd_file}"
    oauth2_proxy_provider      = "${var.oauth2_proxy_provider}"
    oauth2_proxy_github_org    = "${var.oauth2_proxy_github_org}"
    oauth2_proxy_github_team   = "${join(",", var.oauth2_proxy_github_team)}"
    oauth2_proxy_client_id     = "${var.oauth2_proxy_client_id}"
    oauth2_proxy_client_secret = "${var.oauth2_proxy_client_secret}"
    raft_multiplier            = "${var.raft_multiplier}"
    s3_backup_bucket           = "${var.s3_backup_bucket}"
  }
}

# End Data block

resource "aws_ecs_task_definition" "consul" {
  family                = "consul-${var.env}"
  container_definitions = "${data.template_file.consul.rendered}"
  network_mode          = "host"
  task_role_arn         = "${aws_iam_role.consul_task.arn}"

  volume {
    name      = "docker-sock"
    host_path = "/var/run/docker.sock"
  }
}

resource "aws_cloudwatch_log_group" "consul" {
  name = "${aws_ecs_task_definition.consul.family}"

  tags {
    VPC         = "${data.aws_vpc.vpc.tags["Name"]}"
    Application = "${aws_ecs_task_definition.consul.family}"
  }
}

resource "aws_ecs_service" "consul" {
  name            = "consul-${var.env}"
  cluster         = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.consul.arn}"
  desired_count   = "${var.cluster_size * 2}"               # This is not awesome, it lets new AS groups get added to the cluster before destruction.

  placement_constraints {
    type = "distinctInstance"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.consul_ui.arn}"
    container_name   = "consul-ui-${var.env}"
    container_port   = 4180
  }

  iam_role = "${aws_iam_role.ecsServiceRole.arn}"

  depends_on = ["aws_alb_target_group.consul_ui",
    "aws_alb_listener.consul_https",
    "aws_alb.consul",
    "aws_iam_role.ecsServiceRole",
  ]
}

# Security Groups
resource "aws_security_group" "alb-web-sg" {
  name        = "tf-${data.aws_vpc.vpc.tags["Name"]}-consul-uiSecurityGroup"
  description = "Allow Web Traffic into the ${data.aws_vpc.vpc.tags["Name"]} VPC"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "tf-${data.aws_vpc.vpc.tags["Name"]}-consul-uiSecurityGroup"
  }
}
