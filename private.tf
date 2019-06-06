module "private_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = "${compact(concat(var.attributes,list("private")))}"
  tags       = "${merge(var.tags, map(var.subnet_type_tag_key, format(var.subnet_type_tag_value_format,"private")))}"
}

module "private_subnet_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  attributes = "${compact(concat(var.attributes,list("private")))}"
  tags       = "${merge(var.tags, map(var.subnet_type_tag_key, format(var.subnet_type_tag_value_format,"private")))}"
}

locals {
  private_subnet_count = "${var.max_subnet_count == 0 ? length(data.aws_availability_zones.available.names) : var.max_subnet_count}"
}

resource "aws_subnet" "private" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block        = "${cidrsubnet(signum(length(var.cidr_block)) == 1 ? var.cidr_block : data.aws_vpc.default.cidr_block, ceil(log(local.private_subnet_count * 2, 2)), count.index)}"

  tags = "${merge(module.private_subnet_label.tags, map("Name",format("%s%s%s", module.private_subnet_label.id, var.delimiter, replace(element(var.availability_zones, count.index),"-",var.delimiter))))}"

  lifecycle {
    # Ignore tags added by kops or kubernetes
    ignore_changes = ["tags.%", "tags.kubernetes", "tags.SubnetType"]
  }
}

resource "aws_route_table" "private" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${data.aws_vpc.default.id}"

  tags = "${merge(module.private_subnet_label.tags, map("Name",format("%s%s%s", module.private_subnet_label.id, var.delimiter, replace(element(var.availability_zones, count.index),"-",var.delimiter))))}"
}

resource "aws_route_table_association" "private" {
  count = "${length(var.availability_zones)}"

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
