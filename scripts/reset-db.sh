#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DB="$ROOT_DIR/family-tasks.db"
SCHEMA="$ROOT_DIR/database/schema.sql"
SEED="$ROOT_DIR/database/seed.sql"

echo
echo "========================================"
echo " Family Tasks — Reset Database"
echo "========================================"
echo

# Vérifications
[ -f "$SCHEMA" ] || {
    echo "❌ database/schema.sql introuvable."
    exit 1
}

[ -f "$SEED" ] || {
    echo "❌ database/seed.sql introuvable."
    exit 1
}

# Suppression de la base existante
if [ -f "$DB" ]; then
    echo "→ Suppression de la base existante..."
    rm -f "$DB"
    echo "✓ Base supprimée"
else
    echo "→ Aucune base existante."
fi

# Création du schéma
echo
echo "→ Création du schéma SQLite..."

sqlite3 "$DB" < "$SCHEMA"

echo "✓ Schéma créé"

# Injection des données de test
echo
echo "→ Injection des données de test..."

sqlite3 "$DB" < "$SEED"

echo "✓ Données de test injectées"

# Vérification rapide
echo
echo "→ Vérification..."

TABLE_COUNT="$(sqlite3 "$DB" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")"

echo "✓ Tables créées : $TABLE_COUNT"

echo
echo "========================================"
echo " ✓ BASE DE DONNÉES RECONSTRUITE"
echo "========================================"
echo
echo "Base : $DB"
echo