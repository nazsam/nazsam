# Deploy, test, tear down

## Prerequisites

- Terraform >= 1.6
- Azure CLI logged in (`az login`) with Owner or Contributor + User Access Administrator on the subscription
- Your public IP as `admin_source_prefix` (`curl ifconfig.me`)

## Deploy learn

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit subscription_id, tenant_id, admin_source_prefix
terraform init
terraform plan  -var-file=profiles/learn.tfvars
terraform apply -var-file=profiles/learn.tfvars
terraform output
```

## Test

1. SSH to `jumpbox_public_ip` with the password from Key Vault (see `jumpbox_admin_secret_name`).
2. From the jump box, `az login` with managed identity is not enabled for CLI by default; use it as a network hop.
3. Confirm spokes have no public IPs.
4. Run `../scripts/validate.ps1`.

## Switch to dev / prod

```bash
terraform apply -var-file=profiles/dev.tfvars
# later
terraform apply -var-file=profiles/prod.tfvars
```

Prod creates a VPN gateway. Do not start that apply unless you can wait ~45 minutes and pay the hourly SKU.

## Tear down

```bash
terraform destroy -var-file=profiles/<current>.tfvars
```

If destroy fails on a Key Vault with purge protection, remove the vault from state only after you accept the soft-delete retention, or wait for the retention period.

## If Network Watcher create fails

Some subscriptions already have a regional Network Watcher. If so, import it or change `modules/hub-network` to a `data` source named `NetworkWatcher_<region>` in `NetworkWatcherRG`.
