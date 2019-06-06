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

variable "tags" {
  description = "Additional tags to apply to all resources that use this label module"
  type        = "map"
  default     = {}
}

variable "namespace" {
  type        = "string"
  default     = ""
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = "string"
  default     = ""
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "name" {
  type        = "string"
  default     = ""
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "environment" {
  description = "The environment name if not using stage"
  default     = ""
}

variable "attributes" {
  type        = "list"
  description = "Any extra attributes for naming these resources"
  default     = []
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name` and `attributes`"
}

variable "context" {
  type        = "map"
  description = "The context output from an external label module to pass to the label modules within this module"
  default     = {}
}
