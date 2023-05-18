
# AWS NAT Instances are being phased out, and do not support IPv6 traffic,
# such as NAT64, so this module does not support IPv6 traffic to NAT instances.
# NAT Gateways are recommended instead.

module "nat_instance_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["nat", "instance"]

  context = module.this.context
}

## Note: May 2022, although Cloud Posse is generally converting its modules
## to use its `security-group` module rather than provision security group
## resources directly, that is a breaking change, and given that this
## security group is minimal, we will defer making that breaking change
## to preserve compatibility while we add IPv6 functionality.
resource "aws_security_group" "nat_instance" {
  count = local.nat_instance_enabled ? 1 : 0

  name        = module.nat_instance_label.id
  description = "Security Group for NAT Instance"
  vpc_id      = local.vpc_id
  tags        = module.nat_instance_label.tags
}

resource "aws_security_group_rule" "nat_instance_egress" {
  count = local.nat_instance_enabled ? 1 : 0

  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
  security_group_id = join("", aws_security_group.nat_instance[*].id)
  type              = "egress"
}

resource "aws_security_group_rule" "nat_instance_ingress" {
  count = local.nat_instance_enabled ? 1 : 0

  description       = "Allow ingress traffic from the VPC CIDR block"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [local.base_ipv4_cidr_block]
  security_group_id = join("", aws_security_group.nat_instance[*].id)
  type              = "ingress"
}

# aws --region us-west-2 ec2 describe-images --owners amazon --filters Name="name",Values="amzn-ami-vpc-nat*" Name="virtualization-type",Values="hvm"
data "aws_ami" "nat_instance" {
  count = local.need_nat_ami_id ? 1 : 0

  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-comparison.html
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html
# https://dzone.com/articles/nat-instance-vs-nat-gateway
resource "aws_instance" "nat_instance" {
  count = local.nat_instance_enabled ? local.nat_count : 0

  ami                    = local.nat_instance_ami_id
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.nat_instance[0].id]

  tags = merge(
    module.nat_instance_label.tags,
    {
      "Name" = format("%s%s%s", module.nat_instance_label.id, local.delimiter, local.subnet_az_abbreviations[count.index])
    }
  )

  # Required by NAT
  # https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html#EIP_Disable_SrcDestCheck
  source_dest_check = false

  #bridgecrew:skip=BC_AWS_PUBLIC_12: Skipping `EC2 Should Not Have Public IPs` check. NAT instance requires public IP.
  #bridgecrew:skip=BC_AWS_GENERAL_31: Skipping `Ensure Instance Metadata Service Version 1 is not enabled` check until BridgeCrew support condition evaluation. See https://github.com/bridgecrewio/checkov/issues/793
  #bridgecrew:skip=BC_AWS_LOGGING_26: Skipping requirement for detailed monitoring of NAT instance.
  associate_public_ip_address = true #tfsec:ignore:AWS012

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint_enabled ? "enabled" : "disabled"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = var.metadata_http_tokens_required ? "required" : "optional"
  }

  root_block_device {
    encrypted = local.nat_instance_root_block_device_encrypted
  }

  dynamic "credit_specification" {
    for_each = var.nat_instance_cpu_credits_override == "" ? [] : [var.nat_instance_cpu_credits_override]

    content {
      cpu_credits = var.nat_instance_cpu_credits_override
    }
  }

  ebs_optimized = true
}

resource "aws_eip_association" "nat_instance" {
  count = local.nat_instance_enabled ? local.nat_count : 0

  instance_id   = aws_instance.nat_instance[count.index].id
  allocation_id = local.nat_eip_allocations[count.index]
}

# If private IPv4 subnets and NAT Instance are both enabled, create a
# default route from private subnet to NAT Instance in each subnet
resource "aws_route" "nat_instance" {
  count = local.nat_instance_enabled ? local.private_route_table_count : 0

  route_table_id         = local.private_route_table_ids[count.index]
  network_interface_id   = element(aws_instance.nat_instance[*].primary_network_interface_id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_route_table.private]

  timeouts {
    create = local.route_create_timeout
    delete = local.route_delete_timeout
  }
}
