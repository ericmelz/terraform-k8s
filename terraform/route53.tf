# Route53 DNS Configuration
# Note: Set manage_dns = true in terraform.tfvars after migrating emelz.org to this AWS account

# Data source to look up the existing hosted zone
data "aws_route53_zone" "main" {
  count = var.manage_dns ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

# A record for Rancher UI
resource "aws_route53_record" "rancher" {
  count = var.manage_dns ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${var.rancher_subdomain}.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.k8s_instance.public_ip]
}

# A record for development/demo applications
resource "aws_route53_record" "dev" {
  count = var.manage_dns ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${var.dev_subdomain}.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.k8s_instance.public_ip]
}

# Optional: Wildcard record for additional subdomains
# Uncomment if you want *.emelz.org to point to this instance
# resource "aws_route53_record" "wildcard" {
#   count = var.manage_dns ? 1 : 0
#
#   zone_id = data.aws_route53_zone.main[0].zone_id
#   name    = "*.${var.domain_name}"
#   type    = "A"
#   ttl     = 300
#   records = [aws_eip.k8s_instance.public_ip]
# }