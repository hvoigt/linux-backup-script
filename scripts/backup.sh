#!/bin/bash
target=/mnt/ftp
src=/home/git
#src="$HOME"
max_backups=30
backup_id=$(date +%Y-%m-%d_%H.%M.%S)

echo -e "\n\n### $(date +%d.%m.%Y-%H:%M:%S) Backup gestartet"

function error {
    echo -e "\n\nFEHLER aufgetreten... bitte Heiko anrufen!"
    exit 1
}

function delete_old_backups {
    while read i; do
        # zur sicherheit die form des dateinamens überprüfen
        if ! echo $i | egrep "^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}" > /dev/null
        then
            echo "Löschen alter Backups: '$i' ist kein valider Backupname"
            return 1
        fi
        echo "Lösche $target/$(hostname)/$i"
        rm -rf $target/$(hostname)/$i
    done
}

do_backup () {
    if [ -d "$target" ]; then
        dst="$target/$(hostname)"
        list_backups=$(mktemp)
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

	tar cvjf $dst/home-git-$backup_id.tbz $EXCLUDE_OPTION \
		$src/ || error

        echo -e "\n\nAlles Ok, Backup fertig!"
    else
        echo "Keine Backup Festplatte angeschlossen."
        echo ""
    fi
}

logname="$target/$(hostname)/log/backup_$backup_id.log"
if [ ! -d "$(dirname "$logname")" ];then
	mkdir -p "$(dirname "$logname")"
fi

do_backup >$logname
