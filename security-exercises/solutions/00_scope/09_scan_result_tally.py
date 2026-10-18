"""Tally synthetic scan output the way a report needs it.

Data is fictional and already collected; nothing here touches a network.
"""

STATES = {"open", "closed", "filtered", "unresponsive"}


def _check(results: list[tuple[str, int, str]]) -> None:
    for host, port, state in results:
        if not isinstance(host, str) or not host:
            raise ValueError("host must be a non-empty string")
        if not isinstance(port, int) or not 1 <= port <= 65535:
            raise ValueError(f"port out of range: {port}")
        if state not in STATES:
            raise ValueError(f"unknown state: {state}")


def tally(results: list[tuple[str, int, str]]) -> dict[str, int]:
    """Count results by state, rejecting an unknown state or a bad port."""
    _check(results)
    counts: dict[str, int] = {}
    for _, _, state in results:
        counts[state] = counts.get(state, 0) + 1
    return dict(sorted(counts.items()))


def open_services(results: list[tuple[str, int, str]]) -> list[str]:
    """Return "host:port" for open results, sorted, without duplicates."""
    _check(results)
    return sorted({f"{host}:{port}" for host, port, state in results if state == "open"})


if __name__ == "__main__":
    rows = [("10.0.0.5", 22, "open"), ("10.0.0.5", 22, "open"),
            ("10.0.0.5", 3389, "filtered"), ("10.0.0.9", 80, "open"),
            ("10.0.0.9", 443, "closed")]
    assert tally(rows) == {"closed": 1, "filtered": 1, "open": 3}
    assert open_services(rows) == ["10.0.0.5:22", "10.0.0.9:80"]
    assert tally([]) == {}
    assert open_services([]) == []
    try:
        tally([("10.0.0.5", 80, "exploitable")])
    except ValueError:
        pass
    else:
        raise AssertionError("unknown state must be rejected")
    try:
        tally([("10.0.0.5", 70000, "open")])
    except ValueError:
        pass
    else:
        raise AssertionError("port must be 1-65535")
