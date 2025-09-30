# Application Configuration
## Background
Applications are deployed to the Kubernetes cluster.
Kubernetes deployments have pods that are typically configured in one of two ways:
* Environment variables passed to the pod at launch time
* Configuration files that are read by the application running in the pod post launch.
  * Example: A fastAPI app might used pydantic settings to read an .env file from disk
Both of these configuration types have two types of parameters:
* Non-secret
* Secret

### Env vars
In the case of environment variables,
* Non-secret env variables can be configured as plain old helm chart values living in
  git, and injected at helm chart install time by supplying the appropriate values.yaml
  file.  Kubernetes config maps can be used for this as well.
* Secret env variables can also use helm chart values.  However, they should be
  managed as Kubernetes secrets.  An example secret would be POSTGRES_PASSWORD.
  Secrets can be injected at deploy time.  As an example POSTGRES_PASSWORD could
  be set in the github settings.  Github settings can maintain secrets for different
  environment such as dev, prod etc.  On the Kuberetes side, the helm charts should
  configure a secret that has a key whose value is injected at deployment time
  via the deployment script (e.g., a github action).  Typically this is done
  using something like `helm upgrade <release> --set postgresPassword { github.secrets.POSTGRES_PASSWORD }`

### Conf files
In the case of configuration files,
Both non-secret and secret values should be combined into a .env file.
This file can be version controlled, but should not be stored in plaintext
so as to avoid leaking secrets in github.  Therefore, .env files should be
encrypted using gpg and stored into github.  The GPG_PASSPHRASE key is
a secret that lives outside of version control and is managed by
* A human in a password manager like lastpass
* CICD using github secrets
On the Kubernetes side, a volume mounts a directory containing the encrypted
conf.  An initcontainer uses decrypts the configuration into a new, empty
volume using the GPG_KEY.

## Tasks
Let's add configuration to the hostly app.
We will add configuration parameters of the various types.

Use fields in the output of the api response.  Example:
```json
{
  nonSecretEnvVar: 'nonSecretEnvValue',
  secretEnvVar: 'secretEnvValue',
  nonSecretConfFileVar: 'nonSecretConfFileValue',    
  secretConfFileVar: 'secretConfFileValue',    
}
```

We will proceed in steps:
1. Add a non-secret env var to hostly.  Use helm values with different environments like dev, prod.
2. Add a secret env var to hostly.  Demo with different environments like dev, prod.

