"""Prioritize fictional findings using impact and exposure context."""


def triage_finding(severity: str, internet_exposed: bool, sensitive_data: bool) -> str:
    """Return low, medium, high, or critical as a remediation priority."""
    levels = {"low": 1, "medium": 2, "high": 3, "critical": 4}
    if severity not in levels:
        raise ValueError("severity must be low, medium, high, or critical")
    if severity == "critical":
        return "critical"
    score = levels[severity] + int(internet_exposed) + int(sensitive_data)
    return "critical" if score >= 5 else "high" if score >= 4 else "medium" if score >= 2 else "low"


if __name__ == "__main__":
    assert triage_finding("critical", False, False) == "critical"
    assert triage_finding("high", True, False) == "high"
    assert triage_finding("medium", True, True) == "high"
    assert triage_finding("low", False, False) == "low"
    try:
        triage_finding("unknown", False, False)
    except ValueError:
        pass
    else:
        raise AssertionError("unknown severity should be rejected")
