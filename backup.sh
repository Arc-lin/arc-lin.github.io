date=`date`
git checkout master
git add .
git commit -am "Backup-$date"
git push backup master

