## DataSource
data "aws_availability_zones" "current" {
  state = "available"
}

## Calculate CIDR
module "subnet_addrs_private" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  for_each = var.vpc

  base_cidr_block = cidrsubnet(lookup(each.value, "cidr", "172.30.0.0/16"), 1, 0)
  networks = [
    for s in try(each.value.azs, data.aws_availability_zones.current.names) : {
      name     = s
      new_bits = lookup(each.value, "mask_to_subnet", 7)
  }]
}

module "subnet_addrs_public" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  for_each = var.vpc

  base_cidr_block = cidrsubnet(lookup(each.value, "cidr", "172.30.0.0/16"), 1, 1)
  networks = [
    for s in try(each.value.azs, data.aws_availability_zones.current.names) : {
      name     = s
      new_bits = lookup(each.value, "mask_to_subnet", 7)
  }]
}

# module "subnet_addrs_intra" {
#   source  = "hashicorp/subnets/cidr"
#   version = "1.0.0"

#   for_each = var.vpc

#   base_cidr_block = cidrsubnet(lookup(each.value, "cidr", "172.30.0.0/16"), 1, 2)
#   networks = [
#     for s in try(each.value.azs, data.aws_availability_zones.current.names) : {
#       name     = s
#       new_bits = 7
#   }]
# }

## VPC
module "vpc" {
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"

  for_each = var.vpc

  name = "${var.prefix_name}-${each.value.name}-${var.env}-${var.region}"
  cidr = lookup(each.value, "cidr", "172.20.0.0/16")

  azs             = data.aws_availability_zones.current.names
  private_subnets = try(each.value.private_subnets, module.subnet_addrs_private[each.key].networks[*].cidr_block)
  public_subnets  = try(each.value.public_subnets, module.subnet_addrs_public[each.key].networks[*].cidr_block)
  # intra_subnets  = try(each.value.intra_subnets, module.subnet_addrs_intra[each.key].networks[*].cidr_block)

  enable_nat_gateway = lookup(each.value, "enable_nat_gateway", true)
  single_nat_gateway = lookup(each.value, "single_nat_gateway", true)

  enable_dns_hostnames = lookup(each.value, "enable_dns_hostnames", true)
  enable_dns_support   = lookup(each.value, "enable_dns_support", true)

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = lookup(each.value, "enable_flow_log", false)
  create_flow_log_cloudwatch_log_group = lookup(each.value, "enable_flow_log", false)
  create_flow_log_cloudwatch_iam_role  = lookup(each.value, "enable_flow_log", false)
  flow_log_max_aggregation_interval    = 60

  public_subnet_tags = lookup(each.value, "public_subnet_tags", {})

  private_subnet_tags = lookup(each.value, "private_subnet_tags", {})

  depends_on = [
    module.subnet_addrs_private,
    module.subnet_addrs_public
  ]
}

resource "aws_route_table" "private" {

  vpc_id = module.vpc[each.key].vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = module.vpc[each.key].nat_gateway_ids[0]
}

}

resource "aws_route_table_association" "private" {
    subnet_id = module.vpc[each.key].private_subnets[0]
    route_table_id = aws_route_table.private.id
}
