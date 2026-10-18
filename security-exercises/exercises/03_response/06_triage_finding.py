"""Prioritize fictional findings using impact and exposure context."""


def triage_finding(severity: str, internet_exposed: bool, sensitive_data: bool) -> str:
    """Return low, medium, high, or critical as a remediation priority."""
    raise NotImplementedError("Combine the base severity with the two risk factors")


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
