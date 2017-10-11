module "public_subnet_label" {
  source    = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.2.1"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "public"
}

module "public_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.2.1"
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
  count  = "${signum(length(var.vpc_default_route_table_id)) == 1 ? 0 : 1}"
  vpc_id = "${data.aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.igw_id}"
  }

  lifecycle {
    ignore_changes = ["route"]
  }

  tags = "${module.public_label.tags}"
}

resource "aws_route" "public" {
  count                  = "${length(compact(values(var.additional_public_routes)))}"
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "${length(compact(values(var.additional_public_routes))) > 0 ? lookup(var.additional_public_routes, replace(element(concat(list("workaround"), keys(var.additional_public_routes)), count.index), "workaround", ""), "0.0.0.0/0") : ""}"
  gateway_id             = "${length(compact(values(var.additional_public_routes))) > 0 ? replace(element(concat(list("workaround"), keys(var.additional_public_routes)), count.index), "workaround", "") : ""}"
}

resource "aws_route_table_association" "public" {
  count          = "${signum(length(var.vpc_default_route_table_id)) == 1 ? 0 : length(var.availability_zones)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_default" {
  count          = "${signum(length(var.vpc_default_route_table_id)) == 1 ? length(var.availability_zones) : 0}"
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
