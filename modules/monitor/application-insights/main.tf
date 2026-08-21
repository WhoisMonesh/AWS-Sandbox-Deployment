resource "aws_resourcegroups_group" "this" {
  name = var.resource_group_name

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Lab"
          Values = ["kodekloud"]
        }
      ]
    })
  }

  tags = {
    Lab = "kodekloud"
  }
}

resource "aws_applicationinsights_application" "this" {
  resource_group_name = aws_resourcegroups_group.this.name

  tags = {
    Lab = "kodekloud"
  }
}
