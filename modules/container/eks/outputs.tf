output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.this.arn
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_name" {
  value = aws_iam_role.node.name
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "node_instance_profile_name" {
  value = aws_iam_instance_profile.node.name
}

output "node_security_group_id" {
  value = aws_security_group.node.id
}

output "node_autoscaling_group" {
  value = var.create_node_group ? aws_cloudformation_stack.node[0].outputs["NodeAutoScalingGroup"] : null
}

output "oidc_provider_arn" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
