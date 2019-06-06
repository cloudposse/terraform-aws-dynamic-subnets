module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.11.1"
  attributes  = ["${var.attributes}"]
  namespace   = "${var.namespace}"
  environment = "${var.environment}"
  delimiter   = "${var.delimiter}"
  name        = "${var.name}"
  tags        = "${var.tags}"
  context     = "${var.context}"
}
