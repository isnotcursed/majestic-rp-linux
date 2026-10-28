from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from majestic_linux.core.config import RunnerConfig, load_config
from majestic_linux.core.config_parser import parse_shell_config


class ConfigParserTests(unittest.TestCase):
    def test_paths_and_device_names_keep_spaces(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            config_path = Path(directory) / "runner.conf"
            config_path.write_text(
                'PROTON_PATH="/games/Steam/Proton - Experimental/proton"\n'
                'MAJESTIC_GPU_DEVICE_NAME="Example Vendor Discrete GPU 1234"\n',
                encoding="utf-8",
            )
            values = parse_shell_config(config_path)
            self.assertEqual(
                values["PROTON_PATH"],
                "/games/Steam/Proton - Experimental/proton",
            )
            self.assertEqual(
                values["MAJESTIC_GPU_DEVICE_NAME"],
                "Example Vendor Discrete GPU 1234",
            )

    def test_safe_defaults_do_not_download_an_installer(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            config_path = Path(directory) / "runner.conf"
            config_path.write_text("MAJESTIC_INSTALLER_URL=\n", encoding="utf-8")
            config = load_config(config_path)
            self.assertEqual(config.installer_url, "")
            self.assertIsNone(config.installer_path)

        default = RunnerConfig(config_path=Path("runner.conf"))
        self.assertEqual(default.installer_url, "")


if __name__ == "__main__":
    unittest.main()
