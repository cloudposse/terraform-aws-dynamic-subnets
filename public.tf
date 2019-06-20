locals {
  public_subnets_map = {
    "-1" = "${length(local.availability_zones)}"
    "0"  = "0"
    "1"  = "${var.public_subnet_count}"
  }

  ## Keep the subnets within the max_subnets_count limit
  public_subnet_count = "${min(local.public_subnets_map[signum(var.public_subnet_count)], local.max_subnet_count)}"
}

module "public_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.11.1"
  context    = "${module.label.context}"
  attributes = "${compact(concat(module.label.attributes, list("public")))}"
  tags       = "${merge(module.label.tags, map(var.subnet_type_tag_key, format(var.subnet_type_tag_value_format, "public")))}"
}

locals {
  map_public_ip_on_launch = "${var.map_public_ip_on_launch == "true" ? true : false}"
}

resource "aws_subnet" "public" {
  count                   = "${local.public_subnet_count}"
  vpc_id                  = "${data.aws_vpc.default.id}"
  availability_zone       = "${local.availability_zones_public[count.index % length(local.availability_zones_public)]}"
  cidr_block              = "${cidrsubnet(signum(length(var.cidr_block)) == 1 ? var.cidr_block : data.aws_vpc.default.cidr_block, ceil(log(local.public_subnet_count * 2, 2)), local.public_subnet_count + count.index)}"
  map_public_ip_on_launch = "${local.map_public_ip_on_launch}"
  tags                    = "${merge(module.public_label.tags, map("Name", format("%s%s%s", module.public_label.id, module.public_label.delimiter, replace(element(var.availability_zones, count.index), "-", module.public_label.delimiter))))}"

  lifecycle {
    # Ignore tags added by kops or kubernetes
    ignore_changes = ["tags.%", "tags.kubernetes", "tags.SubnetType"]
  }
}

resource "aws_route_table" "public" {
  count  = "${signum(length(var.vpc_default_route_table_id)) == 1 ? 0 : 1}"
  vpc_id = "${data.aws_vpc.default.id}"

  tags = "${module.public_label.tags}"
}

resource "aws_route" "public" {
  count                  = "${signum(length(var.vpc_default_route_table_id)) == 1 ? 0 : 1}"
  route_table_id         = "${join("", aws_route_table.public.*.id)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${var.igw_id}"
}

resource "aws_route_table_association" "public" {
  count          = "${signum(length(var.vpc_default_route_table_id)) == 1 ? 0 : local.public_subnet_count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_default" {
  count          = "${signum(length(var.vpc_default_route_table_id)) == 1 ? local.public_subnet_count : 0}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${var.vpc_default_route_table_id}"
}

resource "aws_network_acl" "public" {
  count      = "${signum(length(var.public_network_acl_id)) == 0 ? 1 : 0}"
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${aws_subnet.public.*.id}"]

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

  tags = "${module.public_label.tags}"
}
