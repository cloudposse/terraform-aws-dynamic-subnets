module "label" {
  source              = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  attributes          = var.attributes
  namespace           = var.namespace
  environment         = var.environment
  stage               = var.stage
  delimiter           = var.delimiter
  name                = var.name
  tags                = var.tags
  additional_tag_map  = var.additional_tag_map
  regex_replace_chars = var.regex_replace_chars
  label_order         = var.label_order
  context             = var.context
}

variable "additional_tag_map" {
  type        = map(string)
  default     = {}
  description = "Additional tags for appending to each tag map"
}

variable "label_order" {
  type        = list(string)
  default     = []
  description = "The naming order of the ID output and Name tag"
}

variable "regex_replace_chars" {
  type        = string
  default     = "/[^a-zA-Z0-9-]/"
  description = "Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed"
}

variable "tags" {
  description = "Additional tags to apply to all resources that use this label module"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = string
  default     = ""
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "name" {
  type        = string
  default     = ""
  description = "Solution name, e.g. 'app' or 'cluster'"
}

variable "environment" {
  type        = string
  description = "The environment name if not using stage"
  default     = ""
}

variable "attributes" {
  type        = list(string)
  description = "Any extra attributes for naming these resources"
  default     = []
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name` and `attributes`"
}

variable "context" {
  type = object({
    namespace           = string
    environment         = string
    stage               = string
    name                = string
    enabled             = bool
    delimiter           = string
    attributes          = list(string)
    label_order         = list(string)
    tags                = map(string)
    additional_tag_map  = map(string)
    regex_replace_chars = string
  })
  default = {
    namespace           = ""
    environment         = ""
    stage               = ""
    name                = ""
    enabled             = true
    delimiter           = ""
    attributes          = []
    label_order         = []
    tags                = {}
    additional_tag_map  = {}
    regex_replace_chars = ""
  }
  description = "Default context to use for passing state between label invocations"
}
