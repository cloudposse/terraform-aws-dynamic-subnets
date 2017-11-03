module "public_subnet_label" {
  source    = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.2.2"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "public"
}

module "public_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.2.2"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["public"]
  tags       = "${var.tags}"
}

resource "aws_subnet" "public" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block        = "${cidrsubnet(signum(length(var.cidr_block)) == 1 ? var.cidr_block : data.aws_vpc.default.cidr_block, ceil(log(length(data.aws_availability_zones.available.names) * 2, 2)), length(data.aws_availability_zones.available.names) + count.index)}"

  tags = {
    "Name"      = "${module.public_subnet_label.id}${var.delimiter}${replace(element(var.availability_zones, count.index),"-",var.delimiter)}"
    "Stage"     = "${module.public_subnet_label.stage}"
    "Namespace" = "${module.public_subnet_label.namespace}"
  }
}

resource "aws_route_table" "public" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${data.aws_vpc.default.id}"

  tags = "${module.public_label.tags}"
}

resource "aws_route" "default_public" {
  count                  = "${length(var.availability_zones)}"
  route_table_id         = "${element(aws_route_table.public.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${var.igw_id}"
}

resource "aws_route" "additional_public" {
  count                  = "${length(var.availability_zones) * length(var.additional_routes_public)}"
  route_table_id         = "${element(aws_route_table.public.*.id, count.index  % length(var.availability_zones))}"
  destination_cidr_block = "${lookup(var.additional_routes_public[count.index  / length(var.availability_zones)], "cidr_block")}"
  gateway_id             = "${lookup(var.additional_routes_public[count.index / length(var.availability_zones)], "gateway_id")}"
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
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
