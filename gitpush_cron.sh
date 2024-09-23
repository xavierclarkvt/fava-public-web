#!/bin/bash
### this is required for beancount to not repeatedly see "File Has Changed"
cd /opt/data/bean 

if [[ `git status --porcelain` ]]; then
	# How many seconds before file is deemed "older"
	OLDTIME=800
	CURTIME=$(date +%s)
	for FILE in *; do
		FILETIME=$(stat $FILE -c %Y)
		TIMEDIFF=$(expr $CURTIME - $FILETIME)
		if [[ $TIMEDIFF -lt $OLDTIME ]]; then 
			return 1 2>/dev/null || exit "1"
		fi
	done

	echo "Files edited long enough ago, push now"
	git stash save
	git pull --rebase
	git stash pop || true
	git add .
	git commit -m "Automatic Commit $(date)"
	git push -f
fi