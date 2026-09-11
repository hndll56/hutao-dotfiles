# Contributing to HUTAO DOTFILES

Terima kasih sudah tertarik mengembangkan repository ini. HUTAO DOTFILES adalah konfigurasi BSPWM pribadi untuk Arch Linux, sehingga tujuan kontribusi utamanya adalah membuat konfigurasi lebih mudah dipahami, dipakai ulang, dan dimodifikasi tanpa menghilangkan karakter aslinya.

## Sebelum Mulai

- Gunakan Arch Linux atau turunan Arch untuk pengujian utama.
- Pahami dasar Git, Bash, BSPWM, dan sxhkd.
- Buat salinan konfigurasi pribadi sebelum mencoba installer.
- Jangan commit informasi pribadi, token, alamat lokal, atau path yang berisi data sensitif.

## Struktur yang Perlu Dipahami

| Lokasi | Fungsi |
|---|---|
| `config/bspwm/` | Aturan window, desktop, startup, dan perilaku BSPWM |
| `config/sxhkd/` | Shortcut keyboard |
| `config/polybar/` | Bar, tema, dan modul informasi sistem |
| `config/rofi/` | Launcher dan menu |
| `config/kitty/` | Konfigurasi terminal |
| `config/picom/` | Compositor dan efek transparansi |
| `config/dunst/` | Notifikasi |
| `config/fish/` | Shell |
| `config/nvim/` | Konfigurasi Neovim |
| `scripts/` | Script yang dipasang ke `~/.local/bin/` |
| `fonts/` | Font yang dipasang ke `~/.local/share/fonts/` |
| `wallpapers/` | Wallpaper |
| `packages.txt` | Daftar dependency pacman dan AUR |
| `install.sh` | Script restore/install |

## Alur Installer

```text
install.sh
  ├─ memeriksa dependency
  ├─ memasang package official melalui pacman
  ├─ memasang package AUR melalui yay
  ├─ menyalin config ke ~/.config
  ├─ menyalin script ke ~/.local/bin
  ├─ menyalin font dan wallpaper
  └─ menjalankan fc-cache -fv
```

## Cara Fork dan Mengembangkan

1. Klik **Fork** pada halaman GitHub repository.
2. Clone fork milikmu:

```bash
git clone https://github.com/<username>/hutao-dotfiles.git
cd hutao-dotfiles
```

3. Buat branch baru:

```bash
git switch -c nama-perubahan
```

4. Edit file yang diperlukan.
5. Uji perubahan pada perangkat sendiri.
6. Commit dan push:

```bash
git add .
git commit -m "docs: explain customization"
git push -u origin nama-perubahan
```

7. Buat Pull Request ke branch `main` repository utama.

## Panduan Modifikasi

### Shortcut

Edit `config/sxhkd/sxhkdrc`. Pastikan command yang dipanggil tersedia di sistem pengguna.

### BSPWM

Edit file di `config/bspwm/` untuk mengubah gap, border, desktop, aturan aplikasi, atau program startup.

### Polybar

Edit konfigurasi tema dan modul di `config/polybar/`. Hindari mengasumsikan semua komputer memiliki nama interface jaringan, sensor baterai, atau sensor temperatur yang sama.

### Script

Tambahkan script ke `scripts/`, gunakan shebang yang sesuai, dan buat executable. Jelaskan dependency script jika membutuhkan program tambahan.

### Dependency

Jika menambah package, masukkan ke `packages.txt` pada bagian yang sesuai: repository official atau AUR. Jangan menambahkan dependency yang hanya diperlukan oleh satu perangkat tanpa dokumentasi.

## Checklist Pull Request

- [ ] Perubahan sudah diuji.
- [ ] Tidak ada credential atau data pribadi.
- [ ] Path yang hardcoded sudah dijelaskan atau dibuat lebih portable.
- [ ] Dependency baru sudah ditambahkan ke `packages.txt` jika diperlukan.
- [ ] README diperbarui jika perilaku install atau penggunaan berubah.
- [ ] Commit menjelaskan perubahan secara singkat.

## Catatan

Konfigurasi ini tetap merupakan dotfiles pribadi. Pull Request yang memperbaiki dokumentasi, portability, typo, installer, atau error yang dapat direproduksi sangat diterima.
