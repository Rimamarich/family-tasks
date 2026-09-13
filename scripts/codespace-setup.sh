#!/usr/bin/env bash

set -uo pipefail

# Family Tasks — Initialisation d'un nouveau Codespace
# Usage:
#   bash scripts/codespace-setup.sh
#
# À lancer une fois, juste après l'ouverture d'un nouveau Codespace sur
# la branche V1-chat. Regroupe les étapes de la page wiki
# "Si besoin de travailler dans un nouveau code space sur V1-chat".

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"

cd "$ROOT_DIR"

echo
echo "========================================"
echo " Family Tasks — Initialisation Codespace"
echo "========================================"
echo

ok()   { echo "✓ $1"; }
warn() { echo "⚠ $1"; }
fail() { echo "✗ ERREUR : $1"; exit 1; }

# ------------------------------------------------------------
# 1. Vérifier qu'on est bien à la racine du projet
# ------------------------------------------------------------

[ -f "$ROOT_DIR/pubspec.yaml" ] \
  || fail "pubspec.yaml introuvable. Ce script doit être lancé depuis le projet family-tasks."

ok "Racine du projet : $ROOT_DIR"

# ------------------------------------------------------------
# 2. Vérifier Flutter
# ------------------------------------------------------------

if ! command -v flutter >/dev/null 2>&1; then
  fail "flutter est introuvable dans le PATH. Ouvre un nouveau terminal, ou attends la fin de l'initialisation du Codespace, ou lance 'bash .devcontainer/setup.sh' s'il existe."
fi

FLUTTER_VERSION="$(flutter --version | head -n 1)"
ok "$FLUTTER_VERSION"

# ------------------------------------------------------------
# 3. Vérifier le SDK Android
# ------------------------------------------------------------

if [ -z "${ANDROID_HOME:-}" ]; then
  warn "ANDROID_HOME n'est pas défini. Le SDK Android ne sera peut-être pas trouvé."
elif [ ! -d "$ANDROID_HOME" ]; then
  warn "ANDROID_HOME pointe vers un dossier introuvable : $ANDROID_HOME"
else
  ok "SDK Android : $ANDROID_HOME"
fi

# ------------------------------------------------------------
# 4. Récupérer les dépendances Dart/Flutter
# ------------------------------------------------------------

echo
echo "→ Récupération des dépendances (flutter pub get)..."
if ! flutter pub get; then
  fail "flutter pub get a échoué. Corrige l'erreur ci-dessus avant de continuer."
fi
ok "Dépendances récupérées"

# ------------------------------------------------------------
# 5. Vérifier / régénérer les fichiers de la plateforme Android
# ------------------------------------------------------------

echo
echo "→ Vérification des fichiers Android (gradlew)..."

if [ -f "$ANDROID_DIR/gradlew" ]; then
  ok "android/gradlew présent"
else
  warn "android/gradlew absent — régénération des fichiers de la plateforme Android"
  echo "  (flutter create --platforms=android . — ne touche ni à lib/, ni à pubspec.yaml)"
  if ! flutter create --platforms=android .; then
    fail "flutter create --platforms=android . a échoué."
  fi
  if [ -f "$ANDROID_DIR/gradlew" ]; then
    ok "android/gradlew régénéré"
    chmod +x "$ANDROID_DIR/gradlew"
  else
    fail "android/gradlew toujours absent après régénération. Vérifie la sortie ci-dessus."
  fi
fi

# S'assurer que gradlew est exécutable dans tous les cas
if [ -f "$ANDROID_DIR/gradlew" ] && [ ! -x "$ANDROID_DIR/gradlew" ]; then
  chmod +x "$ANDROID_DIR/gradlew"
  ok "android/gradlew rendu exécutable"
fi

# ------------------------------------------------------------
# 6. Vérifier les fichiers privés de signature Android
# ------------------------------------------------------------

echo
echo "→ Vérification des fichiers de signature Android..."

if [ ! -f "$KEY_PROPERTIES" ]; then
  warn "android/key.properties absent."
  echo "  Ce fichier n'est jamais stocké dans Git (voir wiki : 'Si besoin de travailler"
  echo "  dans un nouveau code space sur V1-chat'). Restaure-le manuellement, ainsi que"
  echo "  le fichier familytasks-upload-keystore.jks, depuis ton emplacement sécurisé."
else
  ok "android/key.properties présent"

  STORE_FILE="$(sed -n 's/^storeFile=//p' "$KEY_PROPERTIES" | head -n 1)"

  if [ -z "$STORE_FILE" ]; then
    warn "storeFile absent de key.properties."
  else
    # storeFile est résolu par Gradle relativement au dossier android/
    KEYSTORE_PATH="$(realpath -m "$ANDROID_DIR/$STORE_FILE")"
    if [ -f "$KEYSTORE_PATH" ]; then
      ok "Keystore trouvé : $KEYSTORE_PATH"
    else
      warn "Keystore introuvable à l'emplacement résolu : $KEYSTORE_PATH"
      echo "  Vérifie le champ storeFile dans android/key.properties : il est résolu"
      echo "  relativement au dossier android/, donc pour un fichier placé à la racine"
      echo "  du projet, la valeur attendue est generalement : storeFile=../familytasks-upload-keystore.jks"
    fi
  fi
fi

# ------------------------------------------------------------
# 7. Résumé
# ------------------------------------------------------------

echo
echo "========================================"
echo " Résumé"
echo "========================================"
echo
echo "L'environnement de base (Flutter, dépendances, fichiers Android) est prêt."
echo
if [ -f "$KEY_PROPERTIES" ] && [ -n "${KEYSTORE_PATH:-}" ] && [ -f "${KEYSTORE_PATH:-/nonexistent}" ]; then
  echo "Signature Android en place → tu peux lancer une release :"
  echo "  bash scripts/release.sh"
else
  echo "Signature Android incomplète → restaure key.properties et le keystore"
  echo "avant de lancer une release (bash scripts/release.sh)."
  echo "Le développement courant (flutter run, tests, etc.) reste possible sans ça."
fi
echo
