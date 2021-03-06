# The legacy whitelist, should have only offices in it
data "aws_ssm_parameter" "inbound_ips" {
    name = "/NHS/dev-${data.aws_caller_identity.current.account_id}/tf/inbound_ips"
}

data "aws_ssm_parameter" "agent_ips" {
    name = "/NHS/deductions-${data.aws_caller_identity.current.account_id}/gocd-prod/agent_ips"
}

data "aws_ssm_parameter" "public_zone_id" {
    name = "/NHS/deductions-${data.aws_caller_identity.current.account_id}/root_zone_id"
}

data "aws_route53_zone" "public_zone" {
  zone_id         = data.aws_ssm_parameter.public_zone_id.value
  private_zone    = false
}

data "aws_caller_identity" "current" {}

data "aws_route_table" "public-subnet" {
  subnet_id = var.public_subnet_id
}

data "aws_subnet" "public-subnet" {
  id = var.public_subnet_id
}

data "aws_ssm_parameter" "dynamic_vpn_sg" {
  name = "/nhs/${var.environment}/vpn_sg"
}

locals {
  public_subnet_cidr = data.aws_subnet.public-subnet.cidr_block

  agent_cidrs = [
    for ip in split(",", data.aws_ssm_parameter.agent_ips.value):
      "${ip}/32"
  ]
  # This local should be the only source of truth on what IPs are allowed to connect from the Internet
  allowed_public_ips = concat(
    split(",", data.aws_ssm_parameter.inbound_ips.value),
    local.agent_cidrs)

  dynamic_vpn_sg = data.aws_ssm_parameter.dynamic_vpn_sg.value
}
