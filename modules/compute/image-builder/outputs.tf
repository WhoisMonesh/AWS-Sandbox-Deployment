output "infrastructure_config_arn" {
  value = aws_imagebuilder_infrastructure_configuration.this.arn
}

output "image_recipe_arn" {
  value = aws_imagebuilder_image_recipe.this.arn
}
