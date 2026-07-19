# Detection Engineering That Works: High-Fidelity Rules, Not Alert Noise

*By S. Naz — Senior Cybersecurity Leader (CISSP, CISM, CISA, CRISC)*

Every SOC I've inherited had the same problem: too many alerts, too little signal. Analysts drowning
in thousands of low-value detections, muting the noisy ones — and muting is exactly how the real
attack slips through. More rules didn't help. **Better** rules did.

Here's the detection-engineering discipline that turns a noisy SOC into an effective one.

## Fidelity over volume

A detection that fires 500 times a day and gets ignored protects nothing. The goal isn't coverage
of every conceivable event — it's **high-fidelity signal that an analyst will actually act on.**

Take a simple example. "Failed login" is noise. But **"one source IP failing logins across many
accounts, then a successful login from that same IP"** is a password-spray-to-compromise story — and
it's specific enough to warrant immediate action. In Microsoft Sentinel:

```kql
let failures = SigninLogs
  | where ResultType == "50126"          // invalid credentials
  | summarize FailedCount = count(), TargetedUsers = dcount(UserPrincipalName)
    by IPAddress, bin(TimeGenerated, 1h)
  | where FailedCount >= 10 and TargetedUsers >= 5;
failures
| join kind=inner (
    SigninLogs | where ResultType == "0"
    | project SuccessTime = TimeGenerated, IPAddress, UserPrincipalName
  ) on IPAddress
| where SuccessTime > TimeGenerated
```

That's not "someone typed a wrong password." That's "an adversary sprayed the tenant and got in."
One is noise; the other gets a call at 2 a.m.

## Map every detection to MITRE ATT&CK

If you can't say *which adversary technique* a rule covers, you can't see your gaps. Mapping
detections to **MITRE ATT&CK** turns a pile of rules into a coverage map: you can point at the tactics
and techniques you detect, and — more importantly — the ones you don't. Blind spots should be
visible on a dashboard, not discovered during an incident.

## Tune relentlessly, and measure it

A rule is never "done." Track **false-positive rate** per detection and treat a high FP% as a bug.
Allow-list known-good sources (VPN egress, vulnerability scanners, service accounts), raise
thresholds for large tenants, and revisit the noisiest rules every sprint. The metric that matters:
are analysts acting on alerts, or muting them?

## Every alert needs an owner and a runbook

Detection without response is theatre. Each detection should link to a **response playbook** — what
to check, how to contain, who to notify. When the password-spray rule fires, the analyst shouldn't be
improvising; they should be executing the compromised-account playbook: revoke sessions, reset
credentials, re-register MFA, hunt for persistence (inbox rules, OAuth grants, new MFA methods).

## Test your detections before you trust them

Would your rules actually catch the attack? Don't assume — **validate**. Use atomic tests or a
purple-team exercise to fire the technique and confirm the detection triggers. A rule that looks
right but never fires on the real behavior is worse than no rule, because it creates false comfort.

## The takeaway

Good detection engineering is a loop: **write a high-fidelity rule → map it to ATT&CK → pair it with a
runbook → measure its false-positive rate → tune → test.** Do that consistently and your SOC stops
drowning in alerts and starts catching what matters. The win isn't 10,000 detections — it's the
handful that fire only when something is genuinely wrong, and the muscle memory to respond.

---

*I write about SOC operations, detection engineering, and incident response. Connect with me on
[LinkedIn](https://www.linkedin.com/in/naz-cyber-solutions).*
