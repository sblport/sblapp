-- SQL Migration to add order_by column to eqp_tasks table

-- Add the order_by column (nullable, references organizations table)
ALTER TABLE `eqp_tasks` 
ADD COLUMN `order_by` INT(11) UNSIGNED NULL DEFAULT NULL 
AFTER `remarks`;

-- Optional: Add foreign key constraint if organizations table exists
-- Uncomment if you want to enforce referential integrity
-- ALTER TABLE `eqp_tasks` 
-- ADD CONSTRAINT `fk_eqp_tasks_order_by` 
-- FOREIGN KEY (`order_by`) REFERENCES `orgs`(`id`) 
-- ON DELETE SET NULL 
-- ON UPDATE CASCADE;

-- Add index for better query performance
CREATE INDEX `idx_eqp_tasks_order_by` ON `eqp_tasks`(`order_by`);
