variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

variable "random_suffix" {
  description = "Random suffix to guarantee a unique artifact bucket name"
  type        = string
  default     = "0000"
}

variable "canary_name" {
  description = "Name of the CloudWatch Synthetics canary"
  type        = string
  default     = "kk-lab-canary"
}

variable "runtime" {
  description = "Canary runtime"
  type        = string
  default     = "syn-nodejs-puppeteer-9.0"
}

variable "handler" {
  description = "Canary handler (entrypoint in the zip)"
  type        = string
  default     = "index.handler"
}

variable "script_zip" {
  description = "Base64-encoded zip containing the canary script (index.js at root)"
  type        = string
  default     = "UEsDBBQAAAAIANpwFV0LkmXDlQAAAMkAAAAIABwAaW5kZXguanNVVAkAAyQOiGokDohqdXgLAAEE9QEAAAQAAAAATY6xDoJAEER7vmI6jsYfINjQmGBnYX05Frjk3NW9uygh/rtAoTZTzbw3TjgmBBnRQOmRvZIpLzOniZJ38SzjSFpWdeH2omZuLVud17qNMzsMmV3ywjAVlgIb6uB5EFOeKATBoHJDJz11QXKPdsurTW7CzwK3MzfNuy7odRdN8TBZ7gPp17QKmiMW2Kf1f09MVWNdfQBQSwECHgMUAAAACADacBVdC5Jlw5UAAADJAAAACAAYAAAAAAABAAAApIEAAAAAaW5kZXguanNVVAUAAyQOiGp1eAsAAQT1AQAABAAAAABQSwUGAAAAAAEAAQBOAAAA1wAAAAAA"
}
