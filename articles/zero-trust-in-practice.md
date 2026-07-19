# Zero Trust in Practice: Turning NIST 800-207 Into Controls That Actually Ship

*By S. Naz — Senior Cybersecurity Leader (CISSP, CISM, CISA, CRISC)*

"Zero Trust" has become the most over-marketed phrase in security. Vendors sell it as a product;
slide decks reduce it to "never trust, always verify" and move on. But Zero Trust isn't a box you
buy — it's an operating model, and the gap between the principle and a working implementation is
where most programs stall.

After years of building these programs, here's how I translate **NIST SP 800-207** from a framework
into controls that survive contact with a real enterprise.

## Start with the three tenets, not the tooling

NIST 800-207 boils down to three ideas:

1. **Verify explicitly** — authenticate and authorize every request using all available signals.
2. **Least-privilege access** — just enough, just in time.
3. **Assume breach** — segment, encrypt, monitor, and minimize blast radius.

Notice what's missing: a product name. Every tenet maps to controls you likely already own in
Microsoft Entra, AWS IAM, or your EDR. Zero Trust is mostly *configuration and discipline*, not
net-new spend.

## Identity is the control plane — start there

If you do one thing, make **identity** your first perimeter. Concretely:

- **Phishing-resistant MFA for everyone**, not just admins. Attackers phish users, then pivot.
- **Block legacy authentication.** Legacy protocols bypass MFA entirely — they're the unlocked back
  door behind your shiny front-door policy.
- **Risk-based Conditional Access.** Use sign-in and user risk signals to step up or block, rather
  than static IP allow-lists that break the moment someone travels.
- **Just-in-time privilege (PIM).** No standing global admins. Roles are *eligible*, time-bound, and
  require justification.

A hard-won lesson: **deploy every new access policy in report-only mode first.** Watch the sign-in
logs, understand who it would have blocked, *then* enforce. And always keep two monitored
break-glass accounts excluded from Conditional Access — tested quarterly. The fastest way to lose
executive trust in a Zero Trust program is to lock the CEO out on day one.

## Least privilege is a practice, not a project

Wildcard permissions (`*:*`) are the single most common — and most damaging — cloud
misconfiguration I see. Least privilege means:

- Scope IAM to **specific ARNs and actions**, never "all resources, all actions."
- Separate **read** from **write**; a reporting role never needs delete.
- Split **using** a key (`kms:Decrypt`) from **managing** it (`kms:*`).

Start from zero and add exactly the permission an application fails without. It's slower than
granting `*`, and it's the difference between a contained incident and a full account compromise.

## Assume breach: segment and watch everything

Perimeter thinking says "keep them out." Zero Trust assumes they're already in and asks "how do I
limit what they can reach?"

- **Micro-segmentation and default-deny networking** so a compromised workload can't move laterally.
- **Encryption in transit and at rest**, enforced (deny non-TLS, require KMS) — not merely available.
- **Centralized detection** feeding a SIEM, because a control you can't observe is a control you
  can't trust.

## Measure the journey, don't declare victory

Zero Trust is a maturity journey — Traditional → Initial → Advanced → Optimal — not a switch you
flip. Score each pillar (identity, devices, network, apps, data, visibility) honestly, pick **one
increment per quarter**, and report progress to leadership as a heat-map. "% of workforce on
phishing-resistant MFA" communicates far better than a 200-row controls spreadsheet.

## The takeaway

Zero Trust succeeds when you stop treating it as a purchase and start treating it as a set of
disciplined defaults: verify every request, grant the minimum, and assume the adversary is already
inside. Most of it is configuration you already own — applied consistently, measured honestly, and
rolled out without locking out the business.

---

*I write about practical security leadership, cloud security, and DevSecOps. Connect with me on
[LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
