#!/bin/bash

# Directorio de notas
NOTAS_DIR="$HOME/.local/share/notas_rofi"
mkdir -p "$NOTAS_DIR"

ROFI_THEME="$HOME/.config/rofi/launcher.rasi"
TEXT_THEME_STR='configuration { disable-history: true; } window {width: 900px;} listview {columns: 1; lines: 12;} element-text {markup: true;}'

menu_notas() {
    local opciones="[+] Crear nueva nota...\n"
    
    # Listar notas existentes leyendo la primera línea para el resumen visual
    for file in "$NOTAS_DIR"/*.txt; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file" .txt)
            local first_line=$(head -n 1 "$file" | cut -c 1-60 | tr '\n' ' ')
            opciones+="📄 $filename   <span color='#a3be8c' size='small'><i>$first_line...</i></span>@@@$filename\n"
        fi
    done
    
    opciones+="󰌍 Salir"
    
    local LISTA_ROFI=$(echo -e "$opciones" | awk -F'@@@' '{print $1}')
    local ELECCION_ROFI=$(echo -e "$LISTA_ROFI" | rofi -dmenu -i -disable-history -markup-rows -p "Mis Notas:" -theme "$ROFI_THEME" -theme-str "$TEXT_THEME_STR entry { placeholder: \"Buscar notas...\"; }")
    
    if [ "$ELECCION_ROFI" == "[+] Crear nueva nota..." ]; then
        # 1. Pedimos el contenido de la nota
        local contenido=$(rofi -dmenu -i -disable-history -p "Escribe tu nota:" -theme "$ROFI_THEME" -theme-str 'window {width: 1000px;} listview {lines: 0;} entry { placeholder: "Escribe aquí tu nota..."; }')
        
        if [ -n "$contenido" ]; then
            # 2. Pedimos el título AL FINAL
            local titulo_manual=$(rofi -dmenu -i -disable-history -p "Título:" -theme "$ROFI_THEME" -theme-str 'window {width: 700px;} listview {lines: 0;} entry { placeholder: "Escribe el título (o deja en blanco para auto)..."; }')
            
            if [ -z "$titulo_manual" ]; then
                titulo_manual=$(echo "$contenido" | tr -d '/\\:*?"<>|' | cut -c 1-30 | xargs)
                if [ -z "$titulo_manual" ]; then titulo_manual="Nota_$(date +%s)"; fi
            else
                titulo_manual=$(echo "$titulo_manual" | tr -d '/\\:*?"<>|')
            fi
            
            if [ -f "$NOTAS_DIR/$titulo_manual.txt" ]; then
                titulo_manual="${titulo_manual}_$(date +%s)"
            fi
            
            echo "$contenido" > "$NOTAS_DIR/$titulo_manual.txt"
            notify-send -t 3000 "Notas" "Nota guardada:\n$titulo_manual"
        fi
        menu_notas
        
    elif [[ -n "$ELECCION_ROFI" && "$ELECCION_ROFI" != "󰌍 Salir" ]]; then
        local target_name=$(echo -e "$opciones" | grep -F "$ELECCION_ROFI@@@" | awk -F'@@@' '{print $2}')
        if [ -n "$target_name" ]; then
            menu_accion_nota "$target_name"
        fi
    fi
}

menu_accion_nota() {
    local filename=$1
    local filepath="$NOTAS_DIR/$filename.txt"
    
    local acciones="📖 Leer nota\n📋 Copiar al portapapeles\n✏️ Editar / Modificar nota\n Borrar nota\n⬅️ Volver"
    local accion=$(echo -e "$acciones" | rofi -dmenu -i -disable-history -p "Acción:" -theme "$ROFI_THEME" -theme-str "$TEXT_THEME_STR entry { placeholder: \"Buscar acción...\"; }")
    
    case "$accion" in
        "📖 Leer nota")
            local contenido_nota=$(cat "$filepath")
            rofi -e "$contenido_nota" -theme "$ROFI_THEME" -theme-str 'window {width: 800px;}'
            menu_notas
            ;;
        "📋 Copiar al portapapeles")
            cat "$filepath" | wl-copy
            notify-send -t 3000 "Notas" "Copiado al portapapeles."
            menu_notas
            ;;
        "✏️ Editar / Modificar nota")
            local lineas_rofi="[+] Añadir nueva línea al final\n"
            lineas_rofi+=$(awk '{print NR" | "$0}' "$filepath")
            
            local linea_seleccionada=$(echo -e "$lineas_rofi" | rofi -dmenu -i -disable-history -p "Elige línea:" -theme "$ROFI_THEME" -theme-str 'window {width: 1000px;} entry { placeholder: "Buscar línea..."; }')
            
            if [ "$linea_seleccionada" == "[+] Añadir nueva línea al final" ]; then
                local nuevo_texto=$(rofi -dmenu -i -disable-history -p "Nueva línea:" -theme "$ROFI_THEME" -theme-str 'window {width: 1000px;} listview {lines: 0;} entry { placeholder: "Escribe la nueva línea..."; }')
                if [ -n "$nuevo_texto" ]; then
                    echo "$nuevo_texto" >> "$filepath"
                    notify-send -t 3000 "Notas" "Línea añadida."
                fi
            elif [ -n "$linea_seleccionada" ]; then
                local num_linea=$(echo "$linea_seleccionada" | awk -F' \\| ' '{print $1}')
                local contenido_linea=$(sed "${num_linea}q;d" "$filepath")
                
                local editado=$(rofi -dmenu -i -disable-history -p "Editando:" -filter "$contenido_linea" -theme "$ROFI_THEME" -theme-str 'window {width: 1000px;} listview {lines: 0;} entry { placeholder: "Modifica el texto..."; }')
                
                if [ -n "$editado" ]; then
                    sed -i "${num_linea}c\\$editado" "$filepath"
                    notify-send -t 3000 "Notas" "Línea modificada."
                fi
            fi
            menu_notas
            ;;
        " Borrar nota")
            local confirmar=$(echo -e "Sí\nNo" | rofi -dmenu -i -disable-history -p "¿Borrar '$filename'?" -theme "$ROFI_THEME" -theme-str 'window {width: 450px;} listview {lines: 2;} entry { placeholder: "Escribe Sí o No..."; }')
            if [ "$confirmar" == "Sí" ]; then
                rm -f "$filepath"
                notify-send -t 3000 "Notas" "Nota borrada."
            fi
            menu_notas
            ;;
        "⬅️ Volver")
            menu_notas
            ;;
    esac
}

# Arrancar prototipo
menu_notas
