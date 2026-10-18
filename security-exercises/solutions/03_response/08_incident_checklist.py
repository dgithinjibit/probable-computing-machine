"""Build a safe first-response checklist for a fictional account incident."""


def incident_checklist(account_compromised: bool, data_exposed: bool) -> list[str]:
    """Return ordered, defensive actions without probing or altering evidence."""
    steps = ["preserve relevant evidence", "notify the security owner"]
    if account_compromised:
        steps.append("contain the affected account")
    if data_exposed:
        steps.append("assess data exposure")
    steps.append("document decisions and times")
    return steps


if __name__ == "__main__":
    assert incident_checklist(True, True) == [
        "preserve relevant evidence",
        "notify the security owner",
        "contain the affected account",
        "assess data exposure",
        "document decisions and times",
    ]
    assert incident_checklist(False, False) == [
        "preserve relevant evidence",
        "notify the security owner",
        "document decisions and times",
    ]
