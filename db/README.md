4. Your overall setup
The sequence for a new installation is:

Install MariaDB.

Run sudo mariadb-secure-installation and answer the security questions.

Verify the MariaDB version.

Create the sportscars database.

Create tables and insert your sports car data.

===========================================
#STEP-01
==========================================
Step 1: Log in to MariaDB on your server
======================================
bash
sudo mariadb

Step 2: Check your existing databases and users
SHOW DATABASES;
sql
SELECT User, Host FROM mysql.user;
sql
SHOW VARIABLES LIKE 'bind_address';
SHOW VARIABLES LIKE 'port';

=======================================================
#STEP-02
===================================================
Step 2 — Run these checks first
=====================================================
You are currently inside the MariaDB prompt (MariaDB [(none)]>). Run these commands one at a time:

sql
SHOW DATABASES;
sql
SHOW GRANTS FOR 'caradmin'@'localhost';
sql
SHOW VARIABLES LIKE 'bind_address';
sql
SHOW VARIABLES LIKE 'skip_networking';
