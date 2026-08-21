variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "kk-lab"
}

# Optional override for a globally unique bucket name. When empty (default)
# the module falls back to the AWS account id, which is unique per lab session.
variable "random_suffix" {
  description = "Optional suffix for a globally unique bucket name"
  type        = string
  default     = ""
}

# The KodeKloud lab IAM user lacks the read permissions the provider needs to
# refresh these sub-resources after creation (s3:GetBucketPublicAccessBlock,
# s3:GetBucketVersioning, s3:GetEncryptionConfiguration), so they are opt-in.
# Enable them only in accounts where those read actions are permitted.
variable "enable_extras" {
  description = "Create public-access-block, versioning, and SSE configs"
  type        = bool
  default     = false
}
