#!/bin/bash

# ==============================================================================
# Script de Instalación Automatizada - Arch Linux + Hyprland
# ==============================================================================

set -e

echo "=========================================================="
echo "    Iniciando instalación del entorno Hyprland y Dotfiles "
echo "=========================================================="

# 1. Actualizar el sistema e instalar dependencias base
echo "[1/6] Actualizando el sistema..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

# 2. Instalar el gestor de AUR (yay)
echo "[2/6] Verificando e instalando yay..."
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
else
    echo "yay ya está instalado."
fi

# 3. Instalar paquetes de las listas
echo "[3/6] Instalando paquetes desde las listas..."
if [ -f "pkg-lists/pacman.lst" ]; then
    echo "-> Instalando paquetes oficiales..."
    sudo pacman -S --needed --noconfirm - < pkg-lists/pacman.lst
fi

if [ -f "pkg-lists/aur.lst" ]; then
    echo "-> Instalando paquetes de AUR..."
    yay -S --needed --noconfirm - < pkg-lists/aur.lst
fi

# 4. Restaurar configuraciones (Dotfiles)
echo "[4/6] Restaurando archivos de configuración..."
mkdir -p ~/.config
mkdir -p ~/.local/bin

echo "-> Copiando ~/.config..."
cp -r config/* ~/.config/ 2>/dev/null || true

echo "-> Copiando scripts de ~/.local/bin..."
cp -r local-bin/* ~/.local/bin/ 2>/dev/null || true
chmod +x ~/.local/bin/* 2>/dev/null || true

# 5. Habilitar el gestor de sesiones (SDDM)
echo "[5/6] Habilitando SDDM (Display Manager)..."
sudo systemctl enable sddm.service || true
# Nota: Habilitar también otros servicios si fuera necesario (NetworkManager, bluetooth, etc.)
sudo systemctl enable NetworkManager || true
sudo systemctl enable bluetooth || true

# 6. Recordatorio de Antigravity
echo "[6/7] Recordatorio: Antigravity (agy)"
echo "-> El ejecutable de Antigravity no se incluyó por exceder los límites de GitHub (200MB)."
echo "-> Recuerda instalarlo manualmente en tu nuevo sistema usando tu método de instalación habitual."
echo ""

# 7. Clonar repositorio del theme switcher
echo "[7/7] Clonando hyprland-theme-switcher..."
if [ ! -d "$HOME/hyprland-theme-switcher" ]; then
    git clone https://github.com/xian-xander/hyprland-theme-switcher.git ~/hyprland-theme-switcher
    echo "Repositorio de themes clonado en ~/hyprland-theme-switcher"
else
    echo "El repositorio hyprland-theme-switcher ya existe en tu home."
fi

echo "=========================================================="
echo " ¡Instalación completada exitosamente! "
echo " Podrás iniciar sesión usando SDDM en tu próximo reinicio."
echo "=========================================================="
