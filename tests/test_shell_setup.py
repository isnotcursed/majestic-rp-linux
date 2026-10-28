from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
WRAPPER = REPOSITORY_ROOT / "install-and-run-majestic-proton.sh"


class ShellSetupTests(unittest.TestCase):
    def test_local_installer_choice_writes_portable_config(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            installer = root / "Majestic Launcher Setup.exe"
            installer.write_bytes(b"MZ" + b"\0" * 1_048_576)
            config_home = root / "config"
            cache_home = root / "cache"
            env = {
                **os.environ,
                "XDG_CONFIG_HOME": str(config_home),
                "XDG_CACHE_HOME": str(cache_home),
            }

            result = subprocess.run(
                [str(WRAPPER), "setup", "--installer", str(installer)],
                cwd=REPOSITORY_ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)

            config = config_home / "majestic-runner" / "majestic-runner.conf"
            text = config.read_text(encoding="utf-8")
            self.assertIn("MAJESTIC_INSTALLER_URL=\n", text)
            self.assertIn(f'MAJESTIC_INSTALLER_PATH="{installer.resolve()}"', text)
            self.assertNotIn(str(Path.home()), text)

    def test_setup_requires_explicit_choice_without_terminal(self) -> None:
        result = subprocess.run(
            [str(WRAPPER), "setup"],
            cwd=REPOSITORY_ROOT,
            text=True,
            input="",
            capture_output=True,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--download", result.stderr)


if __name__ == "__main__":
    unittest.main()
