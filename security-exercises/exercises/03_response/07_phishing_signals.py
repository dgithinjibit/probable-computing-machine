"""Identify common warning signs in a fictional message."""


def phishing_signals(
    sender_domain: str, expected_domain: str, message: str
) -> list[str]:
    """Return a stable list of mismatch, urgency, and credential-request cues."""
    raise NotImplementedError("Check sender mismatch and suspicious message language")


if __name__ == "__main__":
    signals = phishing_signals(
        "billing.invalid", "example.test", "Urgent: verify your password immediately"
    )
    assert signals == ["domain_mismatch", "urgency", "credential_request"]
    assert phishing_signals("example.test", "example.test", "Meeting at noon") == []
