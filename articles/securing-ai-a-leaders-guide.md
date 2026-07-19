# Securing AI: A Security Leader's Field Guide to LLM Risk

*By S. Naz — Senior Cybersecurity Leader (CISSP, CISM, CISA, CRISC)*

Your organization is already using AI — whether security approved it or not. Employees paste data
into chatbots, teams ship features on top of LLMs, and "let's add an AI agent" appears in every
roadmap. The question isn't whether to allow AI; it's whether you'll govern it before an incident
forces the conversation.

AI introduces a genuinely new attack surface that classic AppSec doesn't fully cover. Here's how I
frame the risk and the controls.

## The new attack surface, in plain terms

The **OWASP Top 10 for LLM Applications** is the most useful starting map. The two you'll meet first:

- **Prompt injection (LLM01):** untrusted input overriding your intended instructions. The nasty
  variant is *indirect* injection — malicious text hidden in a document or web page that your
  retrieval system feeds into the model's context. The model can't tell your instructions from the
  attacker's unless you design that boundary in.
- **Insecure output handling (LLM02):** treating model output as trusted and passing it straight to a
  browser, shell, or database. If model output can reach `eval()` or raw SQL, you've built an
  injection vector with extra steps.

Add **sensitive information disclosure** (the model leaking secrets or PII from its context) and
**excessive agency** (an agent with too many permissions taking real-world actions), and you have the
risks that matter most for anyone shipping AI features.

## Treat all content as data, never as instructions

The single most important design pattern: **establish a trust boundary.** Retrieved documents and
user messages are *untrusted data*, not commands. Your system prompt should say so explicitly, and —
because prompts alone aren't enough — you back it with **programmatic guardrails**: filter and
validate on the way *in* (flag injection attempts) and on the way *out* (catch leaked secrets or
system-prompt disclosure) before anything reaches a user or a tool.

## Least agency: the LLM08 lesson from IAM

We already learned this in cloud security: over-privilege is how a small compromise becomes a big
one. The same rule applies to AI agents. Give a tool or agent the **minimum** permissions it needs,
require **human-in-the-loop** confirmation for high-impact actions (sending email, moving money,
deleting data), and default to deny. An injected instruction is far less dangerous when the agent
simply can't perform the dangerous action.

## Governance: NIST AI RMF and ISO/IEC 42001

Controls need a program around them. The **NIST AI Risk Management Framework** gives a clean
structure — **Govern, Map, Measure, Manage**:

- **Govern:** an AI policy, clear accountability, and a model inventory. You can't secure the AI you
  don't know exists.
- **Map:** for each system, document its purpose, data, and potential harms.
- **Measure:** red-team it — test for prompt injection, measure jailbreak and PII-leak rates.
- **Manage:** deploy guardrails, monitor in production, and have an incident response path for AI
  abuse.

**ISO/IEC 42001** (the AI management system standard) complements this for organizations that need a
certifiable framework. Together they turn "we should be careful with AI" into a defensible program.

## Don't forget privacy

AI risk is also privacy risk. Training and inference data need the same discipline as any sensitive
data: classification, minimization, DLP, and clear boundaries under **GDPR / PIPEDA**. "The model
might have memorized it" is not a defense you want to explain to a regulator.

## The takeaway

Securing AI isn't exotic — it's the fundamentals applied to a new surface: establish trust
boundaries, validate input and output, enforce least privilege, and wrap it all in governance
(NIST AI RMF, ISO 42001) and privacy-by-design. Start now, while you're shaping how AI enters your
organization, rather than after an incident decides it for you.

---

*I write about AI security, cloud security, and governance. Connect with me on
[LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
