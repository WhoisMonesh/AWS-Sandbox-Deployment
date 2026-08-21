variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "service_name" {
  type    = string
  default = "kk-apprunner"
}

variable "image_identifier" {
  type    = string
  default = "public.ecr.aws/docker/library/nginx:latest"
}
