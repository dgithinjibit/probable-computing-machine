"""Refuse to build SQL from strings that were never approved.

The lesson is the refusal, not the query.
"""

ALLOWED_TABLES = {"readings", "devices", "findings"}
ALLOWED_COLUMNS = {"device_id", "recorded_at", "value", "severity"}


def safe_query(table: str, column: str, value: object) -> tuple[str, tuple]:
    """Return a parameterised (sql, params) pair, rejecting unknown names."""
    raise NotImplementedError("Check both names against the allow-lists first")


if __name__ == "__main__":
    sql, params = safe_query("readings", "device_id", 7)
    assert sql == "SELECT * FROM readings WHERE device_id = ?"
    assert params == (7,)
    try:
        safe_query("users; DROP TABLE readings", "device_id", 7)
    except ValueError:
        pass
    else:
        raise AssertionError("unlisted table must be rejected")
    try:
        safe_query("readings", "value = 1 OR 1=1 --", 7)
    except ValueError:
        pass
    else:
        raise AssertionError("unlisted column must be rejected")
