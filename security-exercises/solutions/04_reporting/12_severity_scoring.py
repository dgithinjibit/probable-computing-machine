"""Score a finding with a rule you can defend in a review meeting."""

IMPACT = {"low": 1, "moderate": 2, "high": 3, "complete": 4}
ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3}


def _level(reachable: bool, impact: str, auth_required: bool) -> str:
    value = IMPACT[impact]
    if reachable and impact == "complete" and not auth_required:
        return "critical"
    if reachable and not auth_required:
        return "high" if value >= 3 else "medium"
    if reachable and auth_required and value >= 3:
        return "high"
    if auth_required and value <= 1:
        return "low"
    return "medium"


def score(finding: dict) -> str:
    """Return low/medium/high/critical from reachable, impact, auth_required."""
    for key in ("title", "reachable", "impact", "auth_required"):
        if key not in finding:
            raise ValueError(f"finding is missing {key!r}")
    if finding["impact"] not in IMPACT:
        raise ValueError(f"unknown impact: {finding['impact']}")
    if not isinstance(finding["reachable"], bool) or not isinstance(
        finding["auth_required"], bool
    ):
        raise ValueError("reachable and auth_required must be booleans")
    return _level(finding["reachable"], finding["impact"], finding["auth_required"])


def rank(findings: list[dict]) -> list[str]:
    """Titles ordered worst first; ties broken by title."""
    return sorted(
        (f["title"] for f in findings),
        key=lambda title: (ORDER[score(next(f for f in findings if f["title"] == title))],
                           title),
    )


if __name__ == "__main__":
    assert score({"title": "RCE", "reachable": True, "impact": "complete",
                  "auth_required": False}) == "critical"
    assert score({"title": "Unauth listing", "reachable": True, "impact": "low",
                  "auth_required": False}) == "medium"
    assert score({"title": "Stale banner", "reachable": False, "impact": "low",
                  "auth_required": True}) == "low"
    assert score({"title": "Auth-only leak", "reachable": True, "impact": "high",
                  "auth_required": True}) == "high"
    assert rank([{"title": "b", "reachable": True, "impact": "low",
                  "auth_required": False},
                 {"title": "a", "reachable": True, "impact": "complete",
                  "auth_required": False}]) == ["a", "b"]
    try:
        score({"title": "x", "reachable": True, "impact": "wow",
               "auth_required": False})
    except ValueError:
        pass
    else:
        raise AssertionError("unknown impact must be rejected")
