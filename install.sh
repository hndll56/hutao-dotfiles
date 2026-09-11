#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$REPO_DIR/packages.txt"

ok() { printf '[OK] %s\n' "$*"; }
fail() { printf '[FAILED] %s\n' "$*" >&2; }
die() { fail "$*"; exit 1; }

run_step() {
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else fail "$desc"; return 1; fi
}

run_step_sudo() {
  local desc="$1"; shift
  if sudo "$@"; then ok "$desc"; else fail "$desc"; return 1; fi
}

check_step() {
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else fail "$desc"; return 0; fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

read_packages_section() {
  local section="$1"
  awk -v sec="$section" '
    BEGIN { inside=0 }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    tolower($0)=="official" { inside=(sec=="official"); next }
    tolower($0)=="aur" { inside=(sec=="aur"); next }
    inside { print $0 }
  ' "$PACKAGES_FILE"
}

copy_tree() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
}

main() {
  [ "${EUID}" -ne 0 ] || die "Jalankan installer sebagai user biasa, bukan root. User harus memiliki akses sudo."
  need_cmd pacman || die "pacman tidak ditemukan (script ini untuk Arch/pacman)"
  need_cmd sudo || die "sudo tidak ditemukan"
  need_cmd awk || die "awk tidak ditemukan"
  [ -f "$PACKAGES_FILE" ] || die "packages.txt tidak ditemukan: $PACKAGES_FILE"

  run_step "sudo check" sudo -v || die "butuh akses sudo"

  mapfile -t OFFICIAL_PKGS < <(read_packages_section official)
  if [ ${#OFFICIAL_PKGS[@]} -gt 0 ]; then
    run_step_sudo "install official packages" pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}" || die "gagal install official packages"
  else
    ok "install official packages (none)"
  fi

  mapfile -t AUR_PKGS < <(read_packages_section aur)
  if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    if ! need_cmd yay; then
      need_cmd git || die "git diperlukan untuk memasang yay"
      run_step "install yay (clone+makepkg)" bash -lc '
        set -euo pipefail
        tmp="$(mktemp -d)"
        trap "rm -rf \"$tmp\"" EXIT
        cd "$tmp"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
      ' || die "gagal install yay"
    else
      ok "yay already installed"
    fi
    run_step "install AUR packages" yay -S --needed --noconfirm "${AUR_PKGS[@]}" || die "gagal install AUR packages"
  else
    ok "install AUR packages (none)"
  fi

  mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/fonts" "$HOME/Pictures"
  ok "ensure target dirs"

  for d in bspwm sxhkd polybar rofi kitty picom dunst fish nvim; do
    if [ -d "$REPO_DIR/config/$d" ]; then
      run_step "restore ~/.config/$d" copy_tree "$REPO_DIR/config/$d" "$HOME/.config/$d" || die "gagal restore config: $d"
    else
      die "missing in repo: config/$d"
    fi
  done

  if [ -d "$REPO_DIR/config/rofi/themes" ]; then
    run_step "restore rofi themes to ~/.local/share/rofi/themes" bash -lc '
      set -euo pipefail
      mkdir -p "$HOME/.local/share/rofi/themes"
      cp -a "'"$REPO_DIR"'/config/rofi/themes/." "$HOME/.local/share/rofi/themes/"
    ' || die "gagal restore rofi themes"
  else
    ok "restore rofi themes (none)"
  fi

  if [ -d "$REPO_DIR/scripts" ]; then
    run_step "restore ~/.local/bin" copy_tree "$REPO_DIR/scripts" "$HOME/.local/bin" || die "gagal restore scripts"
  else
    ok "restore ~/.local/bin (none)"
  fi

  if [ -d "$REPO_DIR/fonts" ]; then
    run_step "restore fonts" copy_tree "$REPO_DIR/fonts" "$HOME/.local/share/fonts" || die "gagal restore fonts"
  else
    ok "restore fonts (none)"
  fi

  if [ -d "$REPO_DIR/wallpapers" ] && [ -n "$(find "$REPO_DIR/wallpapers" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    WALL_DST="$HOME/Pictures/Wallpapers"
    run_step "restore wallpapers -> $WALL_DST" bash -lc '
      set -euo pipefail
      mkdir -p "'"$HOME"'/Pictures/Wallpapers"
      cp -a "'"$REPO_DIR"'/wallpapers/." "'"$HOME"'/Pictures/Wallpapers/"
    ' || die "gagal restore wallpapers"
  else
    ok "restore wallpapers (none)"
  fi

  run_step "chmod +x bspwmrc" chmod +x "$HOME/.config/bspwm/bspwmrc" || die "chmod bspwmrc gagal"

  run_step "chmod +x bspwm scripts" bash -lc '
    set -euo pipefail
    shopt -s nullglob
    for f in "$HOME/.config/bspwm"/*.sh; do chmod +x "$f"; done
  ' || die "chmod bspwm *.sh gagal"

  run_step "chmod +x polybar scripts" bash -lc '
    set -euo pipefail
    shopt -s nullglob
    for f in "$HOME/.config/polybar"/*.sh; do chmod +x "$f"; done
  ' || die "chmod polybar *.sh gagal"

  run_step "chmod +x ~/.local/bin (files)" bash -lc '
    set -euo pipefail
    find "$HOME/.local/bin" -maxdepth 1 -type f -print0 | xargs -0 -r chmod +x
  ' || die "chmod ~/.local/bin gagal"

  run_step "fc-cache -fv" fc-cache -fv || die "fc-cache gagal"

  check_step "optional check AudioRelay: $HOME/portable/bin/AudioRelay" test -x "$HOME/portable/bin/AudioRelay"
  check_step "check rofi theme: $HOME/.local/share/rofi/themes/simple-tokyonight.rasi" test -f "$HOME/.local/share/rofi/themes/simple-tokyonight.rasi"

  ok "done"
}

main "$@"
