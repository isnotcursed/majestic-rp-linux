from __future__ import annotations

import unittest

from majestic_linux.runtime.pyinstaller_env import restore_host_library_path


class PyInstallerEnvironmentTests(unittest.TestCase):
    def test_frozen_app_restores_original_library_path(self) -> None:
        environment = {
            "LD_LIBRARY_PATH": "/tmp/_MEI12345",
            "LD_LIBRARY_PATH_ORIG": "/usr/local/lib:/opt/lib",
        }

        changed = restore_host_library_path(environment, frozen=True)

        self.assertTrue(changed)
        self.assertEqual(environment["LD_LIBRARY_PATH"], "/usr/local/lib:/opt/lib")
        self.assertNotIn("LD_LIBRARY_PATH_ORIG", environment)

    def test_frozen_app_removes_override_when_host_had_no_library_path(self) -> None:
        environment = {"LD_LIBRARY_PATH": "/tmp/_MEI12345"}

        restore_host_library_path(environment, frozen=True)

        self.assertNotIn("LD_LIBRARY_PATH", environment)

    def test_source_install_does_not_change_environment(self) -> None:
        environment = {
            "LD_LIBRARY_PATH": "/custom/lib",
            "LD_LIBRARY_PATH_ORIG": "/original/lib",
        }

        changed = restore_host_library_path(environment, frozen=False)

        self.assertFalse(changed)
        self.assertEqual(environment["LD_LIBRARY_PATH"], "/custom/lib")
        self.assertEqual(environment["LD_LIBRARY_PATH_ORIG"], "/original/lib")


if __name__ == "__main__":
    unittest.main()
