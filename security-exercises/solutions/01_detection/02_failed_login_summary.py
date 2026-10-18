"""Summarize repeated failed logins in synthetic training events."""


def repeated_failed_users(
    events: list[tuple[str, str]], threshold: int
) -> dict[str, int]:
    """Return usernames whose failed-event count reaches threshold."""
    if threshold < 1:
        raise ValueError("threshold must be positive")
    counts: dict[str, int] = {}
    for username, status in events:
        if username and status == "failed":
            counts[username] = counts.get(username, 0) + 1
    return {
        username: count
        for username, count in sorted(counts.items())
        if count >= threshold
    }


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
