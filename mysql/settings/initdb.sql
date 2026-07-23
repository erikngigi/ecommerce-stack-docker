-- Create Databases
CREATE DATABASE IF NOT EXISTS akeneo_db;
CREATE DATABASE IF NOT EXISTS magento_db;

-- Create Users and Assign Passwords
CREATE USER IF NOT EXISTS 'akeneo'@'%' IDENTIFIED BY 'akene0V5Wi1sIX';
CREATE USER IF NOT EXISTS 'magento'@'%' IDENTIFIED BY 'mag3nt0xpv2BezYz';

-- Grant Privileges to Users
GRANT ALL PRIVILEGES ON akeneo_db.* TO 'akeneo'@'%';
GRANT ALL PRIVILEGES ON magento_db.* TO 'magento'@'%';

-- Apply Changes
FLUSH PRIVILEGES;
