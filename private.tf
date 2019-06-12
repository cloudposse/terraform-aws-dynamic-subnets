locals {
  private_subnets_map = {
    "-1" = "${length(local.availability_zones)}"
    "0"  = "0"
    "1"  = "${var.private_subnet_count}"
  }

  ## Keep the subnets within the max_subnets_count limit
  private_subnet_count = "${min(local.private_subnets_map[signum(var.private_subnet_count)], local.max_subnet_count)}"
}

module "private_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.11.1"
  context    = "${module.label.context}"
  attributes = "${compact(concat(module.label.attributes,list("private")))}"
  tags       = "${merge(module.label.tags, map(var.subnet_type_tag_key, format(var.subnet_type_tag_value_format,"private")))}"
}

resource "aws_subnet" "private" {
  count             = "${local.private_subnet_count}"
  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${local.availability_zones_private[count.index % length(local.availability_zones_private)]}"
  cidr_block        = "${cidrsubnet(signum(length(var.cidr_block)) == 1 ? var.cidr_block : data.aws_vpc.default.cidr_block, ceil(log(local.private_subnet_count * 2, 2)), count.index)}"

  tags = "${merge(module.private_label.tags, map("Name",format("%s%s%s", module.private_label.id, var.delimiter, replace(local.availability_zones_private[count.index % length(local.availability_zones_private)],"-",var.delimiter))))}"

  lifecycle {
    # Ignore tags added by kops or kubernetes
    ignore_changes = ["tags.%", "tags.kubernetes", "tags.SubnetType"]
  }
}

resource "aws_route_table" "private" {
  count  = "${local.private_subnet_count}"
  vpc_id = "${data.aws_vpc.default.id}"

  tags = "${merge(module.private_label.tags, map("Name",format("%s%s%s", module.private_label.id, var.delimiter, replace(local.availability_zones_private[count.index % length(local.availability_zones_private)],"-",var.delimiter))))}"
}

resource "aws_route_table_association" "private" {
  count = "${local.private_subnet_count}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_network_acl" "private" {
  count      = "${signum(length(var.private_network_acl_id)) == 0 ? 1 : 0}"
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  tags = "${module.private_label.tags}"
}
