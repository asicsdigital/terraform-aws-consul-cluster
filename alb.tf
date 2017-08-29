# Create a new load balancer

resource "aws_alb" "consul" {
  #name            = "tf-consul-${data.aws_vpc.vpc.tags["Name"]}"
  name     = "${replace(format("%.32s", replace("tf-c-${data.aws_vpc.vpc.tags["Name"]}", "_", "-")), "/\\s/", "-")}"
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
  name    = "${data.aws_vpc.vpc.tags["Name"]}.${data.aws_route53_zone.zone.name}"
  type    = "A"

  alias {
    name                   = "${aws_alb.consul.dns_name}"
    zone_id                = "${aws_alb.consul.zone_id}"
    evaluate_target_health = false
  }
}

# Create a new target group
resource "aws_alb_target_group" "consul_ui" {
  #name     = "tf-consul-ui-${data.aws_vpc.vpc.tags["Name"]}"
  name     = "${replace(format("%.32s", replace("tf-c_ui-${data.aws_vpc.vpc.tags["Name"]}", "_", "-")), "/\\s/", "-")}"
  port     = 4180
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.vpc.id}"

  health_check {
    path = "/ping"
  }

  stickiness {
    type    = "lb_cookie"
    enabled = true
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
