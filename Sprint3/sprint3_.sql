CREATE SCHEMA IF NOT EXISTS `sprint3_silver`
OPTIONS (
  location = 'EU',
  description = 'Dades netes, tipades i deduplicades'
);
-- tema delicado son los separados con `` comillas en forma de acento...

-- transactions_raw: delimitador punto y coma
CREATE EXTERNAL TABLE `sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';',
  skip_leading_rows = 1
);

-- companies todo texto. Hay que definir la tabla.
-- he bajado el archivo del bucket con este enlace: 

-- https://storage.cloud.google.com/bootcamp-data-analytics-public/ERP/companies.csv
-- la cabecera es esta: company_id,company_name,phone,email,country,website

CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.companies_raw` (
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

-- creamos tabla american_users_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1
);

-- creamos tabla european_users_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1
);

-- creamos tabla credit_cards_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1
);

-- comprobar todas las tablas del dataset bronze:
SELECT
  table_name,
  table_type
FROM `sprint3_bronze.INFORMATION_SCHEMA.TABLES`
ORDER BY table_name;

-- Exercici 4
-- crea una tabla en el dataset sprint3_bronze con el nombre sprint3_bronze.transactions_raw_native. 
-- Esta tabla debe tener los datos de transactions_raw. Utiliza CREATE OR REPLACE TABLE para evitar errores 
-- en caso de que tenga que repetir la consulta más adelante.
CREATE OR REPLACE TABLE
  `sprint3-analytics-jaume`.`sprint3_bronze`.`transactions_raw_native` AS
SELECT
  *
FROM
  `sprint3-analytics-jaume`.`sprint3_bronze`.`transactions_raw`;

-- consulta de transactions externa
SELECT * FROM `sprint3-analytics-jaume.sprint3_bronze.transactions_raw`;

-- consulta de transactions amb dades locals
SELECT * FROM `sprint3-analytics-jaume.sprint3_bronze.transactions_raw_native`;


-- comparar cost de consultes amb o sense LIMIT 10
SELECT * FROM `sprint3-analytics-jaume.sprint3_bronze.transactions_raw_native`;

SELECT * FROM `sprint3-analytics-jaume.sprint3_bronze.transactions_raw_native` LIMIT 10;

Ejercicio 5

-- Las tablas externas solo admiten lectura
-- creo una tabla nativa con el resultado transformado

SELECT 
  DATE(timestamp) AS fecha,
  SUM(amount) AS total_ingresos
FROM `sprint3-analytics-jaume.sprint3_bronze.transactions_raw_native`
WHERE -- en la consulta nos interesa solo el año 2021. Aplicamos el EXTRACT.
  EXTRACT(YEAR FROM CAST(timestamp AS TIMESTAMP)) = 2021 AND declined = 0
GROUP BY fecha
ORDER BY total_ingresos DESC
LIMIT 5;

-- Exercici 6
SELECT comp.company_name, comp.country, cant.amount, DATE(cant.timestamp) 
FROM `sprint3-analytics-jaume.sprint3_bronze.transactions_raw` AS cant
INNER JOIN `sprint3-analytics-jaume.sprint3_bronze.companies_raw` AS comp
ON cant.business_id = comp.company_id
WHERE cant.amount BETWEEN 100 AND 200 AND 
  (DATE(cant.timestamp) = '2015-04-29' OR DATE(cant.timestamp) = '2018-07-28' OR DATE(cant.timestamp) = '2024-03-13');


-- NIVELL 2
-- Exercici 1
CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id, -- eliminamos el WH- y lo pasamos a INT64
  SAFE_CAST(price AS FLOAT64) AS price,
  colour,
  weight,
  category,
  brand,
  cost,
  launch_date
FROM `sprint3-analytics-jaume.sprint3_bronze.products_raw`;

-- Exercici 2
CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  CAST(timestamp AS TIMESTAMP) AS timestamp, -- hacemos casting sin cambiar el nombre
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,  -- aquí ponemos 0 caso de encontrar un NULL, si no mantiene el valor
  declined,
  ARRAY(
    SELECT SAFE_CAST(TRIM(item_id) AS INT64) -- eliminamos los espacios
    FROM UNNEST(SPLIT(product_ids, ',')) AS item_id -- desempaquetamos los valores del array a partir de la coma
  ) AS products, -- los product_ids aplanados se escriben en la columna products
  user_id,
  SAFE_CAST(lat AS FLOAT64) AS latitude,
  SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-jaume.sprint3_bronze.transactions_raw_native`;

-- Ejercicio 3

CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_silver.users_combined` AS
SELECT 
  id AS user_id,
  name, surname, phone, email, birth_date, country, city, postal_code, address,
  'america' AS origin -- añadimos columna para no perder información al final
FROM `sprint3-analytics-jaume.sprint3_bronze.american_users_raw`
UNION ALL -- unimos las dos tablas
SELECT 
  id AS user_id,
  name, surname, phone, email, birth_date, country, city, postal_code, address,
  'europa' AS origin -- añadimos columna para no perder información al final
FROM `sprint3-analytics-jaume.sprint3_bronze.european_users_raw`;

-- Ejercicio 4

CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_silver.companies_clean` AS
SELECT 
  company_id, -- O id AS company_id segun la tabla en bronce
  company_name, phone, email, country, website
FROM `sprint3-analytics-jaume.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_silver.credit_cards_clean` AS
SELECT 
  id AS card_id, -- modificamos el campo id
  user_id, iban, pan, pin, cvv, track1, track2, expiring_date
FROM `sprint3-analytics-jaume.sprint3_bronze.credit_cards_raw`;

-- Nivel 3. 
-- Ejercicio 1.
CREATE OR REPLACE VIEW `sprint3_gold.v_marketing_kpis` AS
SELECT company_name, phone, country, ROUND(AVG(trans.amount),2) AS media_amount,
  CASE
    WHEN ROUND(AVG(trans.amount),2) > 260 THEN 'Premium'
    ELSE 'Standar'
  END AS client_tier
FROM `sprint3-analytics-jaume.sprint3_silver.companies_clean` AS companies
INNER JOIN `sprint3-analytics-jaume.sprint3_silver.transactions_clean` AS trans ON companies.company_id = trans.business_id
WHERE declined = 0
GROUP BY company_name, phone, country;

-- consulta de la VIEW
SELECT * 
FROM `sprint3-analytics-jaume.sprint3_gold.v_marketing_kpis`
ORDER BY 
  client_tier ASC, -- 'Premium' va abans que 'Standard' alfabèticament
  media_amount DESC;

-- Ejercicio 2

CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_gold.product_sales_ranking` AS
WITH aplanar_array AS (
  SELECT 
    prod_id -- prod_id ya es INT64 gracias a la conversión en Silver
  FROM 
    `sprint3-analytics-jaume.sprint3_silver.transactions_clean`,
    UNNEST(products) AS prod_id
  WHERE declined = 0 -- Solo contamos productos de transacciones válidas
)

SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour,
  IFNULL(COUNT(t.prod_id), 0) AS total_sold
FROM
  `sprint3-analytics-jaume.sprint3_silver.products_clean` AS p
LEFT JOIN 
  aplanar_array AS t ON p.product_id = t.prod_id -- Comparación directa de INT64 con INT64
GROUP BY p.product_id, p.name, p.price, p.colour
ORDER BY total_sold DESC;

