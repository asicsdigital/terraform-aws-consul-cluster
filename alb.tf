# Create a new load balancer

locals {
  enable_custom_domain = "${var.dns_zone == "" ? false : true}"
  custom_endpoint      = "${coalesce(var.hostname, data.aws_vpc.vpc.tags["Name"])}.${var.dns_zone}"
  consul_url_protocol  = "${local.enable_custom_domain ? "https" : "http"}"
  consul_url_hostname  = "${local.enable_custom_domain ? local.custom_endpoint : aws_alb.consul.dns_name}"
  consul_url           = "${local.consul_url_protocol}://${local.consul_url_hostname}"
}

resource "aws_alb" "consul" {
  name_prefix     = "consul"
  security_groups = ["${aws_security_group.alb-web-sg.id}"]
  internal        = false
  subnets         = ["${var.subnets}"]

  tags {
    Environment = "${var.env}"
    VPC         = "${data.aws_vpc.vpc.tags["Name"]}"
  }

  access_logs {
    bucket = "${var.alb_log_bucket}"
    prefix = "logs/elb/${data.aws_vpc.vpc.tags["Name"]}/consul"
  }
}

# DNS Alias for the LB
resource "aws_route53_record" "consul" {
  count   = "${local.enable_custom_domain ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${local.custom_endpoint}"
  type    = "A"

  alias {
    name                   = "${aws_alb.consul.dns_name}"
    zone_id                = "${aws_alb.consul.zone_id}"
    evaluate_target_health = false
  }
}

# Create a new target group
resource "aws_alb_target_group" "consul_ui" {
  port                 = 4180
  protocol             = "HTTP"
  vpc_id               = "${data.aws_vpc.vpc.id}"
  deregistration_delay = "${var.alb_deregistration_delay}"

  health_check {
    path    = "/ping"
    matcher = "200"
  }

  stickiness {
    type    = "lb_cookie"
    enabled = true
  }

  tags {
    Environment = "${var.env}"
    VPC         = "${data.aws_vpc.vpc.tags["Name"]}"
  }
}

# Create a new alb listener
resource "aws_alb_listener" "consul_https" {
  count             = "${local.enable_custom_domain ? 1 : 0}"
  load_balancer_arn = "${aws_alb.consul.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.cert.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.consul_ui.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "consul_http" {
  count             = "${local.enable_custom_domain ? 0 : 1}"
  load_balancer_arn = "${aws_alb.consul.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.consul_ui.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_certificate" "consul_https" {
  count           = "${local.enable_custom_domain ? 1 : 0}"
  listener_arn    = "${aws_alb_listener.consul_https.arn}"
  certificate_arn = "${data.aws_acm_certificate.cert.arn}"
}
