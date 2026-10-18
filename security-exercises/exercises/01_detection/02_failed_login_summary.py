"""Summarize repeated failed logins in synthetic training events."""


def repeated_failed_users(
    events: list[tuple[str, str]], threshold: int
) -> dict[str, int]:
    """Return usernames whose failed-event count reaches threshold."""
    raise NotImplementedError("Count only failed events and validate the threshold")


if __name__ == "__main__":
    events = [("alex", "failed"), ("alex", "failed"), ("sam", "success")]
    assert repeated_failed_users(events, 2) == {"alex": 2}
    assert repeated_failed_users(events, 3) == {}
    try:
        repeated_failed_users(events, 0)
    except ValueError:
        pass
    else:
        raise AssertionError("threshold must be positive")
