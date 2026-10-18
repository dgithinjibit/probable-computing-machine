"""Detect that a file changed, the only honest way to use a hash here."""

import hashlib
from pathlib import Path


def digest(path: Path) -> str:
    """Return the SHA-256 hex digest of a file, reading it in chunks."""
    raise NotImplementedError("Stream the file instead of loading it whole")


def verify(path: Path, expected: str) -> bool:
    """True only when the file matches the digest exactly (case-insensitive)."""
    raise NotImplementedError("Normalise case and compare")


if __name__ == "__main__":
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        target = Path(tmp) / "firmware.bin"
        target.write_bytes(b"bootloader v1")
        first = digest(target)
        assert len(first) == 64 and int(first, 16) >= 0
        assert verify(target, first)
        assert verify(target, first.upper())
        target.write_bytes(b"bootloader v2")
        assert not verify(target, first)
        assert digest(target) != first
        try:
            verify(target, "nothex")
        except ValueError:
            pass
        else:
            raise AssertionError("malformed digest must be rejected")
