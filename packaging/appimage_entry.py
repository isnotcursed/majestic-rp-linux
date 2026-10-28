from majestic_linux.app.cli import main
from majestic_linux.runtime.pyinstaller_env import restore_host_library_path


if __name__ == "__main__":
    restore_host_library_path()
    raise SystemExit(main())
