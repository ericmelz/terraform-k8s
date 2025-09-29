# DNS Automation Setup

## Current State
DNS records for `rancher.emelz.org` and `dev.emelz.org` are currently managed manually in a different AWS account.

## Enabling Automated DNS Management

Once you migrate the `emelz.org` hosted zone to this AWS account (057581197427), follow these steps:

### 1. Create terraform.tfvars
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars
```hcl
manage_dns = true
```

### 3. Apply Terraform
```bash
terraform plan   # Review changes
terraform apply  # Create DNS records automatically
```

## What Gets Automated

When `manage_dns = true`:
- ✅ A record for `rancher.emelz.org` → EC2 elastic IP
- ✅ A record for `dev.emelz.org` → EC2 elastic IP
- ✅ Automatic updates if instance IP changes
- ✅ DNS records deleted when running `terraform destroy`

## Benefits

1. **Infrastructure as Code**: DNS changes tracked in git
2. **Consistency**: DNS always points to current infrastructure
3. **Reproducibility**: Entire stack recreatable with one command
4. **No Manual Updates**: Change IPs without touching Route53 console

## Migration Steps (When Ready)

1. **In your other AWS account**: Export the hosted zone
2. **In this account**: Import or recreate the hosted zone
3. **Update domain registrar**: Point nameservers to new Route53 zone
4. **Wait for propagation**: 24-48 hours for DNS to propagate
5. **Enable in Terraform**: Set `manage_dns = true`
6. **Apply**: Run `terraform apply`

## Optional: Wildcard DNS

Uncomment the wildcard record in `terraform/route53.tf` to make `*.emelz.org` point to this instance:

```hcl
resource "aws_route53_record" "wildcard" {
  count = var.manage_dns ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.k8s_instance.public_ip]
}
```

## Testing

Before migration, verify Terraform configuration:
```bash
terraform validate
terraform plan
```

The plan should show "No changes" when `manage_dns = false`.