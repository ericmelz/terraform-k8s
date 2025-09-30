# Tailscale OAuth Client Setup for GitHub Actions

## Problem
GitHub Actions fails with: `"requested tags [tag:ci] are invalid or not permitted"`

## Solution

### Step 1: Update Tailscale ACL

Go to https://login.tailscale.com/admin/acls and ensure your ACL includes:

```json
{
  "tagOwners": {
    "tag:ci": ["autogroup:admin"]
  },
  "grants": [
    {
      "src": ["tag:ci"],
      "dst": ["*"],
      "ip": ["*"]
    }
  ]
}
```

**Important**: Make sure there are no syntax errors. Click "Save" at the bottom.

### Step 2: Delete and Recreate OAuth Client

The OAuth client needs to be created **after** the tag is defined in the ACL.

1. Go to: https://login.tailscale.com/admin/settings/oauth
2. **Delete** your existing OAuth client (if you created one before defining the tag)
3. Click "Generate OAuth client"
4. The client is automatically authorized to use all tags defined in your ACL
5. Copy the **Client ID** and **Client Secret**

### Step 3: Update GitHub Secrets

Run the setup script again with the new OAuth credentials:

```bash
./scripts/setup-github-secrets.sh
```

When prompted, enter the new Client ID and Client Secret.

### Step 4: Test the Workflow

Trigger the workflow manually to test:

```bash
gh workflow run sync-namespaces.yaml
```

Or make a change to trigger it:

```bash
echo "# Test" >> k8s/namespaces/README.md
git add k8s/namespaces/README.md
git commit -m "Test namespace sync workflow"
git push
```

Check the workflow logs:

```bash
gh run watch
```

## Verification

Once the workflow succeeds, you should see the GitHub Actions runner appear temporarily in your Tailscale admin panel under "Machines" with the tag `tag:ci`.

The runner will automatically disconnect after the workflow completes (ephemeral).