# Bacrypt - Backup and Encrypt Files Suite

Bacrypt is a suite of bash scripts for backing up and encrypting files.

The encrypted files intended to be store online at github, so the files name are masked (to hide embarassing file name).

plain_file.txt -> tar (archived to preserve filename, date, etc.) -> encrypted by GnuPG -> filename in sha256sum hash.

GnuPG id (ie. pro7357@protonmail.com) is used to pad the file name before converted to sha256sum hash. Keep the id secret for maximum privacy.

## Components

### 1. timed.sh

timed.sh automatically backing up and encrypting files on a predefined schedule using systemd timers.

### 2. bacrypt.sh

TODO: bacrypt.sh is a more comprehensive script that includes additional features such as:

- Interactive configuration setup
- Manual backup and encryption options
- File restoration functionality
- Error handling and logging

P/s: ChatGPT think too highly of me. bacrypt.sh is just the way to manual backup and restore.

### 3. install.sh

TODO.. But not really. See manual install.

install.sh is a helper script that simplifies the setup process by:

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

copy all the files to your encrypt folder. (ie /home/bacrypt/)

copy bacrypt.timer and bacrypt.service to "$HOME/.config/systemd/user/" (create the directory if it not exist. user is literal 'user').

edit bacrypt.service to point to correct location of timed.sh

edit bacrypt.timer to change the timing. default is 10 minutes.

copy config to "$HOME/.config/bacrypt/config"

change the config file base on your setup.

### example config file
``` bash
# location for main encrypt directory
bacrypt="/home/bacrypt"

# key_id is your GnuPG id. Create a new one if you don't have any.
key_id="pro7357@protonmail.com"

# base_paths is array of directory that you wish to backup and encrypt.
# ie. directory bash and python directories will be backup and encrypt to  "/home/bacrypt/bash" and "/home/bacrypt/python"
base_paths=("$HOME/bash" "$HOME/python")
```

### continue installation

go to bacrypt directory. ie /home/bacrypt

create new directory for encrypted file. ie /home/bacrypt/python and /home/bacrypt/bash

enter newly created directory then run these bash code to create sub-directory 00 to ff, all 256 of them.

``` bash
# Function to create directories '00' to 'ff'
for i in {0..255}; do
    hex=$(printf "%02x" "$i")
    mkdir -p "$hex"
done
```

installation done! yes, all those directories have to be manually created because i'm too lazy to automate them. i'm the only one using these thing anyway.


## Enable and run

systemctl --user enable --now bacrypt.timer

## Status

systemctl --user status bacrypt.timer

## Logging

Bacrypt logs activity using systemd's journalctl. To view the logs, use the following command:

journalctl -p5 --user-unit bacrypt.service
