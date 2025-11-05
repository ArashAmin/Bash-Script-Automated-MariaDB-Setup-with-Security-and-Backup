#!/bin/bash

# Automated MariaDB Setup Script for Ubuntu Server
# Installs MariaDB, secures it, creates a sample database/table,
# and sets up daily backup cron job. Run with sudo.

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Run this script with sudo."
   exit 1
fi

DB_ROOT_PASS="DbRoot2025!"  # Change this in production!
DB_NAME="company_db"

echo "Starting MariaDB setup..."

# Step 1: Update and install MariaDB
apt update -y
apt install mariadb-server -y
systemctl enable mariadb
systemctl start mariadb

# Step 2: Secure installation
mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$DB_ROOT_PASS');"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

echo "MariaDB secured with root password: $DB_ROOT_PASS"

# Step 3: Create sample database and table
mysql -u root -p$DB_ROOT_PASS -e "
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE
);
INSERT INTO employees (name, email) VALUES ('Test User', 'test@company.com');
"

# Step 4: Initial backup
mysqldump -u root -p$DB_ROOT_PASS $DB_NAME > /home/arri/initial_backup.sql
echo "Initial backup created: /home/arri/initial_backup.sql"

# Step 5: Setup daily cron backup
(crontab -l 2>/dev/null; echo "0 2 * * * mysqldump -u root -p$DB_ROOT_PASS $DB_NAME > /home/arri/backup_\$(date +\%Y\%m\%d).sql") | crontab -
echo "Daily backup cron job added (2 AM)."

# Step 6: Test query
if mysql -u root -p$DB_ROOT_PASS -e "USE $DB_NAME; SELECT * FROM employees;" | grep -q "Test User"; then
    echo "Database test: PASSED"
else
    echo "Database test: FAILED"
fi

echo "Setup completed! MariaDB is ready with sample data."
echo "Test connection: sudo mysql -u root -p$DB_ROOT_PASS"
