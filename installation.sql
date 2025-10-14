-- Create fines table
CREATE TABLE IF NOT EXISTS `mdt_fines` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `amount` INT NOT NULL,
    `status` VARCHAR(20) DEFAULT 'unpaid',
    `officername` VARCHAR(100) NOT NULL,
    `officerjob` VARCHAR(50) NOT NULL,
    `date` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create weapons table
CREATE TABLE IF NOT EXISTS `mdt_weapons` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner_name` VARCHAR(100) NOT NULL,
    `weapon_name` VARCHAR(50) NOT NULL,
    `serial_number` VARCHAR(50) NOT NULL UNIQUE,
    `registered_by` VARCHAR(100) NOT NULL,
    `date` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_owner` (`owner_name`),
    INDEX `idx_serial` (`serial_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS `idx_status_citizenid` ON `mdt_fines` (`status`, `citizenid`);
CREATE INDEX IF NOT EXISTS `idx_weapon_owner` ON `mdt_weapons` (`owner_name`, `serial_number`);