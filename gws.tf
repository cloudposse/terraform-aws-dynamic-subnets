module "nat_gateway_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.2.1"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

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
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  lifecycle {
    create_before_destroy = true
  }

  tags = "${module.nat_gateway_label.tags}"
}
