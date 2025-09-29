# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.k8s_rancher.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.k8s_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.k8s_rancher.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ../ssh-keys/k8s-rancher-key.pem ubuntu@${aws_eip.k8s_instance.public_ip}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.k8s_instance.id
}

# DNS Outputs (only populated when manage_dns = true)
output "rancher_url" {
  description = "URL to access Rancher UI"
  value       = var.manage_dns ? "https://${aws_route53_record.rancher[0].fqdn}" : "https://rancher.emelz.org (DNS managed manually)"
}

output "dev_url" {
  description = "URL for development/demo applications"
  value       = var.manage_dns ? "https://${aws_route53_record.dev[0].fqdn}" : "https://dev.emelz.org (DNS managed manually)"
}

output "dns_managed" {
  description = "Whether DNS is managed by Terraform"
  value       = var.manage_dns
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID (if DNS is managed)"
  value       = var.manage_dns ? data.aws_route53_zone.main[0].zone_id : "N/A - Set manage_dns = true"
}