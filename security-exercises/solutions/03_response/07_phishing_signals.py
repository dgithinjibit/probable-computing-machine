"""Identify common warning signs in a fictional message."""


def phishing_signals(
    sender_domain: str, expected_domain: str, message: str
) -> list[str]:
    """Return a stable list of mismatch, urgency, and credential-request cues."""
    text = message.casefold()
    signals: list[str] = []
    if sender_domain.casefold().rstrip(".") != expected_domain.casefold().rstrip("."):
        signals.append("domain_mismatch")
    if any(word in text for word in ("urgent", "immediately", "act now")):
        signals.append("urgency")
    if any(word in text for word in ("password", "verify your account", "login details")):
        signals.append("credential_request")
    return signals


if __name__ == "__main__":
    signals = phishing_signals(
        "billing.invalid", "example.test", "Urgent: verify your password immediately"
    )
    assert signals == ["domain_mismatch", "urgency", "credential_request"]
    assert phishing_signals("example.test", "example.test", "Meeting at noon") == []
