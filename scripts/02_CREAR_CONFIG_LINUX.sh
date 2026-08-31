#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f config/local.json ]]; then
  cp config/local.example.json config/local.json
fi

echo "config/local.json listo."
echo "Edita SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY."
