from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from majestic_linux.patching.api import patch_js_tree
from majestic_linux.patching.index import (
    MODERN_INDEX_MARKER,
    UPDATER_DISABLED_MARKER,
)
from majestic_linux.patching.common import MARKER


LAUNCHER_634_FIXTURE = '''
const s=A.isPackaged,e=s||process.env.SHOW_UPDATER==="1",t="latest";
class GameService {
  async play(){let n=this.deps.install.get();if(n===null)return;return n}
}
'''


class Launcher634PatchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        main = self.root / "out" / "main"
        main.mkdir(parents=True)
        (main / "index.js").write_text(LAUNCHER_634_FIXTURE, encoding="utf-8")
        (main / "patcherWorker.js").write_text(
            "process.parentPort.on('message', () => {});\n",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def test_launcher_634_patch_is_complete_and_idempotent(self) -> None:
        first = patch_js_tree(self.root, permissions="1")
        self.assertTrue(first.changed)

        index = (self.root / "out" / "main" / "index.js").read_text(encoding="utf-8")
        worker = (self.root / "out" / "main" / "patcherWorker.js").read_text(encoding="utf-8")
        self.assertEqual(index.count(UPDATER_DISABLED_MARKER), 1)
        self.assertEqual(index.count(MODERN_INDEX_MARKER), 1)
        self.assertEqual(worker.count(MARKER), 1)
        self.assertIn("let n=this.deps.install.get();", index)
        self.assertIn("n = { path: JO_PROTON_GTA_PATH", index)

        second = patch_js_tree(self.root, permissions="1")
        self.assertFalse(second.changed)

    def test_unknown_updater_layout_fails_closed(self) -> None:
        index_path = self.root / "out" / "main" / "index.js"
        index_path.write_text(
            "class GameService { async play(){let n=this.deps.install.get();return n} }",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(Exception, "updater gate"):
            patch_js_tree(self.root, permissions="1")


if __name__ == "__main__":
    unittest.main()
