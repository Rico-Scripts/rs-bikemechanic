-- =========================================================
-- RS MECHANIC
-- DATABASE
-- =========================================================

CREATE TABLE IF NOT EXISTS `rs_bikemechanic_service_history` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(12) NOT NULL,
    `mechanic_identifier` VARCHAR(100) NOT NULL,
    `mechanic_name` VARCHAR(100) NOT NULL,
    `service_name` VARCHAR(100) NOT NULL,
    `serviced_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_service_plate` (`plate`),
    INDEX `idx_service_identifier` (`mechanic_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `rs_bikemechanic_vehicle_software` (
    `plate` VARCHAR(12) NOT NULL,
    `antilag` TINYINT(1) NOT NULL DEFAULT 0,
    `launch_control` TINYINT(1) NOT NULL DEFAULT 0,
    `stage` INT NOT NULL DEFAULT 0,
    `sport_exhaust` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `rs_dyno_history` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(12) NOT NULL,
    `model` VARCHAR(64) NOT NULL,
    `mechanic_identifier` VARCHAR(100) NOT NULL,
    `mechanic_name` VARCHAR(100) NOT NULL,
    `horsepower` INT NOT NULL DEFAULT 0,
    `torque` INT NOT NULL DEFAULT 0,
    `top_speed` INT NOT NULL DEFAULT 0,
    `zero_to_hundred` DECIMAL(6,2) NOT NULL DEFAULT 0.00,
    `tested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_dyno_plate` (`plate`),
    INDEX `idx_dyno_identifier` (`mechanic_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
