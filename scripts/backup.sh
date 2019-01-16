#!/bin/bash
target=/mnt/ftp
src="/home /var/lib/ejabberd /root"
max_backups=30
backup_id=$(date +%Y-%m-%d_%H.%M.%S)
ftp_host=ftp.example.com

function error {
    echo -e "\n\nFEHLER aufgetreten..." 1>&2
    exit 1
}

function delete_old_backups {
    while read i; do
        # zur sicherheit die form des dateinamens überprüfen
        if ! echo $i | egrep "^backup-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}" > /dev/null
        then
            echo "Löschen alter Backups: '$i' ist kein valider Backupname"
            return 1
        fi
        echo "Lösche $target/$(hostname)/$i|log"
        rm $target/$(hostname)/$i
        rm $target/$(hostname)/log/${i/%tbz/log}
    done
}

ensure_mount_ftp () {
	if ! mount | grep /mnt/ftp >/dev/null
	then
		curlftpfs $ftp_host $target
	fi
}

do_backup () {
    echo -e "\n\n### $(date +%d.%m.%Y-%H:%M:%S) Backup gestartet"

    if [ -d "$target" ]; then
        dst="$target/$(hostname)"
        list_backups=$(mktemp)
        ignore_sockets=$(mktemp)
        if [ ! -d "$dst" ]; then
    	mkdir "$dst" || exit 1
        fi
        (cd "$dst" && ls -1 > $list_backups || error )
        # Wir können latest ruhig mitzählen da wir
        # ein mehr für das neue Backup löschen müssen
        # sodass wir am Ende immer $num_backups Backups haben
        num_backups=$(cat $list_backups | wc -l)

        if [ $num_backups -gt $max_backups ]; then
            to_delete=$[$num_backups - $max_backups]
            echo "Wir haben $num_backups Backups lösche die ersten $to_delete"
            head -n $to_delete $list_backups | delete_old_backups || error
        fi

        if [ -f "$HOME/.backup-exclude" ]; then
                EXCLUDE_OPTION="--exclude-from $HOME/.backup-exclude"
	fi

        find $src -type s >$ignore_sockets
        EXCLUDE_OPTION="$EXCLUDE_OPTION --exclude-from $ignore_sockets"
	tar cvf $dst/backup-$backup_id.tgz -I pigz $EXCLUDE_OPTION \
		$src 2>&1 || error

        echo -e "\n\nAlles Ok, Backup fertig!"
	rm $list_backups $ignore_sockets
    else
        echo "Keine Backup Festplatte angeschlossen."
        echo ""
    fi
}

ensure_mount_ftp

logname="$target/$(hostname)/log/backup-$backup_id.log"
if [ ! -d "$(dirname "$logname")" ];then
	mkdir -p "$(dirname "$logname")"
fi

do_backup >$logname

umount $target
