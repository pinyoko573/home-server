# Make sure rclone is configured to a cloud provider you use e.g. https://rclone.org/drive/

# This script backups the 'ghost' schema in mysql running in docker and other files.
# Put it in /etc/cron.weekly or so!

# Create tmp folder
mkdir /tmp/backup

# mysql backup
## Check if mysql container is running, else start the container
mysql_is_already_running=0
if docker ps | grep 'mysql'; then
  mysql_is_already_running=1
else
  docker compose up mysql -d
fi

## Perform database dump
sql_container_id=$(docker ps -aqf "name=mysql")
docker exec $sql_container_id /usr/bin/mysqldump -u root --password={{MYSQL_PASSWORD}} ghost > /tmp/backup/ghost_backup.sql

## Stop docker if mysql was started by this script
if [ $mysql_is_already_running -eq 0 ]; then
  docker compose down mysql
fi

# All other backups
tar -C /foo/files/ -czf /tmp/backup/files.tar.gz .

# Export backup to drive
rclone copy /tmp/backup remote:ubuntu-server-backup --config rclone.conf

# Delete tmp folder
rm -r /tmp/backup