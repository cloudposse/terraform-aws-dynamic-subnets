variable "max_availability_zones" {}

variable "region" {}

variable "availability_zones" {
  type = list(string)
}

variable "namespace" {}

variable "name" {}

variable "stage" {}
