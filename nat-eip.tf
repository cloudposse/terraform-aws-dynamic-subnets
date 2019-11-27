locals {
  nat_eip_count = "${local.nat_gateways_count > 0 ? local.nat_gateways_count : (local.nat_instance_count > 0 ? local.nat_instance_count : 0)}"
}

resource "aws_eip" "default" {
  count = "${local.nat_eip_count}"
  vpc   = true
  tags  = "${merge(module.private_label.tags, map("Name", format("%s%s%s", module.private_label.id, var.delimiter, replace(element(var.availability_zones, count.index), "-", var.delimiter))))}"

  lifecycle {
    create_before_destroy = true
  }
}
