variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "application_name" {
  type    = string
  default = "kk-beanstalk-app"
}

variable "application_version_label" {
  type    = string
  default = "v1"
}

variable "s3_bucket" {
  description = "S3 bucket holding the application source bundle (default is a placeholder; set to a real bucket with the key below)"
  type        = string
  default     = "kk-lab-beanstalk-sample"
}

variable "s3_key" {
  description = "S3 object key of the application source bundle zip"
  type        = string
  default     = "sample.zip"
}

variable "solution_stack_name" {
  type    = string
  default = "64bit Amazon Linux 2023 v4.0.1 running Python 3.11"
}

variable "cname_prefix" {
  type    = string
  default = "kk-beanstalk"
}
