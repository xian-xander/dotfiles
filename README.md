<div align="center">
  <h1>My Arch Linux + Hyprland Dotfiles</h1>
  <p>My personal configurations, scripts, and tools for a Hyprland setup from scratch.</p>
</div>

---

## About this repository

This repository contains everything needed to restore my desktop environment on a clean installation of **Arch Linux**. It includes system configurations, applications, an automated installation script, and all the software I use daily.

### What's included?
- **Window Environment:** Hyprland, Waybar, Rofi, Wlogout, Dunst, Btop, Hyprlock.
- **Customization:** [Hyprland Theme Switcher](https://github.com/xian-xander/hyprland-theme-switcher), Matugen.
- **Terminal & Scripts:** Kitty and a collection of custom scripts in `~/.local/bin/` (e.g., rofi menus, quick shortcuts).
- **Applications:** Kitty, Nautilus, Zen Browser, Chromium, Discord, Spotify, Steam, OnlyOffice, Heroic, Bottles, Antigravity, Spicetify and VirtualBox.

---

## 📂 Repository Structure

```text
.
├── config/         # Configurations to be copied to ~/.config/
├── local-bin/      # Custom scripts to be copied to ~/.local/bin/
├── pkg-lists/      # Lists of packages to install
│   ├── pacman.lst  # Official Arch repository packages
│   └── aur.lst     # Arch User Repository (AUR) packages
├── install.sh      # Automated installation script
└── README.md       # This file
```

---

##  Installation on a new system

To use these dotfiles, you first need a base installation of **Arch Linux**. Ensure you have an active internet connection and a user with `sudo` privileges.

1. **Clone this repository:**
   ```bash
   git clone https://github.com/xian-xander/mis-dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```
   *(If you don't have git yet, install it with `sudo pacman -S git`)*

2. **Grant execution permissions to the installer:**
   ```bash
   chmod +x install.sh
   ```

3. **Run the script:**
   ```bash
   ./install.sh
   ```

### ⚙️ What does the script do?
The `install.sh` installation script is designed to automate the following steps:
1. Updates the system (`pacman -Syu`).
2. Installs **yay** (AUR package manager) if not present.
3. Installs **absolutely all** packages from the lists (`pacman.lst` and `aur.lst`).
4. Copies the folders from `config/` directly to `~/.config/`.
5. Copies your custom scripts to `~/.local/bin/` and grants them execution permissions.
6. Enables essential services: **SDDM** (Display Manager), **NetworkManager**, and **Bluetooth**.
7. Automatically clones the [hyprland-theme-switcher](https://github.com/xian-xander/hyprland-theme-switcher) repository into your home directory.

###  Finishing up
Once the script finishes, simply reboot your PC:
```bash
sudo reboot
```
You will be greeted by the **SDDM** login manager. Log in selecting **Hyprland** and enjoy your fully configured environment!

---

<div align="center">
  Made for xian-xander
</div>
