resource "aws_acmpca_certificate_authority" "this" {
  type = var.ca_type
  certificate_authority_configuration {
    key_algorithm     = var.key_algorithm
    signing_algorithm = var.signing_algorithm
    subject {
      organization        = "KodeKloud Lab"
      organizational_unit = "Playground"
      country             = "US"
      common_name         = "${var.name_prefix}-pca"
    }
  }
  permanent_deletion_time_in_days = 7

  tags = {
    Name = "${var.name_prefix}-pca"
    Lab  = "kodekloud"
  }
}
