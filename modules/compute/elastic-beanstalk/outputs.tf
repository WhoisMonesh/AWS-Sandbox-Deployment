output "environment_id" {
  value = aws_elastic_beanstalk_environment.this.id
}

output "cname" {
  value = aws_elastic_beanstalk_environment.this.cname
}
