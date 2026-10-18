"""Tally synthetic scan output the way a report needs it.

Data is fictional and already collected; nothing here touches a network.
"""


def tally(results: list[tuple[str, int, str]]) -> dict[str, int]:
    """Count results by state, rejecting an unknown state or a bad port."""
    raise NotImplementedError("Validate the port range and the allowed states")


def open_services(results: list[tuple[str, int, str]]) -> list[str]:
    """Return "host:port" for open results, sorted, without duplicates."""
    raise NotImplementedError("Sort and de-duplicate")


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
