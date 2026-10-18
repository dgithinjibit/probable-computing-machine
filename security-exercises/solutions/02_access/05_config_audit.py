"""Find missing or unsafe security settings in a fictional service config."""

REQUIRED_SETTINGS = {
    "mfa": True,
    "disk_encryption": True,
    "backup_restore_tested": True,
    "public_admin": False,
}


def unsafe_settings(config: dict[str, object]) -> list[str]:
    """Return sorted names of required settings that are not safely configured."""
    return sorted(
        name for name, required in REQUIRED_SETTINGS.items()
        if config.get(name) is not required
    )


if __name__ == "__main__":
    safe = {
        "mfa": True,
        "disk_encryption": True,
        "backup_restore_tested": True,
        "public_admin": False,
    }
    assert unsafe_settings(safe) == []
    assert unsafe_settings({"mfa": False, "public_admin": True}) == [
        "backup_restore_tested", "disk_encryption", "mfa", "public_admin"
    ]
