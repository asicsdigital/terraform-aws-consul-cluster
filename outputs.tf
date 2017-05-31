output "datacenter" {
  value = "${data.aws_vpc.vpc.tags["Name"]}"
}

output "public_endpoint" {
  value = "${aws_route53_record.consul.fqdn}"
}
