🛡️ ZSHBACKUP

A portable Zsh backup and recovery menu for Termux.

A simple way to list and restore your Zsh backups when you need a recovery environment.

🚀 Quick Start

Open Termux and paste:

pkg install curl perl -y
curl -fsSL https://raw.githubusercontent.com/royalewhite/zshbackup/master/zshbackup.sh -o "$HOME/zshbackup.sh"
bash "$HOME/zshbackup.sh"

✨ Features

- 📂 List available backup snapshots.
- ♻️ Restore a selected snapshot.
- 🛡️ Create a safety snapshot before restoration.
- 🔐 Verify backup checksums before restoring.
- 📍 Choose the default or a custom backup directory.

📁 Default Backup Location

/sdcard/Download/termux-outputs/ZSH_BACKUP

📋 Requirements

- Termux
- Bash
- Perl
- Access to your ZSHBACKUP directory

📦 Repository

https://github.com/royalewhite/zshbackup

---

Keep calm. Your shell has a backup. 👾
