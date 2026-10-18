"""Detect that a file changed, the only honest way to use a hash here."""

import hashlib
import re
from pathlib import Path

HEX64 = re.compile(r"^[0-9a-f]{64}$")


def digest(path: Path) -> str:
    """Return the SHA-256 hex digest of a file, reading it in chunks."""
    hasher = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65_536), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def verify(path: Path, expected: str) -> bool:
    """True only when the file matches the digest exactly (case-insensitive)."""
    normalised = expected.strip().lower()
    if not HEX64.match(normalised):
        raise ValueError("expected digest must be 64 hex characters")
    return digest(path) == normalised


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
