# Defensive security exercises

Original, offline programming challenges inspired by the local penetration
testing, secure-software, and cybersecurity-psychology reading. They focus on
authorization boundaries, synthetic log review, secret redaction, least
privilege, configuration checks, risk triage, phishing awareness, and incident
response.

All data is fictional. The exercises make no network connections, scan no
systems, and include no exploit or credential-collection tooling. Only test
systems you own or have explicit written permission to assess; these exercises
do not authorize testing real targets.

Edit a starter and run it from the exercises root, for example:

```sh
python3 security-exercises/exercises/00_scope/01_authorized_target.py
```

Answers and their assertions are in matching `solutions/` files. Verify all
answers with:

```sh
python3 security-exercises/run_tests.py
```

The track uses only Python's standard library and is not an mdBook. The
exercises are independently written and use the books only for high-level
topic direction; no passages, examples, or offensive procedures are copied.
See the exercises-root [README](../README.md) for local course books and the
combined portal.

## Exercise path

| # | Exercise | Defensive skill |
| --- | --- | --- |
| 01 | [Authorized target check](exercises/00_scope/01_authorized_target.py) | Exact HTTPS allowlist; no network activity |
| 02 | [Failed-login summary](exercises/01_detection/02_failed_login_summary.py) | Detection using synthetic events |
| 03 | [Redact secrets](exercises/01_detection/03_redact_secrets.py) | Safe log sharing |
| 04 | [Role check](exercises/02_access/04_role_check.py) | Least-privilege authorization |
| 05 | [Configuration audit](exercises/02_access/05_config_audit.py) | Secure defaults and resilience |
| 06 | [Triage a finding](exercises/03_response/06_triage_finding.py) | Risk-based remediation priority |
| 07 | [Phishing signals](exercises/03_response/07_phishing_signals.py) | Human-centered awareness cues |
| 08 | [Incident checklist](exercises/03_response/08_incident_checklist.py) | Evidence-preserving first response |
