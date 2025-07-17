variable "envs" {
  default = ["dev", "test", "prod"]
}

variable "cidr_blocks" {
  default = {
    dev  = "10.1.0.0/16"
    test = "10.2.0.0/16"
    prod = "10.3.0.0/16"
  }
}

variable "key_name" {
  default = "dev-key"
}