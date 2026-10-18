"""Redact credential-like values from synthetic logs before sharing them."""


def redact_secrets(text: str) -> str:
    """Mask values following password=, token=, or api_key= labels."""
    raise NotImplementedError("Use a case-insensitive regular expression")


if __name__ == "__main__":
    assert redact_secrets("user=ada token=abc123") == "user=ada token=[REDACTED]"
    assert redact_secrets("api_key=qwerty&mode=test") == "api_key=[REDACTED]&mode=test"
    assert redact_secrets("no credentials here") == "no credentials here"
