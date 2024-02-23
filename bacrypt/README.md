# Bacrypt - Backup and Encrypt Files Suite

Bacrypt is a suite of bash scripts for backing up and encrypting files.

The encrypted files intended to be store online at github, so the files name are masked (to hide embarassing file name).

GnuPG id (ie. pro7357@protonmail.com) is used to padded the file name before converted to sha256sum hash. Keep the id secret for maximum privacy.

## Components

### 1. Timed.sh

Timed.sh automatically backing up and encrypting files on a predefined schedule using systemd timers.

### 2. Bacrypt.sh

TODO: Bacrypt.sh is a more comprehensive script that includes additional features such as:

- Interactive configuration setup
- Manual backup and encryption options
- File restoration functionality
- Error handling and logging

### 3. Install.sh

TODO: Install.sh is a helper script that simplifies the setup process by:

- Installing dependencies (if needed)
- Setting up configuration files
- Installing systemd units for automated backups

## Prerequisites

Know about these stuff:

- Bash shell
- GnuPG (gpg)
- Tar utility
- Systemd (for using timers)

## Manual Installation

Refer to the future (TODO) Install.sh

## Note

systemctl --user status bacrypt.timer

## Logging

Bacrypt logs activity using systemd's journalctl. To view the logs, use the following command:

journalctl -p5 --user-unit bacrypt.service
