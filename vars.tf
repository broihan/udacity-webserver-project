variable "prefix" {
  type = string
  description = "The prefix which should be used for all resources."
  default = "webserver"
}

variable "location" {
  type = string
  description = "The Azure Region in which all resources should be created."
  default = "West Europe"
}

variable "number_of_vms" {
  type = number
  description = "The number of virtual machines. Each virtual machine contains a webserver. Incoming traffic will be load balancede across the number of virtual machines."
  default = 2
  validation {
    condition = var.number_of_vms >= 2 && var.number_of_vms <= 5
    error_message = "The number of virtual machines must be between 2 and 5."
  }
}

variable "environment" {
  type = string
  description = "Adds a tag to all resources with key environment and the provided value. Values maybe Production, Stage or something like that."
  default = "stage"
}