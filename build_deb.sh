#!/bin/bash
set -euo pipefail

# Fehler abfangen, damit das Terminal offen bleibt
#trap 'echo; echo "❌ Build abgebrochen!"; read -rp "Enter drücken zum Schließen..."' ERR
trap 'echo; echo "❌ Build abgebrochen!"; read -rp "Enter drücken zum Schließen..."' ERR

# --------------------------------------------------
# Verzeichnisse
# --------------------------------------------------

BASE="/Nas/git/piext"
PKG="$BASE/piext_pkg"
OUTDIR="$BASE/bin"
WINSETUP="PiExtRestorer_Setup.exe"

# Linux
SRC_BIN="$BASE/piext-Lin/source/piext"
HELP_DE="$BASE/piext-Lin/source/PiExt_de.html"
HELP_EN="$BASE/piext-Lin/source/PiExt_en.html"
ICON="$BASE/piext-Lin/source/piext128.png"

# Windows
WIN_SETUP="$BASE/piext-Win/source/Output/PiExtRestorer_Setup.exe"

# --------------------------------------------------
# Version abfragen
# --------------------------------------------------

read -rp "Bitte Version eingeben (z.B. 1.0.0): " version

if [ -z "$version" ]; then
    echo "❌ Keine Version eingegeben!"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

echo
echo "🚀 Build PiExt Release"
echo "Version: v$version"
echo

# --------------------------------------------------
# Dateien prüfen
# --------------------------------------------------

check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ Datei nicht gefunden:"
        echo "$1"
        read -rp "Enter drücken zum Schließen..."
        exit 1
    fi
}

check_file "$SRC_BIN"
check_file "$HELP_DE"
check_file "$HELP_EN"
check_file "$ICON"
check_file "$WIN_SETUP"

# --------------------------------------------------
# Ausgabe-Verzeichnis
# --------------------------------------------------

mkdir -p "$OUTDIR"

# Version für den Updater schreiben
echo "v$version" > "$OUTDIR/version.txt"

# --------------------------------------------------
# Alte Builds entfernen
# --------------------------------------------------

rm -rf "$PKG"

rm -f "$OUTDIR/piext.deb"
rm -f "$OUTDIR/$WINSETUP"

# --------------------------------------------------
# Windows Installer übernehmen
# --------------------------------------------------

echo "📦 Übernehme Windows Installer..."

install -m644 "$WIN_SETUP" \
    "$OUTDIR/$WINSETUP"

# --------------------------------------------------
# Linux Paketstruktur
# --------------------------------------------------

mkdir -p "$PKG/DEBIAN"
mkdir -p "$PKG/usr/lib/piext"
mkdir -p "$PKG/usr/bin"
mkdir -p "$PKG/usr/share/applications"
mkdir -p "$PKG/usr/share/icons/hicolor/256x256/apps"

# --------------------------------------------------
# Binary
# --------------------------------------------------

install -Dm755 "$SRC_BIN" \
    "$PKG/usr/lib/piext/piext"

# --------------------------------------------------
# CLI-Befehl
# --------------------------------------------------

cat > "$PKG/usr/bin/piext" <<'EOF'
#!/bin/bash

export XDG_RUNTIME_DIR="/tmp/runtime-root"

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

exec /usr/lib/piext/piext "$@"
EOF

chmod 755 "$PKG/usr/bin/piext"

# --------------------------------------------------
# HTML-Hilfe
# --------------------------------------------------

install -Dm644 "$HELP_DE" \
    "$PKG/usr/lib/piext/piext_de.html"

install -Dm644 "$HELP_EN" \
    "$PKG/usr/lib/piext/piext_en.html"

# --------------------------------------------------
# Desktop Entry
# --------------------------------------------------

cat > "$PKG/usr/share/applications/piext.desktop" <<EOF
[Desktop Entry]
Name=PiExt
Comment=EXT2/EXT3/EXT4 Image Backup and Restore Tool
Exec=sudo /usr/lib/piext/piext
Icon=piext
Terminal=false
Type=Application
Categories=Utility;System;
EOF

# --------------------------------------------------
# Icon
# --------------------------------------------------

install -Dm644 "$ICON" \
    "$PKG/usr/share/icons/hicolor/256x256/apps/piext.png"

# --------------------------------------------------
# Debian Control-Datei
# --------------------------------------------------

cat > "$PKG/DEBIAN/control" <<EOF
Package: piext
Version: $version
Section: utils
Priority: optional
Architecture: arm64
Maintainer: RaspberryFpc
Depends: zstd, e2fsprogs, sudo, libqt5pas1
Description: PiExt - EXT partition image backup and restore tool
 Creates and restores compressed images of Linux EXT2, EXT3 and EXT4 partitions.
EOF

# --------------------------------------------------
# Debian-Paket erstellen
# --------------------------------------------------

echo
echo "📦 Erstelle Debian-Paket..."

TMP_BUILD=$(mktemp -d)

cp -a "$PKG/." "$TMP_BUILD/"

dpkg-deb --build --root-owner-group \
    "$TMP_BUILD" \
    "$OUTDIR/piext.deb"

# Temporäres Verzeichnis entfernen
rm -rf "$TMP_BUILD"

# --------------------------------------------------
# Ergebnis prüfen
# --------------------------------------------------

if [ ! -f "$OUTDIR/piext.deb" ]; then
    echo "❌ Debian-Paket wurde nicht erzeugt!"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

if [ ! -f "$OUTDIR/$WINSETUP" ]; then
    echo "❌ Windows Installer wurde nicht übernommen!"
    read -rp "Enter drücken zum Schließen..."
    exit 1
fi

# --------------------------------------------------
# Fertig
# --------------------------------------------------

echo
echo "========================================"
echo "✅ Release erfolgreich erstellt!"
echo "========================================"
echo
echo "Version: v$version"
echo
echo "Release-Dateien:"
echo
ls -lh \
    "$OUTDIR/piext.deb" \
    "$OUTDIR/$WINSETUP" \
    "$OUTDIR/version.txt"

echo
read -rp "Enter drücken zum Schließen..."

