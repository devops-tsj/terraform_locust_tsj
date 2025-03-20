
module "keypair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  for_each = var.keypair

  key_name           = "${var.prefix_name}-${each.value.name}-${var.region}"
  create_private_key = true
  tags = {
    Environment = var.env

  }
}

resource "aws_secretsmanager_secret" "my_secret" {
  for_each = var.keypair

  name = "${var.prefix_name}-${each.value.name}-${var.region}-new"
}

resource "aws_secretsmanager_secret_version" "my_secret_version" {
  for_each = var.keypair

  secret_id     = aws_secretsmanager_secret.my_secret[each.key].id
  secret_string = module.keypair[each.key].private_key_pem
}