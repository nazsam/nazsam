# Ransomware Resilience: Building an Incident Response Plan That Actually Works

*By S. Naz · Cybersecurity, Cloud & AI Security Leader*

Most ransomware incident response plans read well in a tabletop exercise and fall apart in the first real hour of an actual incident — because tabletop exercises rarely simulate the thing that actually determines outcome: how fast you can make decisions under genuine uncertainty and pressure.

## The Plan Is Not the Capability

A written IR plan documents *what should happen*. Resilience is whether the organization can actually execute it at 2 a.m. when the CEO is calling and nobody's sure yet how far the attacker got. That gap closes through repetition — tabletop exercises run quarterly, not annually, with scenarios that get harder each time and include the uncomfortable decisions (do we pay, do we notify customers before we have full facts, do we take production systems offline preemptively).

## The Controls That Change the Outcome Before It Starts

Immutable, offline backups tested through actual restoration drills — not just backup jobs that report success — are the single control most correlated with a fast recovery instead of a ransom payment. Network segmentation limits how far an initial compromise can spread before detection. And a pre-negotiated relationship with a DFIR retainer firm and outside counsel means you're not evaluating vendors for the first time during the incident itself.

## The First 24 Hours, Structured

Containment decisions (isolate affected systems, but preserve evidence) come before eradication. Communication — internal, to leadership, and eventually external if required — needs a single accountable owner so mixed messages don't leak or contradict each other. And the decision to engage law enforcement and regulators should already have a documented threshold and process, not be improvised mid-incident when clarity is hardest to find.

## Key Takeaways

- Tested, immutable backups are the highest-leverage control for avoiding a ransom decision entirely.
- Quarterly tabletop exercises with escalating difficulty build real decision-making capability, not just document review.
- Pre-negotiate DFIR and legal retainers before an incident, not during one.

---
*Part of the [devsecforge](https://github.com/devsecforge/devsecforge) writing series — also cross-posted on [LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
