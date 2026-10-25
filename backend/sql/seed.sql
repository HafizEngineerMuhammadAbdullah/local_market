-- ============================================================
-- LocalMarket - starter data
-- Run AFTER schema.sql. Safe to run once; running it twice will
-- fail on the UNIQUE constraints (that is the constraints working).
-- Users, businesses and sample ads are added in later slices,
-- because user rows need a hashed password produced by the API.
-- ============================================================

USE localmarket;

INSERT INTO CATEGORY (name, slug) VALUES
  ('Electronics',   'electronics'),
  ('Vehicles',      'vehicles'),
  ('Property',      'property'),
  ('Jobs',          'jobs'),
  ('Services',      'services'),
  ('Fashion',       'fashion'),
  ('Home & Garden', 'home-garden');
  
  
SELECT * FROM USER;
SELECT * FROM PAYMENT;
SELECT * FROM FAVORITE;
SELECT * FROM CATEGORY;
SELECT * FROM BUSINESS;
SELECT * FROM AD_IMAGE;
SELECT * FROM AD;
