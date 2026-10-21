-- SPRINT 4
-- Ejercicio 1

SELECT DATE(timestamp) AS fecha, transaction_id, company_name, country
FROM `sprint3-analytics-jaume.sprint3_silver.transactions_clean` AS t
INNER JOIN `sprint3-analytics-jaume.sprint3_silver.companies_clean`AS c ON t.business_id = c.company_id
WHERE c.country =  'Germany' AND DATE(timestamp) = '2022-03-22';

-- Ejercicio 2
-- creamos la tabla transactions.recent 
CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_silver.transactions_recent` AS
SELECT
  * EXCEPT(timestamp), -- modificamos la fecha a partir de la fecha actual (la del momento que se ejecuta el script)
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(),INTERVAL CAST(FLOOR(RAND() * 50) AS INT64) DAY) AS timestamp_random
FROM `sprint3-analytics-jaume.sprint3_silver.transactions_clean`;

-- creamos la tabla optimizada:
CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp_random) --particionamos a partir de la fecha
CLUSTER BY business_id AS --ordenamos cada particion a partir de la id de la compañia
SELECT *
FROM `sprint3-analytics-jaume.sprint3_silver.transactions_recent`
WHERE declined = 0;

  -- Ejercicio 3.

  -- Realizamos las consultas
SELECT *
FROM `sprint3-analytics-jaume.sprint3_silver.transactions_recent`
WHERE DATE(timestamp_random) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE() AND declined = 0;

SELECT *
FROM `sprint3-analytics-jaume.sprint3_gold.fact_transactions_optimized`
WHERE DATE(timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE() AND declined = 0;

-- Ejercicio 4
-- creamos la materialized view:

CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-jaume.sprint3_gold.mv_daily_sales` AS
SELECT DATE(timestamp_random) AS date,SUM(amount) AS total_import
FROM `sprint3-analytics-jaume.sprint3_gold.fact_transactions_optimized`
GROUP BY DATE(timestamp_random);

-- y la consulta sobre la vista:

SELECT DATE(timestamp_random) AS Data,ROUND(total_import,2) AS total_import
FROM `sprint3-analytics-jaume.sprint3_gold.mv_daily_sales`
ORDER BY DATE(timestamp_random);

-- Nivel 2. Ejercicio 1
-- creamos la CTE
WITH VIP_Stats AS (
  SELECT
    user_id,
    ROUND(SUM(amount),2) AS gasto_total,
    COUNT(*) AS num_transacciones,
    ROUND(AVG(amount), 2) AS tiquet_medio,
    MAX(amount) AS compra_max
  FROM `sprint3-analytics-jaume.sprint3_silver.transactions_clean`
  GROUP BY user_id
  HAVING SUM(amount) > 500
)
SELECT * -- y la consultamos para comprvar que es correcta
FROM VIP_Stats;

-- Ahora cruzamos con la tabla de usuarios

WITH VIP_Stats AS (
  SELECT
    user_id,
    ROUND(SUM(amount),2) AS gasto_total,
    COUNT(*) AS num_transacciones,
    ROUND(AVG(amount), 2) AS tiquet_medio,
    MAX(amount) AS compra_max
  FROM `sprint3-analytics-jaume.sprint3_silver.transactions_clean`
  WHERE declined = 0 -- aseguramos solo las transacciones válidas
  GROUP BY user_id
  HAVING SUM(amount) > 500 -- usamos HAVING al tener la agregación
)

SELECT 
  u.user_id, -- tenemos que especificar de dónde saca este usuario o hay ambiguedad!
  CONCAT(u.name, ' ', u.surname) AS nom_complet, -- nombre y apellidos concatenados con un espacio en medio
  email, 
  num_transacciones, 
  tiquet_medio, 
  compra_max, 
  gasto_total 
FROM `sprint3-analytics-jaume.sprint3_silver.users_combined` AS u
INNER JOIN VIP_stats AS v ON v.user_id = u.user_id
ORDER BY gasto_total DESC;

-- Ejercicio 2

WITH ventas_dia AS (
  SELECT 
    DATE(timestamp_random) AS fecha,
    ROUND(SUM(total_import), 2) AS ventas_hoy
  FROM `sprint3-analytics-jaume.sprint3_gold.mv_daily_sales` -- view materializada
  GROUP BY DATE(timestamp_random)
)

SELECT 
  fecha,
  ventas_hoy,
  LAG(ventas_hoy) OVER (ORDER BY fecha ASC) AS ventas_ayer, -- función ventana, LAG mira en la fila anterior a medida que recorre la tabla y la escribe en ventas_ayer
  ROUND(
    ((ventas_hoy - LAG(ventas_hoy) OVER (ORDER BY fecha ASC)) / NULLIF(LAG(ventas_hoy) OVER (ORDER BY fecha ASC), 0)) * 100, 2) AS deferencia_percentil -- aquí es la resta de las ventas del dia actual con el precedente dividido por las ventas del dia anterior y multiplicado por 100, todo implementado por funciones ventana.
FROM 
  ventas_dia
ORDER BY 
  fecha ASC;


-- Ejercicio 3

SELECT
  DATE(timestamp_random) AS data,
  ROUND(total_import, 2)  AS vendes_dia,
  ROUND(SUM(total_import) OVER (
          PARTITION BY EXTRACT(YEAR FROM timestamp_random)
          ORDER BY timestamp_random
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS vendes_ytd
FROM `sprint3-analytics-jaume.sprint3_gold.mv_daily_sales`
ORDER BY data;

-- Ejercicio 4

WITH tres_prim_compras AS (
  SELECT 
    user_id,
    timestamp_random AS data_compra,
    amount AS import_compra,
    -- Numeramos las compras de las transacciones
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp_random ASC) AS num_compra
  FROM `sprint3-analytics-jaume.sprint3_silver.transactions_recent`
-- QUALIFY sobre la función ventana para discrimanr todas las compras posteriores a la 3a compra
-- ahorramos el cálculo innecesario ya que nos piden trabajar SOLO sobre las 3 primeras compras
  QUALIFY num_compra <= 3)

SELECT 
  us.user_id,
  CONCAT(us.name,' ',us.surname) AS nom_complet,
  us.email,
  -- Data e importe de la 3a compra exacta
  MAX(CASE WHEN t.num_compra = 3 THEN t.data_compra END) AS data_3a_compra,
  MAX(CASE WHEN t.num_compra = 3 THEN t.import_compra END) AS import_3a_compra,
  -- AVG de las 3 primeras compras
  ROUND(AVG(t.import_compra), 2) AS mitjana_3_primeres

FROM tres_prim_compras AS t
INNER JOIN `sprint3-analytics-jaume.sprint3_silver.users_combined` AS us ON t.user_id = us.user_id
GROUP BY us.user_id,us.name,us.surname,us.email

-- Con el HAVING COUNT nos quedamos con los usuarios que tienen las 3 compras hechas
HAVING COUNT(t.num_compra) = 3
ORDER BY data_3a_compra ASC;

-- Nivel 3. Ejercicio 1.

CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_gold.dim_transactions_flat` AS -- trabajamos en Gold
WITH desglose AS ( -- creamos la CTE que hace el desglose  de productos
  SELECT 
    transaction_id,
    user_id,
    timestamp,
    amount AS total_import,
    -- Desempaquetamos el array 'products' de transactions_clean
    id_prod AS product_id
  FROM `sprint3-analytics-jaume.sprint3_silver.transactions_clean`
    CROSS JOIN UNNEST(products) AS id_prod
)

SELECT -- el inner join para conseguir el nombre del producto
  d.transaction_id,
  d.user_id,
  d.timestamp,
  d.total_import,
  d.product_id,
  p.name AS product_name,
  p.price AS unit_price
FROM desglose AS d -- invocamos la CTE
INNER JOIN `sprint3-analytics-jaume.sprint3_silver.products_clean` AS p
  ON d.product_id = p.product_id;

-- Ejercicio 2

SELECT product_id, product_name, COUNT(*) AS cantidad_unds
FROM `sprint3-analytics-jaume.sprint3_gold.dim_transactions_flat` 
GROUP BY product_id, product_name
ORDER BY cantidad_unds DESC
LIMIT 5;

-- Ejercicio 3

-- creamos la función 
CREATE OR REPLACE FUNCTION `sprint3-analytics-jaume.sprint3_gold.calculate_tax`(base FLOAT64, percentatge_iva FLOAT64)
RETURNS FLOAT64 AS (
  ROUND(base * (1 + (percentatge_iva / 100.0)), 2)
);

-- Consulta con la función permanente (UDF)
SELECT 
  product_name,
  unit_price, -- solo antes de invocar la UDF que podemos modificar el porcentaje de cálculo
  `sprint3-analytics-jaume.sprint3_gold.calculate_tax`(unit_price, 21.0) AS CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_gold.dim_transactions_flat` AS
WITH desglose AS (
  SELECT 
    transaction_id,
    user_id,
    timestamp,
    amount AS total_import,
    id_prod AS product_id
  FROM `sprint3-analytics-jaume.sprint3_silver.transactions_clean`
  CROSS JOIN UNNEST(products) AS id_prod
)
SELECT 
  d.transaction_id,
  d.user_id,
  d.timestamp,
  d.total_import,
  d.product_id,
  p.name AS product_name,
  p.price AS unit_price,
  `sprint3-analytics-jaume.sprint3_gold.calculate_tax`(p.price, 21.0) AS product_price_tax_inc
FROM desglose AS d
INNER JOIN `sprint3-analytics-jaume.sprint3_silver.products_clean` AS p
  ON d.product_id = p.product_id;
FROM `sprint3-analytics-jaume.sprint3_gold.dim_transactions_flat`;

-- Creamos tabla en la consulta para que se pueda usar en Looker
CREATE OR REPLACE TABLE `sprint3-analytics-jaume.sprint3_gold.consulta_diaria_ventas` AS
SELECT 
  transaction_id,
  product_name,
  unit_price, -- es antes de invocar la UDF que podemos modificar el porcentaje del IVA
  `sprint3-analytics-jaume.sprint3_gold.calculate_tax`(unit_price, 21.0) AS product_price_tax_inc
FROM `sprint3-analytics-jaume.sprint3_gold.dim_transactions_flat`;


