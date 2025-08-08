rsync -avzh --delete --exclude='*.log' --exclude='*.git' --exclude='cache/*' --exclude='tmp/*' root@beta.reboot47.xyz:/var/www/morishita/ ~/DEV/morishita/



rsync -avz \
    --exclude 'vendor' \
    --exclude 'var/cache' \
    --exclude 'var/log' \
    --exclude '.git' \
    --exclude 'node_modules' \
    --exclude 'tests' \
    --exclude ‘.’git \
    --exclude 'codeception' \
   ~/DEV/morishita/ \
    root@beta.reboot47.xyz:/var/www/morishita/