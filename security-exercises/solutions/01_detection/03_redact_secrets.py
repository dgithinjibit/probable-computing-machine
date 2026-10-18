"""Redact credential-like values from synthetic logs before sharing them."""

import re


def redact_secrets(text: str) -> str:
    """Mask values following password=, token=, or api_key= labels."""
    pattern = re.compile(r"\b(password|token|api[_-]?key)\s*=\s*[^&\s]+", re.IGNORECASE)
    return pattern.sub(lambda match: f"{match.group(1)}=[REDACTED]", text)


if __name__ == "__main__":
    assert redact_secrets("user=ada token=abc123") == "user=ada token=[REDACTED]"
    assert redact_secrets("api_key=qwerty&mode=test") == "api_key=[REDACTED]&mode=test"
    assert redact_secrets("no credentials here") == "no credentials here"
