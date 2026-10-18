"""Check an HTTPS URL against an explicit, exact hostname allowlist."""

from urllib.parse import urlsplit


def is_authorized_target(url: str, allowed_hosts: set[str]) -> bool:
    """Return True only for an HTTPS URL whose hostname is explicitly allowed."""
    try:
        parsed = urlsplit(url)
        hostname = parsed.hostname
    except ValueError:
        return False
    normalized_allowlist = {host.strip().lower().rstrip(".") for host in allowed_hosts}
    return (
        parsed.scheme.lower() == "https"
        and hostname is not None
        and parsed.username is None
        and parsed.password is None
        and hostname.lower().rstrip(".") in normalized_allowlist
    )


if __name__ == "__main__":
    allowed = {"training.example"}
    assert is_authorized_target("https://training.example/lab", allowed)
    assert is_authorized_target("https://TRAINING.EXAMPLE./lab", allowed)
    assert not is_authorized_target("http://training.example/lab", allowed)
    assert not is_authorized_target("https://training.example.attacker.test", allowed)
    assert not is_authorized_target("https://other.example", allowed)
    assert not is_authorized_target("https://user@training.example", allowed)
