from __future__ import annotations

import os
import sys
from collections.abc import MutableMapping


def restore_host_library_path(
    environment: MutableMapping[str, str] | None = None,
    *,
    frozen: bool | None = None,
) -> bool:
    """Undo PyInstaller's Linux loader override before spawning host tools."""
    env = os.environ if environment is None else environment
    is_frozen = bool(getattr(sys, "frozen", False)) if frozen is None else frozen
    if not is_frozen:
        return False

    original = env.pop("LD_LIBRARY_PATH_ORIG", None)
    if original:
        env["LD_LIBRARY_PATH"] = original
    else:
        env.pop("LD_LIBRARY_PATH", None)
    return True
