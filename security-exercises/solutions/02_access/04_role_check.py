"""Apply a least-privilege role check."""


def can_access(
    user_roles: dict[str, set[str]], username: str, required_role: str
) -> bool:
    """Return whether the named user has exactly the required capability."""
    return required_role in user_roles.get(username, set())


if __name__ == "__main__":
    roles = {"ada": {"reader"}, "lin": {"reader", "editor"}}
    assert can_access(roles, "lin", "editor")
    assert not can_access(roles, "ada", "editor")
    assert not can_access(roles, "missing", "reader")
