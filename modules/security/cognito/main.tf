resource "aws_cognito_user_pool" "this" {
  name = "${var.name_prefix}-user-pool"

  mfa_configuration = "ON"

  password_policy {
    minimum_length    = 12
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  auto_verified_attributes = ["email"]

  tags = {
    Name = "${var.name_prefix}-user-pool"
    Lab  = "kodekloud"
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name                = "${var.name_prefix}-client"
  user_pool_id        = aws_cognito_user_pool.this.id
  generate_secret     = false
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

data "aws_iam_policy_document" "assume_authenticated" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.this.id]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role" "authenticated" {
  name               = "${var.name_prefix}-cognito-auth"
  assume_role_policy = data.aws_iam_policy_document.assume_authenticated.json

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_iam_role_policy_attachment" "authenticated" {
  role       = aws_iam_role.authenticated.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}

resource "aws_cognito_identity_pool" "this" {
  identity_pool_name               = "${var.name_prefix}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.this.id
    provider_name           = aws_cognito_user_pool.this.endpoint
    server_side_token_check = false
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "this" {
  identity_pool_id = aws_cognito_identity_pool.this.id

  roles = {
    authenticated = aws_iam_role.authenticated.arn
  }
}
