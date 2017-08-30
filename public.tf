module "public_label" {
  source    = "git::https://github.com/cloudposse/tf_label.git?ref=tags/0.1.0"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.name}-public"
}

resource "null_resource" "public_cidr_block" {
  triggers = {
    subnet = "${
      cidrsubnet(
      signum(length(var.cidr_block)) == 1 ?
      var.cidr_block : data.aws_vpc.default.cidr_block,
      ceil(log(length(data.aws_availability_zones.available.names) * 2, 2)),
      length(data.aws_availability_zones.available.names) + count.index)
    }"
  }
}

resource "aws_subnet" "public" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  cidr_block        = "${null_resource.public_cidr_block.triggers.subnet}"
  tags              = "${module.public_label.tags}"
  depends_on        = ["null_resource.public_cidr_block"]
}

resource "aws_route_table" "public" {
  count  = "${signum(length(var.vpc_default_route_table_id)) == 1 ? 0 : 1}"
  vpc_id = "${data.aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }

  tags = "${module.public_label.tags}"
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
