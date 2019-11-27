module "nat_instance_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.11.1"
  context    = "${module.label.context}"
  attributes = "${distinct(compact(concat(module.label.attributes, list("nat", "instance"))))}"
}

locals {
  nat_instance_enabled = "${var.nat_instance_enabled == "true" ? true : false}"
  nat_instance_count   = "${local.nat_instance_enabled ? length(var.availability_zones) : 0}"
  cidr_block           = "${var.cidr_block != "" ? var.cidr_block : data.aws_vpc.default.cidr_block}"
}

resource "aws_security_group" "nat_instance" {
  count       = "${local.nat_instance_enabled ? 1 : 0}"
  name        = "${module.nat_instance_label.id}"
  description = "Security Group for NAT Instance"
  vpc_id      = "${var.vpc_id}"
  tags        = "${module.nat_instance_label.tags}"
}

resource "aws_security_group_rule" "nat_instance_egress" {
  count             = "${local.nat_instance_enabled ? 1 : 0}"
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${join("", aws_security_group.nat_instance.*.id)}"
  type              = "egress"
}

resource "aws_security_group_rule" "nat_instance_ingress" {
  count             = "${local.nat_instance_enabled ? 1 : 0}"
  description       = "Allow ingress traffic from the VPC CIDR block"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${local.cidr_block}"]
  security_group_id = "${join("", aws_security_group.nat_instance.*.id)}"
  type              = "ingress"
}

// aws --region us-west-2 ec2 describe-images --owners amazon --filters Name="name",Values="amzn-ami-vpc-nat*" Name="virtualization-type",Values="hvm"
data "aws_ami" "nat_instance" {
  count       = "${local.nat_instance_enabled ? 1 : 0}"
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

// https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-comparison.html
// https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html
// https://dzone.com/articles/nat-instance-vs-nat-gateway
resource "aws_instance" "nat_instance" {
  count                  = "${local.nat_instance_count}"
  ami                    = "${join("", data.aws_ami.nat_instance.*.id)}"
  instance_type          = "${var.nat_instance_type}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.nat_instance.id}"]
  tags                   = "${merge(module.nat_instance_label.tags, map("Name", format("%s%s%s", module.nat_label.id, var.delimiter, replace(element(var.availability_zones, count.index), "-", var.delimiter))))}"

  # Required by NAT
  # https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html#EIP_Disable_SrcDestCheck
  source_dest_check = false

  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "nat_instance" {
  count         = "${local.nat_instance_count}"
  instance_id   = "${element(aws_instance.nat_instance.*.id, count.index)}"
  allocation_id = "${element(aws_eip.default.*.id, count.index)}"
}

resource "aws_route" "nat_instance" {
  count                  = "${local.nat_instance_count}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  instance_id            = "${element(aws_instance.nat_instance.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = ["aws_route_table.private"]
}
