# Simple (but complete) Linux Backup Script

This is a simple backup script which started as a backup solution that should not need further maintenance, since it is used by my parents to backup their data. It is a complete solution to backup the home folder of a computer to an external drive formatted with a filesystem that can store the attributes of the source filesystem.

## Features

  * Incremental but with complete folders like with Time Maschine from Apple
  * Deduplication of files with hardlinks
  * Configurable amount of backups that should be kept
  * Can be stored on the external harddrive for documentation
  * No local temporary storage needed
  
## Configuration

Either

  1. Mount you backup drive under `/media/Backup` and just run `./scripts/backup.sh`
  
or

  2. Have a look at the top of [scripts/backup.sh](scripts/backup.sh) there are some configuration variables to tweak and specify source and target folders, etc.

# Server support

There is some server support for backup to tar files saved directly on a FTP Server on the [_server_](https://github.com/hvoigt/linux-backup-script/tree/server) branch. This works well but is probably very specific to my use case. Just in case someone is interested in this.
