# 🛡️ ZSHBACKUP

Portable Zsh configuration backup and recovery for Termux.

**ZSHBACKUP** lets you create, verify, list, and restore snapshots of your Zsh configuration and custom scripts.

## ✨ Features

- 📦 Snapshot listing and recovery
- 🔐 SHA-256 checksum verification
- 🛡️ Automatic safety snapshot before restoration
- ♻️ Selective restoration of configuration files and scripts
- 📍 Default or custom backup directory
- 📱 Designed for rooted and non-rooted Termux devices

## 📋 Requirements

- Android with [Termux](https://github.com/termux/termux-app)
- Bash
- Perl
- Zsh
- Git and curl
- Storage permission for the backup directory

## 🚀 Fresh Termux Setup

If you're starting with a fresh Termux installation, install the minimum environment first.

### 1. Update Termux and install packages

```bash
pkg update
pkg install perl zsh git curl -y
termux-setup-storage
```

### 2. Install Oh My Zsh

```bash
RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 3. Install Powerlevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

### 4. Install Zsh plugins

```bash
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

git clone https://github.com/zsh-users/zsh-autosuggestions \
"$ZSH_CUSTOM/plugins/zsh-autosuggestions"

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
"$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

git clone https://github.com/marlonrichert/zsh-autocomplete \
"$ZSH_CUSTOM/plugins/zsh-autocomplete"
```

> **Note:** Oh My Zsh already includes the `git` and `autoupdate` plugins.

## 📥 Install ZSHBACKUP

Install or update the recovery script:

```bash
curl -fsSL https://raw.githubusercontent.com/royalewhite/zshbackup/master/zshbackup.sh \
-o "$HOME/zshbackup.sh"
```

Launch it:

```bash
bash "$HOME/zshbackup.sh"
```

## 📍 Backup Location

Default location:

```text
/sdcard/Download/termux-outputs/ZSH_BACKUP
```

You can also select a custom backup directory through the recovery menu.

## ♻️ Restore a Snapshot

1. Launch **ZSHBACKUP**.
2. Select your backup directory.
3. Choose **Restore snapshot**.
4. Select a snapshot or press `ENTER` for the latest.
5. Wait for checksum verification.
6. Type `RESTORE` to confirm.

ZSHBACKUP creates a safety snapshot before restoration.

Existing matching configuration files and scripts are replaced. Other custom scripts are not deleted.

After successful restoration, start Zsh:

```bash
zsh
```

## ⚠️ Important Notes

- Install the shell environment before restoring its configuration.
- ZSHBACKUP does not install Oh My Zsh, themes, plugins, or external tools automatically.
- Restoring configuration files does not guarantee that every custom script's dependencies are installed.
- ZSHBACKUP does not require root access.
- Keep your backup directory accessible before attempting recovery.

## 📜 License

GNU General Public License v3.0 (GPL-3.0).

---

**Author:** Evilars & Ku5i 👾✨
