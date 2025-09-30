# Encrypted Configuration Management

This directory contains encrypted configuration files for the Hosty application, managed in a GitOps style.

## Overview

The Hosty application supports multiple configuration methods:
1. **Non-secret environment variables** - Plain values in Helm charts
2. **Secret environment variables** - Kubernetes Secrets
3. **Configuration files** - Encrypted .env files stored in version control

This README focuses on the **encrypted configuration file** approach.

## Directory Structure

```
apps/hosty/
├── app-conf/                      # Encrypted configs per environment
│   ├── dev/
│   │   └── .env.gpg              # Encrypted dev config
│   ├── prod/
│   │   └── .env.gpg              # Encrypted prod config
│   ├── .gitignore                # Prevents committing decrypted files
│   └── README.md                 # This file
├── config-templates/
│   └── .env.template             # Template for generating configs
└── scripts/
    └── generate-config.sh        # Script to generate and encrypt configs
```

## How It Works

### 1. Configuration Generation

Use the `generate-config.sh` script to create and encrypt configuration files:

```bash
cd apps/hosty

# Set configuration values
export NON_SECRET_CONF_FILE_VAR="dev-non-secret-conf-value"
export SECRET_CONF_FILE_VAR="dev-secret-conf-value"
export GPG_PASSPHRASE="dev-passphrase-12345"

# Generate encrypted config for dev environment
./scripts/generate-config.sh dev
```

This script:
- Reads the template from `config-templates/.env.template`
- Substitutes placeholder values with your environment variables
- Encrypts the result using GPG with AES256 cipher
- Saves the encrypted file to `app-conf/dev/.env.gpg`
- Removes the unencrypted temporary file for security

### 2. Updating Helm Values

After generating the encrypted config, you need to update the Helm values file:

```bash
# Get base64-encoded content
base64 < app-conf/dev/.env.gpg

# Add to helm/hosty/values-dev.yaml:
encryptedConfig: "jA0ECQMIL+wZK4KRZST/0sAdAUd7hNTi..."
```

Also ensure the GPG passphrase is set in the secrets section:

```yaml
secrets:
  GPG_PASSPHRASE: "dev-passphrase-12345"
```

### 3. Kubernetes Deployment

When you deploy the Helm chart:

1. **ConfigMap Creation** - The encrypted config is stored in a Kubernetes ConfigMap
2. **Init Container** - An Alpine Linux container with GPG:
   - Mounts the encrypted ConfigMap as read-only
   - Installs GPG
   - Decrypts the config using the `GPG_PASSPHRASE` from Kubernetes Secret
   - Writes decrypted config to a shared `emptyDir` volume
3. **Application Container** - The Hosty app:
   - Mounts the decrypted config volume at `/app/config`
   - Reads `/app/config/.env` at startup
   - Exposes values in API responses

### 4. Application Access

The Hosty application reads the configuration file at startup:

```python
# From apps/hosty/main.py
CONFIG_FILE = Path("/app/config/.env")
config_from_file = {}

if CONFIG_FILE.exists():
    with open(CONFIG_FILE) as f:
        for line in f:
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                config_from_file[key] = value
```

## Security Model

### Encryption
- **Algorithm**: GPG symmetric encryption with AES256
- **Passphrase Storage**: Different passphrases per environment, stored as Kubernetes Secrets
- **Version Control**: Only encrypted files (`.env.gpg`) are committed to git
- **Decrypted Files**: Never touch disk on host systems or in version control

### Secrets Management
- **GPG Passphrases**: Stored in Kubernetes Secrets, injected into init container
- **Decrypted Config**: Lives only in-memory (`emptyDir` volume) during pod lifetime
- **Config File Values**: Never logged or exposed outside the application

### Access Control
- **Encrypted ConfigMap**: Readable by anyone with cluster access
- **GPG Passphrase Secret**: Requires appropriate RBAC permissions
- **Decrypted Config**: Only accessible within the pod's namespace

## Environment Configuration

### Development Environment

```bash
# Configuration values
NON_SECRET_CONF_FILE_VAR="dev-non-secret-conf-value"
SECRET_CONF_FILE_VAR="dev-secret-conf-value"
GPG_PASSPHRASE="dev-passphrase-12345"

# Generate
./scripts/generate-config.sh dev

# Update helm/hosty/values-dev.yaml with:
# - encryptedConfig: (base64 of app-conf/dev/.env.gpg)
# - secrets.GPG_PASSPHRASE: "dev-passphrase-12345"
```

### Production Environment

```bash
# Configuration values
NON_SECRET_CONF_FILE_VAR="prod-non-secret-conf-value"
SECRET_CONF_FILE_VAR="prod-secret-conf-value"
GPG_PASSPHRASE="prod-passphrase-67890"

# Generate
./scripts/generate-config.sh prod

# Update helm/hosty/values-prod.yaml with:
# - encryptedConfig: (base64 of app-conf/prod/.env.gpg)
# - secrets.GPG_PASSPHRASE: "prod-passphrase-67890"
```

## GitOps Workflow

1. **Update Configuration**:
   ```bash
   export NON_SECRET_CONF_FILE_VAR="new-value"
   export SECRET_CONF_FILE_VAR="new-secret"
   export GPG_PASSPHRASE="your-passphrase"
   ./scripts/generate-config.sh dev
   ```

2. **Update Helm Values**:
   ```bash
   base64 < app-conf/dev/.env.gpg
   # Paste into helm/hosty/values-dev.yaml
   ```

3. **Commit and Push**:
   ```bash
   git add app-conf/dev/.env.gpg
   git add helm/hosty/values-dev.yaml
   git commit -m "Update dev configuration"
   git push
   ```

4. **Deploy**:
   ```bash
   helm upgrade --install hosty-dev ./helm/hosty \
     --namespace dev-weighter-net \
     --values ./helm/hosty/values-dev.yaml
   ```

## Verification

### Check Init Container Logs

```bash
kubectl logs -n dev-weighter-net -l app.kubernetes.io/name=hosty \
  -c decrypt-config
```

Look for:
- `Decryption exit code: 0` (success)
- Decrypted file contents displayed

### Test API Response

```bash
kubectl port-forward -n dev-weighter-net svc/hosty-dev 8000:8000 &
curl http://localhost:8000/
```

Expected response:
```json
{
  "host": "localhost:8000",
  "message": "I'm being hit from localhost:8000!",
  "nonSecretEnvVar": "dev-environment-value",
  "secretEnvVar": "dev-secret-value",
  "nonSecretConfFileVar": "dev-non-secret-conf-value",
  "secretConfFileVar": "dev-secret-conf-value"
}
```

## Troubleshooting

### Decryption Fails

**Symptom**: Init container logs show "decrypt_message failed"

**Solution**: Check that:
- `GPG_PASSPHRASE` secret matches the passphrase used during encryption
- Encrypted config in ConfigMap is valid base64

### Config Values Not Loading

**Symptom**: API returns default values like "default-conf-value"

**Solution**:
1. Check init container completed successfully
2. Verify decrypted file exists in pod:
   ```bash
   kubectl exec -n dev-weighter-net <pod-name> -- cat /app/config/.env
   ```
3. Check application logs for file read errors

### Wrong Passphrase

**Symptom**: Different passphrase for dev vs prod got mixed up

**Solution**: Each environment uses its own passphrase:
- Dev: `dev-passphrase-12345`
- Prod: `prod-passphrase-67890`

Regenerate the encrypted config with the correct passphrase.

## Manual Decryption

To manually decrypt a config file for inspection:

```bash
# Using the GPG passphrase
gpg --batch --passphrase 'dev-passphrase-12345' \
  --decrypt app-conf/dev/.env.gpg
```

**Warning**: Only decrypt configs in secure environments. Never commit decrypted files.

## Best Practices

1. **Different Passphrases**: Use unique GPG passphrases per environment
2. **Rotation**: Regularly rotate secrets and re-encrypt configs
3. **Access Control**: Limit who can access GPG passphrases and encrypted files
4. **Audit Trail**: All config changes are tracked in git history
5. **Testing**: Always test config changes in dev before applying to prod
6. **Documentation**: Keep this README updated when changing the config workflow

## Related Files

- `../config-templates/.env.template` - Configuration template
- `../scripts/generate-config.sh` - Encryption script
- `../helm/hosty/templates/configmap-encrypted.yaml` - ConfigMap for encrypted data
- `../helm/hosty/templates/deployment.yaml` - Init container and volume configuration
- `../helm/hosty/values-dev.yaml` - Dev environment configuration
- `../helm/hosty/values-prod.yaml` - Prod environment configuration
- `../main.py` - Application code that reads the config file