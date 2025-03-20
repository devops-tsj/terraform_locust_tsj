# Security Group
module "security_group_instance" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  for_each = var.instance

  name        = "${var.prefix_name}-${each.value.name}-sg"
  description = "Access to instance"
  vpc_id      = module.vpc[each.value.vpc_key].vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = module.vpc[each.value.vpc_key].vpc_cidr_block
    },
  ]

  egress_rules = ["all-all"]
}

# EC2
module "instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = var.instance

  name = each.value.name

  ami                    = each.value.ami
  iam_instance_profile   = aws_iam_instance_profile.instance[each.key].id
  instance_type          = each.value.instance_type
  subnet_id              = lookup(each.value, "subnet_id", element(module.vpc[each.value.vpc_key].public_subnets, 0))
  vpc_security_group_ids = [module.security_group_instance[each.key].security_group_id]
  key_name               = module.keypair[each.value.keypair_key].key_pair_name

  private_ip = lookup(each.value, "ip_address", null)


  root_block_device = [
    {
      volume_type = "${each.value.root_device_volume_type}"
      volume_size = "${each.value.root_device_volume_size}"
      encrypted   = "${each.value.root_device_volume_encrypted}"
    },
  ]
}

resource "aws_eip" "instance" {
   instance = module.instance[each.key].id
   for_each = var.instance
   domain   = "vpc"
   tags = {
     "Name" = "${var.prefix_name}-${each.value.name}-${var.env}"
   }
 }

# resource "aws_s3_bucket" "instance" {
#   for_each = var.instance
#   bucket   = "${var.prefix_name}-${each.value.name}-${var.env}"
# }

data "aws_iam_policy_document" "instance" {
  for_each = var.instance
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  for_each           = var.instance
  name               = "EC2-${var.prefix_name}-${each.value.name}-${var.region}"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance[each.key].json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  for_each   = var.instance
  role       = aws_iam_role.instance[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  for_each = var.instance
  name     = aws_iam_role.instance[each.key].name
  role     = aws_iam_role.instance[each.key].name
}
