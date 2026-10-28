#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
ROOT="$(repository_root)"
VERSION="$(package_version "$ROOT")"
RELEASE="${PACKAGE_RELEASE:-1}"
RPM_ROOT="$ROOT/build/rpm"
SOURCE_ROOT="$RPM_ROOT/source"
TOPDIR="$RPM_ROOT/rpmbuild"
OUTPUT_DIR="$ROOT/dist-packages"

rm -rf -- "$RPM_ROOT"
mkdir -p "$SOURCE_ROOT" "$TOPDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS} "$OUTPUT_DIR"
install_shared_files "$ROOT" "$SOURCE_ROOT"
tar -C "$SOURCE_ROOT" -czf "$TOPDIR/SOURCES/majestic-linux-runner-root.tar.gz" .

cat > "$TOPDIR/SPECS/majestic-linux-runner.spec" <<EOF
Name:           majestic-linux-runner
Version:        $VERSION
Release:        $RELEASE%{?dist}
Summary:        Majestic RP runner for Proton
License:        MIT
URL:            https://github.com/isnotcursed/majestic-rp-linux
Source0:        majestic-linux-runner-root.tar.gz
BuildArch:      noarch
Requires:       bash
Requires:       nodejs
Requires:       python3 >= 3.11

%description
Prepares a Proton prefix, installs Majestic Launcher and patches app.asar for Linux.

%prep
%setup -q -c -T

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}

%files
%{_bindir}/majestic-linux
%{_bindir}/asar
%{_prefix}/lib/majestic-linux-runner/
%{_datadir}/applications/io.github.isnotcursed.majestic-linux-runner.desktop
%{_datadir}/icons/hicolor/scalable/apps/majestic-linux.svg
%{_datadir}/metainfo/io.github.isnotcursed.majestic-linux-runner.metainfo.xml
%{_docdir}/majestic-linux-runner/

%changelog
* Wed Oct 28 2026 GPT-5.6 Sol <gpt-5.6-sol@openai.com> - $VERSION-$RELEASE
- Build DEB, RPM and AppImage release artifacts
EOF

rpmbuild --define "_topdir $TOPDIR" -bb "$TOPDIR/SPECS/majestic-linux-runner.spec"
RPM_FILE="$(find "$TOPDIR/RPMS" -type f -name '*.rpm' -print -quit)"
[[ -n "$RPM_FILE" ]] || { printf 'RPM was not built\n' >&2; exit 1; }
cp -- "$RPM_FILE" "$OUTPUT_DIR/"
OUTPUT="$OUTPUT_DIR/$(basename "$RPM_FILE")"
rpm -qip "$OUTPUT"
rpm -qlp "$OUTPUT" >/dev/null
rpm -qpR "$OUTPUT" | grep -Fx nodejs >/dev/null
rpm -qpR "$OUTPUT" | grep -F 'python3 >= 3.11' >/dev/null
SMOKE_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$SMOKE_ROOT"' EXIT
(cd "$SMOKE_ROOT" && rpm2cpio "$OUTPUT" | cpio -id --quiet)
"$SMOKE_ROOT/usr/bin/majestic-linux" setup --help >/dev/null
rm -rf -- "$SMOKE_ROOT"
trap - EXIT
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
printf 'Built %s\n' "$OUTPUT"
