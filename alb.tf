# Create a new load balancer

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
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${coalesce(var.hostname, data.aws_vpc.vpc.tags["Name"])}.${data.aws_route53_zone.zone.name}"
  type    = "A"

  alias {
    name                   = "${aws_alb.consul.dns_name}"
    zone_id                = "${aws_alb.consul.zone_id}"
    evaluate_target_health = false
  }
}

# Create a new target group
resource "aws_alb_target_group" "consul_ui" {
  port     = 4180
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.vpc.id}"

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
  load_balancer_arn = "${aws_alb.consul.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${data.aws_acm_certificate.cert.arn}" # edit needed

  default_action {
    target_group_arn = "${aws_alb_target_group.consul_ui.arn}"
    type             = "forward"
  }
}
