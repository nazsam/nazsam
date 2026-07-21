# Kubernetes Security in Production: Beyond the Basics

*By S. Naz · Cybersecurity, Cloud & AI Security Leader*

Most Kubernetes security guidance stops at "enable RBAC and use Network Policies," which is true but incomplete — those are table stakes, not a production-grade security posture. Real defense-in-depth for Kubernetes needs to cover the layers most teams skip: admission control, runtime detection, and the supply chain that produces the images running in your cluster.

## Layer 1: Admission Control — Stopping Bad Config Before It Deploys

Pod Security Admission (the built-in successor to Pod Security Policies) enforces baseline, restricted, or privileged profiles at the namespace level, blocking privileged containers and host-path mounts before they ever schedule. Layer OPA Gatekeeper or Kyverno on top for organization-specific policy — requiring resource limits, blocking images from unapproved registries, enforcing label standards — and you've closed the gap between "technically allowed by Kubernetes" and "allowed by your organization's standards."

## Layer 2: Runtime Detection — Because Prevention Isn't Perfect

Falco (and similar eBPF-based tools) watches actual syscall behavior inside running containers and flags anomalies — a shell spawned inside a container that should never spawn one, unexpected outbound connections, file access outside an expected path. This is the layer that catches what admission control couldn't prevent, and it's the layer most Kubernetes security programs skip entirely because it requires ongoing tuning rather than a one-time configuration.

## Layer 3: The Image Supply Chain

Every container image is a software supply chain artifact — scan it with Trivy or similar tooling in CI before it ever reaches a registry, sign images with Cosign so the cluster can verify provenance at deploy time, and enforce that verification through admission control so an unsigned or unscanned image simply can't run. This closes the loop between SBOM and supply-chain practices and what actually executes in production.

## Layer 4: Network Policy as Default-Deny, Not Default-Allow

Most clusters run with fully open pod-to-pod networking by default. A default-deny NetworkPolicy per namespace, with explicit allow rules for actual required traffic, dramatically limits lateral movement if any single pod is compromised — the Kubernetes equivalent of network segmentation, and one of the highest-leverage changes most clusters still haven't made.

## Key Takeaways

- RBAC and Network Policies are table stakes — admission control, runtime detection, and supply chain verification are where real defense-in-depth lives.
- Falco-style runtime detection catches what prevention layers miss, but needs ongoing tuning investment.
- Default-deny NetworkPolicy per namespace is one of the highest-leverage, most-skipped configuration changes.

---
*Part of the [devsecforge](https://github.com/devsecforge/devsecforge) writing series — also cross-posted on [LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
