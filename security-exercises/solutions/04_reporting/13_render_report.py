"""Render findings as a report a stranger can act on."""

SEVERITY_ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3}
IMPACT = {"low": 1, "moderate": 2, "high": 3, "complete": 4}


def _score(finding: dict) -> str:
    value = IMPACT[finding["impact"]]
    if finding["reachable"] and finding["impact"] == "complete" and not finding["auth_required"]:
        return "critical"
    if finding["reachable"] and not finding["auth_required"]:
        return "high" if value >= 3 else "medium"
    if finding["reachable"] and finding["auth_required"] and value >= 3:
        return "high"
    if finding["auth_required"] and value <= 1:
        return "low"
    return "medium"


def render(findings: list[dict], engagement: dict) -> str:
    """Markdown report: scope evidence first, then findings worst to least."""
    if not engagement.get("authorized_by"):
        raise ValueError("refusing to render a report with no authorization evidence")
    if not engagement.get("scope"):
        raise ValueError("refusing to render a report with no in-scope assets")
    for finding in findings:
        if finding.get("impact") not in IMPACT:
            raise ValueError(f"unknown impact: {finding.get('impact')}")
        if not finding.get("remediation"):
            raise ValueError(f"finding {finding.get('title')!r} has no remediation")
        if not finding.get("evidence"):
            raise ValueError(f"finding {finding.get('title')!r} has no evidence")
    lines = [f"# Penetration test report: {engagement['client']}", ""]
    lines += ["## Authorization",
              f"- Authorized by: {engagement['authorized_by']}",
              f"- In scope: {', '.join(engagement['scope'])}",
              f"- Out of scope: {', '.join(engagement.get('out_of_scope', [])) or 'none stated'}",
              ""]
    ordered = sorted(findings, key=lambda f: (SEVERITY_ORDER[_score(f)], f["title"]))
    if not ordered:
        lines += ["## Findings", "", "No findings were recorded.", ""]
    for finding in ordered:
        lines += [f"## Finding: {finding['title']}",
                  f"- Severity: {_score(finding)}",
                  f"- Evidence: {finding['evidence']}",
                  f"- Remediation: {finding['remediation']}",
                  ""]
    return "\n".join(lines)


if __name__ == "__main__":
    engagement = {"client": "Acme Clinic", "authorized_by": "ops@acme.example",
                  "scope": ["10.0.0.0/24"], "out_of_scope": ["10.0.9.0/24"]}
    findings = [{"title": "Shared admin password", "reachable": True,
                 "impact": "complete", "auth_required": False,
                 "evidence": "hash matched a common list",
                 "remediation": "rotate and require MFA"}]
    text = render(findings, engagement)
    assert text.startswith("# Penetration test report: Acme Clinic")
    assert "## Authorization" in text and "ops@acme.example" in text
    assert "## Finding: Shared admin password" in text
    assert "rotate and require MFA" in text
    assert text.index("Out of scope") > text.index("## Authorization")
    try:
        render(findings, {"client": "x", "authorized_by": "", "scope": ["a"]})
    except ValueError:
        pass
    else:
        raise AssertionError("a report without authorization evidence is refused")
    try:
        render([{"title": "no fix", "reachable": True, "impact": "low",
                 "auth_required": False, "evidence": "e"}], engagement)
    except ValueError:
        pass
    else:
        raise AssertionError("every finding needs remediation")
