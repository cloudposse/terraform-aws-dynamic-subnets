resource "aws_eip" "default" {
  count = "${length(var.availability_zones)}"
  vpc   = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "default" {
  count         = "${length(var.availability_zones)}"
  allocation_id = "${element(aws_eip.default.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.private.*.id, count.index)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "default" {
  count  = "${1 - signum(length(var.igw_id))}"
  vpc_id = "${data.aws_vpc.default.id}"
  tags   = "${module.tf_label.tags}"
}
