"""Check an HTTPS URL against an explicit, exact hostname allowlist."""


def is_authorized_target(url: str, allowed_hosts: set[str]) -> bool:
    """Return True only for an HTTPS URL whose hostname is explicitly allowed."""
    raise NotImplementedError("Parse the URL and compare its normalized hostname")


if __name__ == "__main__":
    allowed = {"training.example"}
    assert is_authorized_target("https://training.example/lab", allowed)
    assert not is_authorized_target("http://training.example/lab", allowed)
    assert not is_authorized_target("https://training.example.attacker.test", allowed)
    assert not is_authorized_target("https://other.example", allowed)
