#!/usr/bin/env bash

set -euo pipefail

# Family Tasks — Release Android
# Usage:
#   bash scripts/release.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"
GRADLE_PROPERTIES="$ANDROID_DIR/gradle.properties"
BUILD_GRADLE="$ANDROID_DIR/app/build.gradle.kts"
APK="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"

echo
echo "========================================"
echo " Family Tasks — Android Release"
echo "========================================"
echo

fail() {
    echo
    echo "✗ ERREUR : $1"
    echo
    exit 1
}

ok() {
    echo "✓ $1"
}

# ------------------------------------------------------------
# 1. Vérification de Flutter
# ------------------------------------------------------------

command -v flutter >/dev/null 2>&1 \
    || fail "Flutter est introuvable dans le PATH."

FLUTTER_VERSION="$(flutter --version | head -n 1)"
ok "$FLUTTER_VERSION"

# ------------------------------------------------------------
# 2. Vérification du SDK Android
# ------------------------------------------------------------

[ -n "${ANDROID_HOME:-}" ] \
    || fail "ANDROID_HOME n'est pas défini."

[ -d "$ANDROID_HOME" ] \
    || fail "ANDROID_HOME pointe vers un dossier introuvable : $ANDROID_HOME"

[ -x "$ANDROID_HOME/platform-tools/adb" ] \
    || fail "adb est introuvable dans \$ANDROID_HOME/platform-tools."

ok "SDK Android : $ANDROID_HOME"

# ------------------------------------------------------------
# 3. Vérification du projet
# ------------------------------------------------------------

[ -d "$ANDROID_DIR" ] \
    || fail "Le dossier android/ est introuvable."

[ -f "$BUILD_GRADLE" ] \
    || fail "android/app/build.gradle.kts est introuvable."

[ -f "$GRADLE_PROPERTIES" ] \
    || fail "android/gradle.properties est introuvable."

ok "Projet Flutter/Android trouvé"

# ------------------------------------------------------------
# 4. Vérification de l'identité Android
# ------------------------------------------------------------

grep -q 'applicationId = "fr.tribulle.familytasks"' "$BUILD_GRADLE" \
    || fail "L'applicationId Android n'est pas fr.tribulle.familytasks."

grep -q 'namespace = "fr.tribulle.familytasks"' "$BUILD_GRADLE" \
    || fail "Le namespace Android n'est pas fr.tribulle.familytasks."

ok "Identité Android : fr.tribulle.familytasks"

# ------------------------------------------------------------
# 5. Vérification de la signature
# ------------------------------------------------------------

[ -f "$KEY_PROPERTIES" ] \
    || fail "android/key.properties est absent."

grep -q '^keyAlias=' "$KEY_PROPERTIES" \
    || fail "keyAlias est absent de key.properties."

grep -q '^keyPassword=' "$KEY_PROPERTIES" \
    || fail "keyPassword est absent de key.properties."

grep -q '^storePassword=' "$KEY_PROPERTIES" \
    || fail "storePassword est absent de key.properties."

grep -q '^storeFile=' "$KEY_PROPERTIES" \
    || fail "storeFile est absent de key.properties."

STORE_FILE="$(sed -n 's/^storeFile=//p' "$KEY_PROPERTIES" | head -n 1)"

[ -n "$STORE_FILE" ] \
    || fail "storeFile est vide."

KEYSTORE_PATH="$(realpath -m "$ANDROID_DIR/$STORE_FILE")"

[ -f "$KEYSTORE_PATH" ] \
    || fail "Le keystore indiqué par key.properties est introuvable : $KEYSTORE_PATH"

ok "Keystore et key.properties présents"

# ------------------------------------------------------------
# 6. Vérification de la configuration Gradle
# ------------------------------------------------------------

grep -q '^org.gradle.jvmargs=' "$GRADLE_PROPERTIES" \
    || fail "org.gradle.jvmargs n'est pas défini explicitement dans gradle.properties."

ok "Limite mémoire Gradle définie explicitement"

# ------------------------------------------------------------
# 7. Vérification de la mémoire disponible
# ------------------------------------------------------------

AVAILABLE_KB="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"

# 3 GiB minimum disponibles avant de lancer Gradle.
MIN_AVAILABLE_KB=$((3 * 1024 * 1024))

if [ "$AVAILABLE_KB" -lt "$MIN_AVAILABLE_KB" ]; then
    AVAILABLE_GIB="$(awk "BEGIN {printf \"%.1f\", $AVAILABLE_KB/1024/1024}")"
    fail "Seulement ${AVAILABLE_GIB} GiB de RAM disponibles. Attends que l'environnement soit moins chargé ou augmente la machine Codespaces."
fi

AVAILABLE_GIB="$(awk "BEGIN {printf \"%.1f\", $AVAILABLE_KB/1024/1024}")"
ok "Mémoire disponible : ${AVAILABLE_GIB} GiB"

# ------------------------------------------------------------
# 8. Arrêt des anciens daemons Gradle
# ------------------------------------------------------------

echo
echo "→ Arrêt des anciens daemons Gradle..."

(
    cd "$ANDROID_DIR"
    ./gradlew --stop
)

ok "Daemons Gradle nettoyés"

# ------------------------------------------------------------
# 9. Construction
# ------------------------------------------------------------

echo
echo "→ Construction de l'APK release..."
echo

cd "$ROOT_DIR"

flutter build apk --release

# ------------------------------------------------------------
# 10. Vérification finale
# ------------------------------------------------------------

[ -f "$APK" ] \
    || fail "La construction semble terminée mais l'APK est introuvable."

APK_SIZE="$(du -h "$APK" | cut -f1)"

echo
echo "========================================"
echo " ✓ RELEASE RÉUSSIE"
echo "========================================"
echo
echo "APK : $APK"
echo "Taille : $APK_SIZE"
echo