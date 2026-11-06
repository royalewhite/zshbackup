🛡️ ZSHBACKUP

A portable Zsh backup and recovery menu for Termux.

A simple way to list and restore your Zsh backups when you need a recovery environment.

🚀 Quick Start

1. Install Perl

Open Termux and run:

```bash
pkg install perl -y
```

2. Download ZSHBACKUP

```bash
curl -fsSL https://raw.githubusercontent.com/royalewhite/zshbackup/master/zshbackup.sh -o "$HOME/zshbackup.sh"
```

3. Launch the recovery menu

```bash
bash "$HOME/zshbackup.sh"
```

That's it! 👾

✨ Features

- 📂 List available backup snapshots.
- ♻️ Restore a selected snapshot.
- 🛡️ Create a safety snapshot before restoration.
- 🔐 Verify backup checksums before restoring.
- 📍 Choose the default or a custom backup directory.

📁 Default Backup Location

```text
/sdcard/Download/termux-outputs/ZSH_BACKUP
```

📋 Requirements

- Termux
- Bash
- Perl
- Access to your ZSHBACKUP directory

📦 Repository

"GitHub Repository" (https://github.com/royalewhite/zshbackup)

---

Keep calm. Your shell has a backup. 👾
