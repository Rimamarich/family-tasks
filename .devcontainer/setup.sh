#!/usr/bin/env bash

set -euo pipefail

echo
echo "========================================"
echo " Family Tasks — Setup environnement"
echo "========================================"
echo

# ------------------------------------------------------------
# 1. Flutter
# ------------------------------------------------------------

if [ ! -x /home/codespace/flutter/bin/flutter ]; then
  echo "→ Installation de Flutter 3.44.9..."
  git clone --depth 1 --branch 3.44.9 \
    https://github.com/flutter/flutter.git \
    /home/codespace/flutter
  echo "✓ Flutter installé"
else
  echo "✓ Flutter déjà présent"
fi

# ------------------------------------------------------------
# 2. SDK Android
# ------------------------------------------------------------

ANDROID_SDK="/home/codespace/android-sdk"
CMDLINE_TOOLS="$ANDROID_SDK/cmdline-tools/latest"
TOOLS_ZIP="/tmp/cmdline-tools.zip"

if [ ! -d "$CMDLINE_TOOLS" ]; then
  echo "→ Installation du SDK Android..."

  mkdir -p "$ANDROID_SDK"

  # Télécharge les command-line tools
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    -O "$TOOLS_ZIP"

  # Extrait dans un dossier temporaire
  mkdir -p /tmp/android-cmdline
  unzip -q "$TOOLS_ZIP" -d /tmp/android-cmdline

  # Déplace dans la structure attendue
  mkdir -p "$ANDROID_SDK/cmdline-tools"
  mv /tmp/android-cmdline/cmdline-tools "$CMDLINE_TOOLS"

  # Nettoie
  rm -rf /tmp/android-cmdline "$TOOLS_ZIP"

  echo "✓ Command-line tools installés"
else
  echo "✓ SDK Android déjà présent"
fi

# ------------------------------------------------------------
# 3. Composants Android (platform-tools, platforms, build-tools)
# ------------------------------------------------------------

export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="$CMDLINE_TOOLS/bin:$ANDROID_SDK/platform-tools:$PATH"

if [ ! -d "$ANDROID_SDK/platform-tools" ]; then
  echo "→ Installation des composants Android..."
  yes | sdkmanager --licenses >/dev/null 2>&1 || true
  sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" >/dev/null
  echo "✓ Composants Android installés"
else
  echo "✓ Composants Android déjà présents"
fi

# ------------------------------------------------------------
# 4. Précache Flutter pour Android
# ------------------------------------------------------------

echo "→ Précache Flutter pour Android..."
/home/codespace/flutter/bin/flutter precache --android >/dev/null
echo "✓ Flutter prêt pour Android"

echo
echo "========================================"
echo " ✓ Environnement prêt"
echo "========================================"
echo