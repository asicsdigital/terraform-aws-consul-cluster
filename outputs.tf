output "datacenter" {
  value = "${data.aws_vpc.vpc.tags["Name"]}"
}

output "public_endpoint" {
  value = "${aws_alb.consul.dns_name}"
}

output "custom_public_endpoint" {
  value = "${local.custom_endpoint}"
}

output "consul_url" {
  value = "${local.consul_url}"
}
