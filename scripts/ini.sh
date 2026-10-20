#!/bin/bash

# Lecture d'une valeur dans un fichier .ini
# Usage: ini_get <fichier> <section> <clé> [défaut]
ini_get() {
    local value
    value=$(awk -F'=' -v section="[$2]" -v key="$3" '
        /^[[:space:]]*\[/ { in_section = ($0 ~ "^[[:space:]]*" "\\" section) ; next }
        in_section && /^[[:space:]]*[^#;]/ {
            k = $1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
            if (k == key) {
                v = substr($0, index($0, "=") + 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
                print v; exit
            }
        }' "$1")
    echo "${value:-$4}"
}
