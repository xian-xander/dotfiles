#!/bin/bash

# Configuración
ROFI_THEME="$HOME/.config/rofi/launcher.rasi"
SNIPPETS_FILE="$HOME/.local/share/snippets.txt"
NOTAS_DIR="$HOME/.local/share/notas_rofi"
mkdir -p "$NOTAS_DIR"

# Sobrescribimos temporalmente el diseño de la cuadrícula de iconos (grid)
TEXT_THEME_STR='configuration { disable-history: true; } window {width: 900px;} listview {columns: 1; lines: 12; scrollbar: true;} element {padding: 10px;} element-text {horizontal-align: 0.0;}'

# ==========================================
# FUNCIONES DE BATERÍA
# ==========================================
aplicar_bateria() {
    local min=$1
    local max=$2
    local mensaje=$3
    sudo ~/.local/bin/set_battery.sh "$min" "$max"
    notify-send -u normal -t 3000 -a "Gestor de Batería" "🔋 Batería" "$mensaje"
}

menu_bateria() {
    local OPCIONES_BATERIA="󰁹 Normal (0-100%)\n󰂂 Conservación (75-80%)\n󰌍 Volver"
    local ELECCION_BATERIA=$(echo -e "$OPCIONES_BATERIA" | rofi -dmenu -i -disable-history -p "Batería:" -theme "$ROFI_THEME" -theme-str "$TEXT_THEME_STR")

    case "$ELECCION_BATERIA" in
        "󰁹 Normal (0-100%)") aplicar_bateria 0 100 "Modo Normal activado (0-100%)" ;;
        "󰂂 Conservación (75-80%)") aplicar_bateria 75 80 "Modo Conservación activado (75-80%)" ;;
        "󰌍 Volver") main_menu ;;
    esac
}

# ==========================================
# FUNCIONES DE AUDIO
# ==========================================
menu_audio() {
    local OPCIONES_AUDIO=$(pactl list sinks | grep -E 'Sink #|Description:' | awk '
        /Sink #/ { id=substr($2, 2) }
        /Description:/ { sub(/^[ \t]+Description: /, ""); print "🎵 " $0 "|" id }
    ')

    if [ -z "$OPCIONES_AUDIO" ]; then
        notify-send -u critical "Audio" "No se encontraron dispositivos."
        main_menu
        return
    fi

    local NOMBRES_AUDIO=$(echo "$OPCIONES_AUDIO" | cut -d'|' -f1)
    NOMBRES_AUDIO="$NOMBRES_AUDIO\n󰌍 Volver"

    local ELECCION_AUDIO=$(echo -e "$NOMBRES_AUDIO" | rofi -dmenu -i -disable-history -p "Salida de Audio:" -theme "$ROFI_THEME" -theme-str "$TEXT_THEME_STR")

    if [[ "$ELECCION_AUDIO" == "󰌍 Volver" ]]; then
        main_menu
    elif [[ -n "$ELECCION_AUDIO" ]]; then
        local ID=$(echo "$OPCIONES_AUDIO" | grep "^$ELECCION_AUDIO|" | cut -d'|' -f2)
        if [[ -n "$ID" ]]; then
            pactl set-default-sink "$ID"
            notify-send -t 3000 "Audio" "Salida cambiada a:\n$ELECCION_AUDIO"
        fi
    fi
}

# ==========================================
# FUNCIONES DE MODO NOCHE
# ==========================================
toggle_night_mode() {
    if command -v hyprsunset &>/dev/null; then
        if pgrep -x "hyprsunset" >/dev/null; then
            killall hyprsunset; notify-send -t 3000 "Modo Noche" "Protección ocular DESACTIVADA ☀️"
        else
            hyprsunset -t 4500 >/dev/null 2>&1 &
            notify-send -t 3000 "Modo Noche" "Protección ocular ACTIVADA 🌙"
        fi
    elif command -v wlsunset &>/dev/null; then
        if pgrep -x "wlsunset" >/dev/null; then
            killall wlsunset; notify-send -t 3000 "Modo Noche" "Protección ocular DESACTIVADA ☀️"
        else
            wlsunset -t 4500 >/dev/null 2>&1 &
            notify-send -t 3000 "Modo Noche" "Protección ocular ACTIVADA 🌙"
        fi
    fi
}

# ==========================================
# FUNCIONES DE MÁQUINAS VIRTUALES (ASIR)
# ==========================================
menu_vms() {
    local vms=""
    
    if command -v VBoxManage &>/dev/null; then
        while read -r line; do
            [[ -n "$line" ]] && vms+="VBox 🖥️ $line@@@$line\n"
        done <<< "$(VBoxManage list vms | awk -F'"' '{print $2}')"
    fi
    
    if command -v virsh &>/dev/null; then
        while read -r line; do
            [[ -n "$line" ]] && vms+="KVM 🖥️ $line@@@$line\n"
        done <<< "$(virsh -c qemu:///system list --all --name 2>/dev/null | grep -v '^$')"
    fi

    if command -v vmrun &>/dev/null; then
        local inv="$HOME/.vmware/inventory.vmls"
        if [ -f "$inv" ]; then
            while read -r vmx; do
                [[ -n "$vmx" && -f "$vmx" ]] || continue
                vms+="VMware 🖥️ $(basename "$vmx" .vmx)@@@$vmx\n"
            done <<< "$(grep 'config = ' "$inv" 2>/dev/null | cut -d'"' -f2)"
        else
            while read -r vmx; do
                vms+="VMware 🖥️ $(basename "$vmx" .vmx)@@@$vmx\n"
            done <<< "$(find "$HOME/vmware/" -maxdepth 3 -name "*.vmx" 2>/dev/null)"
        fi
    fi
    
    if [ -z "$vms" ]; then
        notify-send -u critical "VMs" "No se encontraron máquinas."
        main_menu
        return
    fi
    
    local LISTA_ROFI=$(echo -e "$vms" | awk -F'@@@' '{print $1}')
    LISTA_ROFI="$LISTA_ROFI\n󰌍 Volver"
    
    local ELECCION_ROFI=$(echo -e "$LISTA_ROFI" | rofi -dmenu -i -disable-history -p "Selecciona VM:" -theme "$ROFI_THEME" -theme-str "$TEXT_THEME_STR")
    
    if [[ "$ELECCION_ROFI" == "󰌍 Volver" ]]; then
        main_menu
        return
    elif [[ -n "$ELECCION_ROFI" ]]; then
        local engine=$(echo "$ELECCION_ROFI" | awk '{print $1}')
        local vm_name_display=$(echo "$ELECCION_ROFI" | cut -d' ' -f3-)
        local vm_id=$(echo -e "$vms" | grep -F "$ELECCION_ROFI@@@" | awk -F'@@@' '{print $2}')
        
        local ACCIONES="▶️ Iniciar (GUI)\n▶️ Iniciar (Segundo plano)\n⏹️ Apagar (Forzado)\n󰌍 Volver"
        local ACCION=$(echo -e "$ACCIONES" | rofi -dmenu -i -disable-history -p "¿Acción?" -theme "$ROFI_THEME" -theme-str "$TEXT_THEME_STR")
        
        case "$ACCION" in
            "▶️ Iniciar (GUI)")
                if [ "$engine" == "VBox" ]; then 
                    SALIDA=$(VBoxManage startvm "$vm_id" --type gui 2>&1)
                elif [ "$engine" == "KVM" ]; then 
                    SALIDA=$(virsh -c qemu:///system start "$vm_id" 2>&1)
                    if [[ $? -eq 0 || "$SALIDA" == *"already active"* ]]; then virt-manager --connect qemu:///system --show-domain-console "$vm_id" >/dev/null 2>&1 & fi
                elif [ "$engine" == "VMware" ]; then 
                    local DESKTOP_FILE="$HOME/.local/share/applications/vmware-workstation.desktop"
                    if [ -f "$DESKTOP_FILE" ]; then
                        local VMWARE_CMD=$(grep '^Exec=' "$DESKTOP_FILE" | head -n1 | sed 's/^Exec=//' | sed 's/ %U//; s/ %f//; s/ %F//; s/ %u//')
                        eval "$VMWARE_CMD -x '$vm_id' >/dev/null 2>&1 &"
                        SALIDA=""
                    elif command -v vmware &>/dev/null; then
                        vmware -x "$vm_id" >/dev/null 2>&1 &
                        SALIDA=""
                    else
                        vmplayer -X "$vm_id" >/dev/null 2>&1 &
                        SALIDA=""
                    fi
                fi
                if [ $? -eq 0 ]; then notify-send -t 3000 "VMs" "Iniciando:\n$vm_name_display"; else notify-send -u critical "Error $engine" "$SALIDA"; fi
                ;;
            "▶️ Iniciar (Segundo plano)")
                if [ "$engine" == "VBox" ]; then SALIDA=$(VBoxManage startvm "$vm_id" --type headless 2>&1)
                elif [ "$engine" == "KVM" ]; then SALIDA=$(virsh -c qemu:///system start "$vm_id" 2>&1)
                elif [ "$engine" == "VMware" ]; then SALIDA=$(vmrun start "$vm_id" nogui 2>&1)
                fi
                if [ $? -eq 0 ]; then notify-send -t 3000 "VMs" "Iniciando en fondo:\n$vm_name_display"; else notify-send -u critical "Error $engine" "$SALIDA"; fi
                ;;
            "⏹️ Apagar (Forzado)")
                if [ "$engine" == "VBox" ]; then VBoxManage controlvm "$vm_id" poweroff >/dev/null 2>&1 &
                elif [ "$engine" == "KVM" ]; then virsh -c qemu:///system destroy "$vm_id" >/dev/null 2>&1 &
                elif [ "$engine" == "VMware" ]; then vmrun stop "$vm_id" hard >/dev/null 2>&1 &
                fi
                notify-send -t 3000 "VMs" "Apagando:\n$vm_name_display" 
                ;;
            "󰌍 Volver") menu_vms ;;
        esac
    fi
}

# ==========================================
# FUNCIONES DE SSH
# ==========================================
menu_ssh() {
    local SSH_CONFIG="$HOME/.ssh/config"
    local HOSTS=$(grep -i "^Host " "$SSH_CONFIG" 2>/dev/null | grep -v "*" | awk '{print "🌐 "$2}')
    
    if [ -z "$HOSTS" ]; then
        notify-send -u critical "SSH" "No tienes servidores configurados."
        main_menu
        return
    fi
    
    HOSTS+="\n󰌍 Volver"
    local ELECCION_HOST=$(echo -e "$HOSTS" | rofi -dmenu -i -disable-history -p "Conectar a:" -theme "$ROFI_THEME" -theme-str "$TEXT_THEME_STR")
    
    if [[ "$ELECCION_HOST" == "󰌍 Volver" ]]; then
        main_menu
    elif [[ -n "$ELECCION_HOST" ]]; then
        local selected_host=$(echo "$ELECCION_HOST" | awk '{print $2}')
        kitty --title "SSH: $selected_host" bash -c "ssh '$selected_host'; echo ''; echo '---'; echo 'Conexión finalizada o fallida.'; read -p 'Presiona ENTER para cerrar la ventana...'" &
    fi
}

# ==========================================
# FUNCIONES DE CHULETARIO (SNIPPETS)
# ==========================================
menu_snippets() {
    local OPCIONES_MARKUP=""
    while IFS="|" read -r desc cmd; do
        desc=$(echo "$desc" | xargs)
        cmd=$(echo "$cmd" | xargs)
        [[ -z "$desc" || -z "$cmd" ]] && continue
        OPCIONES_MARKUP+="<span color='#88c0d0'><b>$desc</b></span>   ➜   <span color='#a3be8c'><i>$cmd</i></span>@@@$cmd\n"
    done < "$SNIPPETS_FILE"

    local SNIPPETS_THEME='configuration { disable-history: true; } window {width: 1000px;} listview {columns: 1; lines: 12;} element {padding: 12px;} element-text {horizontal-align: 0.0; markup: true;}'

    local LISTA_ROFI=$(echo -e "$OPCIONES_MARKUP" | awk -F'@@@' '{print $1}')
    LISTA_ROFI="$LISTA_ROFI\n󰌍 Volver"

    local ELECCION_ROFI=$(echo -e "$LISTA_ROFI" | rofi -dmenu -i -disable-history -markup-rows -p "Snippets:" -theme "$ROFI_THEME" -theme-str "$SNIPPETS_THEME")
    
    if [[ "$ELECCION_ROFI" == "󰌍 Volver" ]]; then
        main_menu
    elif [[ -n "$ELECCION_ROFI" ]]; then
        local COMANDO_ORIGINAL=$(echo -e "$OPCIONES_MARKUP" | grep -F "$ELECCION_ROFI@@@" | awk -F'@@@' '{print $2}')
        
        if [ -n "$COMANDO_ORIGINAL" ]; then
            echo -n "$COMANDO_ORIGINAL" | wl-copy
            notify-send -t 3000 "Chuletario" "Comando copiado:\n$COMANDO_ORIGINAL"
        fi
    fi
}

# ==========================================
# MENÚ PRINCIPAL
# ==========================================
main_menu() {
    local OPCIONES=" Lanzador de Aplicaciones\n🎨 Cambiar Tema\n🔋 Opciones de batería\n🔊 Cambiar Salida de Audio\n🌙 Modo Noche (On/Off)\n🖥️ Gestor de Máquinas Virtuales\n🌐 Conexiones SSH Rápidas\n📝 Chuletario (Snippets)"
    local ELECCION=$(echo -e "$OPCIONES" | rofi -dmenu -i -disable-history -p "Menú:" -theme "$ROFI_THEME")

    case "$ELECCION" in
        " Lanzador de Aplicaciones") rofi -show drun -theme "$ROFI_THEME" ;;
        "🎨 Cambiar Tema") "$HOME/.local/bin/switch_theme.sh" ;;
        "🔋 Opciones de batería") menu_bateria ;;
        "🔊 Cambiar Salida de Audio") menu_audio ;;
        "🌙 Modo Noche (On/Off)") toggle_night_mode ;;
        "🖥️ Gestor de Máquinas Virtuales") menu_vms ;;
        "🌐 Conexiones SSH Rápidas") menu_ssh ;;
        "📝 Chuletario (Snippets)") menu_snippets ;;
    esac
}

# Ejecutar el menú principal
main_menu
