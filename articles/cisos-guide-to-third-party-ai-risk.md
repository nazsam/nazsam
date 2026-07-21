# The CISO's Guide to Third-Party AI Risk

*By S. Naz · Cybersecurity, Cloud & AI Security Leader*

Your vendor risk management program almost certainly has a mature process for evaluating a new SaaS vendor's SOC 2 report. Ask it to evaluate whether that same vendor's embedded AI feature trains on your customer data, and most programs have no defined process at all. Third-party AI risk needs its own lane inside vendor risk management — the existing questionnaire doesn't ask the right questions yet.

## What the Standard Vendor Questionnaire Misses

Traditional vendor security questionnaires focus on data handling, access controls, and incident history. AI-specific risk needs additional questions: does the vendor's product use your data to train or fine-tune models, and if so, is that opt-out or opt-in; what foundation model providers are embedded in their stack, creating a fourth-party risk you may not have visibility into; and what happens to data processed by the AI feature if you terminate the contract — is it purged from any derived models, or does it persist indefinitely.

## Building an AI Addendum to Vendor Risk Assessment

Rather than rebuilding vendor risk management from scratch, add an AI-specific addendum triggered whenever a vendor's product includes generative AI or ML features: data usage and training rights, model provenance and the fourth-party AI providers involved, and contractual commitments around data deletion and model retraining if the relationship ends. This addendum should trigger automatically based on vendor self-attestation during onboarding, not rely on the security team catching it manually.

## Handling the Vendors You Already Have

Existing vendors are rolling out AI features into products you've already approved, often without a new procurement cycle to catch it. A practical response: require vendors to notify you before enabling new AI features in existing products (build this into contract renewal language going forward), and run a periodic sweep of your approved vendor list specifically checking for AI feature additions since the last review.

## Key Takeaways

- Standard vendor security questionnaires don't cover AI-specific risks like training-data usage and fourth-party model providers.
- Build an AI-specific addendum that triggers automatically rather than relying on manual catch-all review.
- Existing vendors adding AI features to already-approved products is a growing blind spot — build renewal-cycle checks for it.

---
*Part of the [devsecforge](https://github.com/devsecforge/devsecforge) writing series — also cross-posted on [LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
