# CSPM in a Multi-Cloud World: One Posture-Management Operating Model

*By S. Naz · Cybersecurity, Cloud & AI Security Leader*

Most enterprises aren't single-cloud by choice — they're multi-cloud by acquisition, by business unit autonomy, or by a vendor negotiation that happened three reorgs ago. Cloud Security Posture Management tooling promises to unify visibility across that sprawl, but the tooling is only half the problem. The operating model around it is what actually determines whether posture management works or becomes another dashboard nobody acts on.

## The Tooling Layer

Modern CSPM platforms — whether native (Defender for Cloud, Security Hub) or third-party — can ingest findings across Azure, AWS, and GCP and normalize them against common frameworks like CIS Benchmarks and NIST CSF. That normalization matters: a misconfigured storage bucket is conceptually the same finding whether it's an S3 bucket or a Blob container, and your remediation workflow should treat it that way rather than running three parallel processes per cloud.

## The Operating Model Layer — Where Most Programs Actually Fail

Tooling tells you what's wrong. It doesn't assign an owner, set a remediation SLA, or escalate when the SLA is missed. Build that layer deliberately: route findings to the team that owns the resource (not a central security queue that becomes a bottleneck), set risk-based SLAs so a public S3 bucket with sensitive data gets fixed in hours while a low-severity finding gets fixed in the normal sprint cycle, and report aggregate posture trends to leadership monthly so posture management stays visible above the team level.

## Preventing Drift, Not Just Detecting It

The highest-leverage move is shifting posture enforcement left, into the same Infrastructure-as-Code pipelines that provision the resources in the first place — policy-as-code checks (via Open Policy Agent, Azure Policy, or AWS Config rules) that block a misconfigured resource from ever being created beat detecting it after the fact every time.

## Key Takeaways

- CSPM tooling normalizes findings across clouds, but the operating model around ownership and SLAs determines real-world impact.
- Route findings to resource owners directly rather than centralizing remediation in the security team.
- Shift posture enforcement into IaC pipelines to prevent drift instead of only detecting it after deployment.

---
*Part of the [devsecforge](https://github.com/devsecforge/devsecforge) writing series — also cross-posted on [LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
