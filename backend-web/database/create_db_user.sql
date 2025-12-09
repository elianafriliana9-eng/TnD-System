-- ============================================
-- Create Dedicated Database User for TND System
-- Run this in MySQL/phpMyAdmin
-- ============================================

-- 1. Create new user with strong password
-- CHANGE 'strong_password_here' to a secure password!
CREATE USER IF NOT EXISTS 'tnd_user'@'localhost' IDENTIFIED BY 'strong_password_here';

-- 2. Grant specific privileges (NOT ALL PRIVILEGES)
-- Only grant what's needed for the application
GRANT SELECT, INSERT, UPDATE, DELETE ON tnd_system.* TO 'tnd_user'@'localhost';

-- 3. Apply changes
FLUSH PRIVILEGES;

-- 4. Verify user was created
SELECT User, Host FROM mysql.user WHERE User = 'tnd_user';

-- 5. Verify privileges
SHOW GRANTS FOR 'tnd_user'@'localhost';

-- ============================================
-- AFTER CREATING USER:
-- 1. Update .env file:
--    DB_USERNAME=tnd_user
--    DB_PASSWORD=strong_password_here
--
-- 2. Test connection using new credentials
--
-- 3. If everything works, you can optionally remove root access
--    (NOT recommended for local development, only for production)
-- ============================================

-- Optional: For production deployment only
-- Drop old root access after confirming new user works
-- DROP USER 'root'@'localhost'; -- DON'T RUN THIS IN DEVELOPMENT!
