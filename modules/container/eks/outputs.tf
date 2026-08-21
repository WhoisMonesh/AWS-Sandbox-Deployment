output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.this.arn
}

output "node_role_name" {
  value = aws_iam_role.node.name
}

output "oidc_provider_arn" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
