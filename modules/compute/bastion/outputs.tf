output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Bastion public DNS name"
  value       = aws_instance.bastion.public_dns
}

output "private_key_filename" {
  description = "Local path to the generated private key (gitignored)"
  value       = local_file.private_key.filename
}

output "ssh_command" {
  description = "Ready-to-run SSH command"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.bastion.public_ip}"
}

output "connect_eks_command" {
  description = "Command to configure kubectl on the bastion"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}
