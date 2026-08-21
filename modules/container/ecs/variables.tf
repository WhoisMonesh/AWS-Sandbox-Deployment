variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "cluster_name" {
  type    = string
  default = "kk-lab-ecs"
}

variable "container_image" {
  type    = string
  default = "public.ecr.aws/docker/library/nginx:latest"
}
