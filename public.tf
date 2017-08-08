resource "aws_subnet" "public" {
  count = "${length(var.availability_zones)}"

  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block        = "${cidrsubnet(data.aws_vpc.default.cidr_block, length(var.availability_zones), count.index)}"

  tags             = "${module.tf_label.tags}"
}


resource "aws_route_table" "public" {
  count = "${1 - signum(length(var.vpc_default_route_table))}"
  vpc_id = "${data.aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags         = "${module.tf_label.tags}"
}

resource "aws_route_table_association" "public" {
  count = "${1 - signum(length(var.vpc_default_route_table))}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}
