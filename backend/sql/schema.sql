-- ============================================================
-- LocalMarket - database schema (matches SRS Section 4.5)
-- Run this whole file in MySQL Workbench to (re)create the database.
-- WARNING: the DROP statements delete existing data. That is
-- intentional so you can reset the database while developing.
-- ============================================================

CREATE DATABASE IF NOT EXISTS localmarket
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE localmarket;

-- Drop in REVERSE dependency order: a table that holds a foreign key
-- must be dropped before the table it points to.
DROP TABLE IF EXISTS PAYMENT;
DROP TABLE IF EXISTS FAVORITE;
DROP TABLE IF EXISTS AD_IMAGE;
DROP TABLE IF EXISTS AD;
DROP TABLE IF EXISTS CATEGORY;
DROP TABLE IF EXISTS BUSINESS;
DROP TABLE IF EXISTS USER;

-- Create in dependency order: referenced tables first.

CREATE TABLE USER (
  user_id       INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('user','business','admin') NOT NULL DEFAULT 'user',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE BUSINESS (
  business_id   INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT NOT NULL UNIQUE,
  business_name VARCHAR(150) NOT NULL,
  city          VARCHAR(100) NOT NULL,
  phone         VARCHAR(20),
  verified      BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE CATEGORY (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(80) NOT NULL UNIQUE,
  slug        VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE AD (
  ad_id       INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  category_id INT NOT NULL,
  title       VARCHAR(150) NOT NULL,
  description TEXT,
  price       DECIMAL(10,2) NOT NULL,
  city        VARCHAR(100) NOT NULL,
  status      ENUM('pending','approved','promoted','rejected','removed')
              NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES BUSINESS(business_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES CATEGORY(category_id),
  INDEX idx_city (city),
  INDEX idx_category (category_id)
) ENGINE=InnoDB;

CREATE TABLE AD_IMAGE (
  image_id  INT AUTO_INCREMENT PRIMARY KEY,
  ad_id     INT NOT NULL,
  image_url VARCHAR(255) NOT NULL,
  FOREIGN KEY (ad_id) REFERENCES AD(ad_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE FAVORITE (
  favorite_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  ad_id       INT NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_ad (user_id, ad_id),
  FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
  FOREIGN KEY (ad_id)   REFERENCES AD(ad_id)     ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE PAYMENT (
  payment_id  INT AUTO_INCREMENT PRIMARY KEY,
  business_id INT NOT NULL,
  ad_id       INT NOT NULL,
  amount      DECIMAL(10,2) NOT NULL,
  status      ENUM('pending','completed','failed') NOT NULL DEFAULT 'completed',
  method      VARCHAR(50) DEFAULT 'simulated',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (business_id) REFERENCES BUSINESS(business_id),
  FOREIGN KEY (ad_id)       REFERENCES AD(ad_id)
) ENGINE=InnoDB;
