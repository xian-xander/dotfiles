#!/bin/bash

# Obtiene las ventanas abiertas en Hyprland y las muestra como tooltip

clients=$(hyprctl clients -j 2>/dev/null)

if [[ -z "$clients" || "$clients" == "[]" ]]; then
    echo '{"text": "", "tooltip": "No hay apps abiertas", "class": "empty"}'
    exit 0
fi

# Extraer nombres únicos de apps (campo "class")
apps=$(echo "$clients" | grep '"class"' | sed 's/.*"class": "\(.*\)".*/\1/' | sort -u | grep -v '^$')

# Construir tooltip
tooltip=""
while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    tooltip+="$app\n"
done <<< "$apps"

# Eliminar último \n
tooltip="${tooltip%\\n}"

echo "{\"text\": \"❮\", \"tooltip\": \"$(echo -e "$tooltip")\"}"
