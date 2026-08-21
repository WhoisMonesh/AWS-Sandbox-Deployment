variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "random_suffix" {
  description = "Random suffix to guarantee a unique bucket name"
  type        = string
  default     = "0000"
}

variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "kk-lab-trail"
}
