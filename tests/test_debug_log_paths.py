from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from majestic_linux.runtime.debug_logs import debug_log_root, start_debug_log_session


class DebugLogPathTests(unittest.TestCase):
    def test_xdg_state_home_is_used_instead_of_working_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with patch.dict(os.environ, {"XDG_STATE_HOME": directory}):
                session = start_debug_log_session()
            self.assertEqual(session.root, Path(directory) / "majestic-runner" / "logs")
            self.assertTrue(session.path("system.log").is_file())

    def test_custom_log_directory_is_respected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "custom"
            session = start_debug_log_session(log_directory=root)
            self.assertEqual(session.root, root / "logs")

    def test_default_uses_user_state_directory(self) -> None:
        with patch.dict(os.environ, {"XDG_STATE_HOME": ""}):
            self.assertEqual(debug_log_root(), Path.home() / ".local" / "state" / "majestic-runner" / "logs")


if __name__ == "__main__":
    unittest.main()
