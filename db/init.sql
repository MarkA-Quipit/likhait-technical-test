-- Create database if not exists
CREATE DATABASE IF NOT EXISTS expense_system_development CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE expense_system_development;

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  date DATE NOT NULL DEFAULT (CURRENT_DATE),
  category_id INT NOT NULL,
  payer_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
  INDEX idx_category_id (category_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed categories
INSERT INTO categories (name) VALUES
  ('Food'),
  ('Transport'),
  ('Supplies'),
  ('Entertainment'),
  ('Utilities')
ON DUPLICATE KEY UPDATE name=name;

-- Seed expenses
INSERT INTO expenses (description, amount, category_id, payer_name) VALUES
  ('Team Lunch at Italian Restaurant', 1500.50, 1, 'John Doe'),
  ('Grab to Client Meeting', 350.00, 2, 'Jane Smith'),
  ('Office Supplies - Pens and Paper', 450.75, 3, 'Mike Johnson'),
  ('Team Building Dinner', 2800.00, 1, 'Sarah Lee'),
  ('Taxi to Airport', 800.00, 2, 'John Doe'),
  ('Coffee and Snacks for Meeting', 250.25, 1, 'Emily Chen'),
  ('Printer Ink Cartridges', 680.00, 3, 'Mike Johnson'),
  ('Uber for Site Visit', 420.50, 2, 'Jane Smith'),
  ('Client Lunch Meeting', 1850.00, 1, 'Sarah Lee'),
  ('Office Cleaning Supplies', 320.00, 3, 'Emily Chen'),
  ('Team Movie Night', 1200.00, 4, 'John Doe'),
  ('Internet Bill', 2500.00, 5, 'Mike Johnson'),
  ('Breakfast Meeting with Client', 580.00, 1, 'Jane Smith'),
  ('Bus Tickets for Conference', 150.00, 2, 'Sarah Lee'),
  ('Electricity Bill', 3200.00, 5, 'Emily Chen');