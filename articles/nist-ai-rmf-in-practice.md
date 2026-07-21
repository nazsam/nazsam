# NIST AI RMF in Practice: A 90-Day Implementation Plan

*By S. Naz · Cybersecurity, Cloud & AI Security Leader*

The NIST AI Risk Management Framework is comprehensive, well-designed, and — like most NIST frameworks — not something you implement by reading it once and hoping. Here's a practical 90-day plan to go from "we've heard of it" to "we're operating against it," broken into three 30-day phases: Map, Measure, Manage.

## Days 1–30: Map

The AI RMF's "Map" function is about establishing context before you try to control anything. In the first 30 days, inventory every AI system in use or development, identify who owns each one, document the intended use case and any known limitations, and classify each system by potential impact — a customer-facing chatbot and an internal document summarizer carry very different risk profiles. This inventory becomes the foundation everything else builds on, and it usually surfaces more AI usage than leadership expected.

## Days 31–60: Measure

With the map in hand, the "Measure" function is where you assess each system against relevant risks: fairness and bias, robustness to adversarial input, transparency and explainability, and security risks like those in the OWASP LLM Top 10. You don't need bespoke tooling for every system on day one — a structured risk questionnaire, applied consistently, gets you 80% of the value and identifies which systems need deeper technical evaluation.

## Days 61–90: Manage

The final phase turns assessment into action: define risk tolerance thresholds and escalation paths, assign accountable owners for ongoing monitoring, and build the governance cadence — a recurring AI risk review, not a one-time audit — that keeps the program alive after day 90. This is also where you formalize approval gates for new AI systems entering production, so the inventory doesn't go stale the moment you finish building it.

## What Success Looks Like at Day 90

Not a perfect program — a *running* one. You should have a living inventory, a repeatable risk assessment process, and a governance cadence with named owners. That's a foundation you can mature over the following year, and it's dramatically more than most organizations have today.

## Key Takeaways

- Map, Measure, Manage — in that order — is the fastest path to a working program, not a perfect one.
- The initial AI inventory is often the most valuable (and most eye-opening) deliverable.
- A governance cadence matters more than a one-time audit; risk management is a process, not a checkbox.

---
*Part of the [devsecforge](https://github.com/devsecforge/devsecforge) writing series — also cross-posted on [LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
