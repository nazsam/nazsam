# Building an AI-BOM: Model Supply-Chain Visibility for Security Teams

*By S. Naz · Cybersecurity, Cloud & AI Security Leader*

Software Bills of Materials became table stakes after SolarWinds and Log4Shell. AI systems need the same discipline, because a model is a supply-chain artifact just like a software dependency — except most security teams can't currently answer basic questions like "which models are running in production, what were they trained on, and what's their provenance?"

## What Goes Into an AI-BOM

An AI Bill of Materials should capture, at minimum: the model name, version, and source (proprietary API, open-weight download, fine-tuned derivative); the base model it was built from, if fine-tuned; known training data sources or datasets, where disclosed; the licenses governing use and redistribution; and the evaluation and safety testing performed before deployment. If you can't fill in most of these fields for a model in production today, that's the gap to close first.

## Why This Isn't Just Paperwork

Without an AI-BOM, you can't answer a CVE-style question when a foundation model provider discloses a vulnerability or a training-data issue. You can't do impact analysis when a vendor deprecates a model version. And you can't demonstrate due diligence to an auditor or regulator asking how you're managing AI risk — which is increasingly a real question, not a hypothetical one, under frameworks like the EU AI Act.

## Getting Started Without Boiling the Ocean

Start with an inventory, not a perfect BOM: list every model and API endpoint currently in use across the org, including the ones procurement doesn't know about (see: Shadow AI). Layer in provenance and licensing data as you touch each system. Wire the inventory into your existing CMDB or asset management tooling rather than standing up a parallel system — the goal is one source of truth, not another spreadsheet nobody updates.

## Key Takeaways

- Treat models like software dependencies: you need to know what's running, where it came from, and what it depends on.
- Start with a basic inventory before chasing a perfect, fully automated AI-BOM.
- This is becoming a compliance requirement, not just a best practice, under emerging AI regulation.

---
*Part of the [devsecforge](https://github.com/devsecforge/devsecforge) writing series — also cross-posted on [LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
