#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$REPO_DIR/packages.txt"

ok() { printf '[OK] %s\n' "$*"; }
fail() { printf '[FAILED] %s\n' "$*"; }

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
  # usage: read_packages_section official|aur
  local section="$1"
  awk -v sec="$section" '
    BEGIN { in=0 }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    tolower($0)=="official" { in=(sec=="official"); next }
    tolower($0)=="aur"      { in=(sec=="aur"); next }
    in { print $0 }
  ' "$PACKAGES_FILE"
}

copy_tree() {
  # copy_tree SRC_DIR DEST_DIR (merge)
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
}

main() {
  need_cmd pacman || die "pacman tidak ditemukan (script ini untuk Arch/pacman)"

  if [ ! -f "$PACKAGES_FILE" ]; then
    die "packages.txt tidak ditemukan: $PACKAGES_FILE"
  fi

  # sudo check early
  run_step "sudo check" sudo -v || die "butuh akses sudo"

  # Install official packages
  mapfile -t OFFICIAL_PKGS < <(read_packages_section official)
  if [ ${#OFFICIAL_PKGS[@]} -gt 0 ]; then
    run_step_sudo "install official packages" pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}" \
      || die "gagal install official packages"
  else
    ok "install official packages (none)"
  fi

  # Ensure yay for AUR
  mapfile -t AUR_PKGS < <(read_packages_section aur)
  if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    if ! need_cmd yay; then
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

    run_step "install AUR packages" yay -S --needed --noconfirm "${AUR_PKGS[@]}" \
      || die "gagal install AUR packages"
  else
    ok "install AUR packages (none)"
  fi

  # Restore configs
  mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/fonts" "$HOME/Pictures"
  ok "ensure target dirs"

  for d in bspwm sxhkd polybar rofi kitty picom dunst fish nvim; do
    if [ -d "$REPO_DIR/config/$d" ]; then
      run_step "restore ~/.config/$d" copy_tree "$REPO_DIR/config/$d" "$HOME/.config/$d" \
        || die "gagal restore config: $d"
    else
      fail "missing in repo: config/$d"
      exit 1
    fi
  done

  # Rofi theme(s) referenced from configs
  if [ -d "$REPO_DIR/config/rofi/themes" ]; then
    run_step "restore rofi themes to ~/.local/share/rofi/themes" bash -lc '
      set -euo pipefail
      mkdir -p "$HOME/.local/share/rofi/themes"
      cp -a "'$REPO_DIR'/config/rofi/themes/." "$HOME/.local/share/rofi/themes/"
    ' || die "gagal restore rofi themes"
  else
    ok "restore rofi themes (none)"
  fi

  # Restore scripts
  if [ -d "$REPO_DIR/scripts" ]; then
    run_step "restore ~/.local/bin" copy_tree "$REPO_DIR/scripts" "$HOME/.local/bin" \
      || die "gagal restore scripts"
  else
    ok "restore ~/.local/bin (none)"
  fi

  # Restore fonts
  if [ -d "$REPO_DIR/fonts" ]; then
    run_step "restore fonts" copy_tree "$REPO_DIR/fonts" "$HOME/.local/share/fonts" \
      || die "gagal restore fonts"
  else
    ok "restore fonts (none)"
  fi

  # Restore wallpapers
  if [ -d "$REPO_DIR/wallpapers" ] && [ "$(ls -A "$REPO_DIR/wallpapers" 2>/dev/null || true)" != "" ]; then
    WALL_DST="$HOME/Pictures/Wallpapers"
    run_step "restore wallpapers -> $WALL_DST" bash -lc '
      set -euo pipefail
      mkdir -p "'$HOME'/Pictures/Wallpapers"
      cp -a "'$REPO_DIR'/wallpapers/." "'$HOME'/Pictures/Wallpapers/"
    ' || die "gagal restore wallpapers"
  else
    ok "restore wallpapers (none)"
  fi

  # Permissions
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
    find "$HOME/.local/bin" -maxdepth 1 -type f -print0 | xargs -0 chmod +x
  ' || die "chmod ~/.local/bin gagal"

  # Font cache
  run_step "fc-cache -fv" fc-cache -fv || die "fc-cache gagal"

  # Non-fatal readiness checks (config references)
  check_step "optional check AudioRelay: $HOME/portable/bin/AudioRelay" test -x "$HOME/portable/bin/AudioRelay"
  check_step "check rofi theme: $HOME/.local/share/rofi/themes/simple-tokyonight.rasi" test -f "$HOME/.local/share/rofi/themes/simple-tokyonight.rasi"

  ok "done"
}

main "$@"
