module "private_label" {
  source    = "git::https://github.com/cloudposse/tf_label.git?ref=tags/0.1.0"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.name}-private"
}

resource "aws_subnet" "private" {
  count = "${length(var.availability_zones)}"

  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block        = "${cidrsubnet(data.aws_vpc.default.cidr_block, length(var.availability_zones), length(var.availability_zones)  + count.index)}"
  tags              = "${module.private_label.tags}"
}

resource "aws_route_table" "private" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${data.aws_vpc.default.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.default.*.id, count.index)}"
  }

  tags = "${module.private_label.tags}"
}

resource "aws_route_table_association" "private" {
  count = "${length(var.availability_zones)}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
