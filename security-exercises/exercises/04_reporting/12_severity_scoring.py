"""Score a finding with a rule you can defend in a review meeting."""

IMPACT = {"low": 1, "moderate": 2, "high": 3, "complete": 4}


def score(finding: dict) -> str:
    """Return low/medium/high/critical from reachable, impact, auth_required."""
    raise NotImplementedError("Validate the keys, then apply a written rule")


def rank(findings: list[dict]) -> list[str]:
    """Titles ordered worst first; ties broken by title."""
    raise NotImplementedError("Sort by score then title")


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
