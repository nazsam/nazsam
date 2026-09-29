# Backup and disaster recovery

## File data

- Azure File Sync keeps a full copy in Azure Files
- Azure Backup (Recovery Services vault) protects the Azure file share (snapshots + vault-tier backup)
- On-prem file server OS disks: MARS agent or Azure Backup via Arc

## Hyper-V VMs

1. Create a Hyper-V site in the vault
2. Install Site Recovery Provider + Microsoft Azure Recovery Services agent on each host
3. Replicate selected VMs to a target VNet in Azure (the spoke in this lab)
4. Run a test failover that does **not** touch production DNS
5. Document failback

Do not put your only domain controller in ASR without a second DC and a written forest recovery plan.

## Run a test failover (outline)

1. Vault → Replicated items → Test failover
2. Choose an isolated Azure VNet
3. Confirm boot and app
4. Cleanup test failover
