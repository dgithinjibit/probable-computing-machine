"""Render findings as a report a stranger can act on."""


def render(findings: list[dict], engagement: dict) -> str:
    """Markdown report: scope evidence first, then findings worst to least."""
    raise NotImplementedError("Refuse to render without authorization evidence")


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
