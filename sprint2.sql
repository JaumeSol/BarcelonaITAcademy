USE transactions;

-- **** APARTAT 2 ****

-- quantitat per paisos
SELECT country, SUM(amount)
FROM company
INNER JOIN transaction
ON company.id = transaction.company_id
GROUP BY country;

-- contar paisos que fan transaccions
SELECT COUNT(DISTINCT country) AS Total_paisos
FROM company
INNER JOIN transaction
ON company.id = transaction.company_id;

-- companyia amb mitjana més gran de vendes
SELECT company_name AS nom, AVG(amount) AS promig_transaccions
FROM company
INNER JOIN transaction
ON company.id = transaction.company_id
GROUP BY company_name
ORDER BY promig_transaccions DESC
LIMIT 1;

-- **** APARTAT 3 ****

-- transaccions realitzades per empreses d'Alemanya
SELECT company_id, id
FROM transaction AS t
WHERE company_id IN -- és dins del conjunt de companyies alemanyes
	(SELECT id FROM company
    WHERE country = 'Germany');

-- Empreses amb transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT id, company_name  -- para ver el amout habria que hacer una consulta correlacionada
FROM company
WHERE id IN 
	(SELECT company_id
    FROM transaction
    WHERE amount > 
		(SELECT AVG(amount)
		FROM transaction)
	);

-- Llistat empreses que no tenen transaccions registrades
SELECT company_name AS nom_empresa
FROM company
WHERE id NOT IN 
	(SELECT DISTINCT company_id
	FROM transaction);  
-- busco entre todas las empresas con transacciones cuáles no estan en la tabla company
-- el resultado es que todas tienen registros.


-- **** APARTAT 4 ****
CREATE TABLE credit_card (
id VARCHAR(15) PRIMARY KEY, -- para que sea igual que en transaction
iban VARCHAR(50), 
pan VARCHAR(20), 
pin VARCHAR(4), 
cvv VARCHAR(3), 
expiring_date TIMESTAMP -- me da problemas al hacer la fk!
);

ALTER TABLE credit_card CHANGE expiring_date expiring_date VARCHAR(10); -- paso la fecha a carácter

SHOW COLUMNS FROM credit_card; -- pruebo que se ha hecho el cambio de variable en la fecha

ALTER TABLE credit_card ADD COLUMN expiring_date_fmt DATE;

ALTER TABLE transaction -- relaciono tablas
ADD CONSTRAINT fk_transaction_creditcard
FOREIGN KEY (credit_card_id) REFERENCES credit_card(id); -- me da error por registros NULL!!

SET SQL_SAFE_UPDATES = 0; -- quito salvaguarda de datos
UPDATE credit_card
SET expiring_date_fmt = STR_TO_DATE(expiring_date, '%m/%d/%y'); -- modifico la cadena de texto a formato ISO
SET SQL_SAFE_UPDATES = 1; -- vuelvo a activar la salvaguarda de datos

ALTER TABLE credit_card DROP COLUMN expiring_date; -- elimino la columna de fecha en formato VARCHAR
ALTER TABLE credit_card CHANGE expiring_date_fmt expiring_date DATE; -- renombro columna creada antes con fecha formato DATE

ALTER TABLE transaction -- relaciono tablas
ADD CONSTRAINT fk_transaction_creditcard
FOREIGN KEY (credit_card_id) REFERENCES credit_card(id); -- ya no me da error!!

-- **** APARTAT 5 ****

SET SQL_SAFE_UPDATES = 0;
update credit_card set id = 'CcU-2938' where iban = 'TR323456312213576817699999';
SET SQL_SAFE_UPDATES = 1;

select *
from credit_card
where id = 'CcU-2938';

-- **** APARTAT 6 ****

show columns from transaction;
SET FOREIGN_KEY_CHECKS = 0;
INSERT INTO transaction(id, credit_card_id, company_id, user_id, lat, longitude, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 999, 829.999, -117.999, 111.11, 0);
SET FOREIGN_KEY_CHECKS = 1;
select *
from transaction
where credit_card_id = 'CcU-9999';

-- **** APARTAT 7 ****

ALTER TABLE credit_card DROP COLUMN Pan;
SHOW COLUMNS FROM credit_card;

-- **** APARTAT 8 ****

CREATE DATABASE nova_transaction;
USE nova_transaction;

CREATE TABLE transaction (
Id VARCHAR(40) PRIMARY KEY, 
card_id VARCHAR(15), 
business_id VARCHAR(6),
timestamp DATETIME, 
amount DECIMAL(10,2),
declined TINYINT(1), 
product_ids VARCHAR(50), 
user_id INT, 
lat DOUBLE, 
longitude DOUBLE, -- usamos DOUBLE pq son coordenadas y necesitamo alta precisión
discount_amount DECIMAL(10,2), 
tax_amount DECIMAL(10,2), 
shipping_amount DECIMAL(10,2), 
channel VARCHAR(15), 
campaign_id VARCHAR(20), 
device_type VARCHAR(50), 
is_international TINYINT(1), 
decline_reason VARCHAR(50), 
distance_km DECIMAL(10,2)
);

SELECT product_ids FROM transaction LIMIT 10;

SHOW COLUMNS FROM transaction;
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1; -- habilitar la posibilidad de cargar datos locales

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__transactions.csv' -- atención con las barras invertidas!!!
INTO TABLE transaction
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Id, card_id, business_id, timestamp, amount, declined, product_ids, user_id,
 lat, longitude, discount_amount, tax_amount, shipping_amount, channel, campaign_id,
 device_type, is_international, decline_reason, distance_km);
 select * from transactions;

SET SQL_SAFE_UPDATES = 0;
UPDATE transaction
SET decline_reason = NULL -- elimino los '' y sustituyo por NULL
WHERE decline_reason = '';
SET SQL_SAFE_UPDATES = 1;

CREATE TABLE companies (
company_id VARCHAR(6) PRIMARY KEY,
company_name VARCHAR(40),
phone VARCHAR(15),
email VARCHAR(40),
country VARCHAR(30),
website VARCHAR(50),
merchant_category VARCHAR(50),
merchant_price_position VARCHAR(60)
);

ALTER TABLE companies MODIFY website VARCHAR(60);
SHOW COLUMNS FROM companies;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__companies.csv' -- atención con las barras invertidas!!!
INTO TABLE companies
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(company_id,company_name,phone,email,country,website,merchant_category,merchant_price_position);
DESCRIBE companies;

SHOW COLUMNS FROM companies;
SHOW VARIABLES LIKE 'secure_file_priv';

CREATE TABLE users1 ( -- aquí importo americanos
id INT PRIMARY KEY,
name VARCHAR(50),
surname VARCHAR(50),
phone VARCHAR(18),
email VARCHAR(50),
birth_date VARCHAR(30), 
country VARCHAR(30),
city VARCHAR(50),
postal_code INT,
address VARCHAR(50),
signup_date DATE,
user_segment VARCHAR(40),
income_band VARCHAR(10)
);

ALTER TABLE users1 MODIFY postal_code VARCHAR(10);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__american_users.csv' -- atención con las barras invertidas!!!
INTO TABLE users1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id,name,surname,phone,email,birth_date,country,city,postal_code,address,signup_date,user_segment,income_band);

-- cambiar formato fecha
ALTER TABLE users1 ADD COLUMN birth_date_fmt DATE;
SET SQL_SAFE_UPDATES = 0; -- quito protección de modificación
UPDATE users1
SET birth_date_fmt = STR_TO_DATE(birth_date, '%b %e, %Y'); -- texto a fecha
ALTER TABLE users1 DROP COLUMN birth_date;
ALTER TABLE users1 CHANGE birth_date_fmt birth_date DATE;
SET SQL_SAFE_UPDATES = 1; -- rehabilito proteccion de modificación

select *
from users1;

DESCRIBE companies;

CREATE TABLE users2 (  -- aquí importo europeos
    id             INT PRIMARY KEY,
    name           VARCHAR(30),
    surname        VARCHAR(30),
    phone          VARCHAR(20),
    email          VARCHAR(50),
    birth_date     VARCHAR(20),   -- hay que ver cómo seguir con este...
    country        VARCHAR(30),
    city           VARCHAR(30),
    postal_code    VARCHAR(10),   -- alfanumérico 
    address        VARCHAR(60),   
    signup_date    DATE,
    user_segment   VARCHAR(30),
    income_band    VARCHAR(15)
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__european_users.csv'
INTO TABLE users2
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id,name,surname,phone,email,birth_date,country,city,postal_code,address,signup_date,user_segment,income_band);

select *
from users2; -- correctamente cargada

-- cambiar formato fecha
ALTER TABLE users2 ADD COLUMN birth_date_fmt DATE;
SET SQL_SAFE_UPDATES = 0; -- quito protección de modificación
UPDATE users2
SET birth_date_fmt = STR_TO_DATE(birth_date, '%b %e, %Y'); -- texto a fecha
-- ALTER TABLE users2 DROP COLUMN birth_date;
ALTER TABLE users2 CHANGE birth_date_fmt birth_date DATE;

SET SQL_SAFE_UPDATES = 1; -- rehabilito proteccion de modificación

describe users2;
select * from users2;

ALTER TABLE transaction -- relaciono tablas
ADD CONSTRAINT fk_transaction_id_users
FOREIGN KEY (user_id) REFERENCES users1(id); -- ya no me da error!!

SELECT COUNT(DISTINCT t.user_id)
FROM transaction t
LEFT JOIN users1 u ON t.user_id = u.id
WHERE u.id IS NULL;

CREATE TABLE dim_users AS  -- fusiono las tablas de usuarios, dado que en transactions hay datos de USA y de Europa. es una nueva dimension de la BBDD.
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band
FROM users1
UNION ALL
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band
FROM users2;

drop table dim_users;

-- compruebo que esté bien
describe dim_users;
alter table dim_users rename to users_junts; -- renombro
select count(*) from users_junts; 
describe users_junts;

-- creo primary key
ALTER TABLE users_junts ADD PRIMARY KEY (id);
describe users_junts;

-- relaciono amb transaction
ALTER TABLE transaction 
ADD CONSTRAINT fk_transaction_users_junts
FOREIGN KEY (user_id) REFERENCES users_junts(id);

-- **** EXERCICI 9 ****
SELECT id, name, surname
FROM users_junts;

SELECT id, name, surname
FROM users_junts
WHERE id IN (
	SELECT user_id
    FROM transaction
    GROUP BY user_id
    HAVING COUNT(user_id) > 80
);

-- **** Exercici 10 ****

SELECT credit_card.iban, AVG(amount) AS mitjana_amount
FROM transaction
INNER JOIN credit_card ON credit_card.id = transaction.credit_card_id
WHERE transaction.company_id = (SELECT id FROM company WHERE company_name = 'Donec Ltd')
GROUP BY credit_card.iban;

-- ****||| NIVELL 2 |||****

-- **** Exercici 1 ****
SELECT * FROM transaction;

SELECT DATE(timestamp), SUM(amount) as suma
FROM transaction
GROUP BY DATE(timestamp)
ORDER BY suma DESC
LIMIT 5;

-- con las fechas desglosadas
SELECT id, timestamp, amount
FROM transaction
WHERE DATE(timestamp) IN (
    SELECT fecha FROM (
        SELECT DATE(timestamp) AS fecha, SUM(amount) AS total_ingresos
        FROM transaction
        GROUP BY DATE(timestamp)
        ORDER BY total_ingresos DESC
        LIMIT 5
    ) AS top5
)
ORDER BY timestamp;

-- **** Exercici 2 ****

SELECT company_name, phone, country, DATE(transaction.`timestamp`) AS fecha, amount
FROM company
INNER JOIN transaction ON company.id = transaction.company_id
WHERE amount > 350 AND amount < 400 AND ( 
	DATE(transaction.timestamp) = '2015-04-29'
    OR DATE(transaction.timestamp) = '2018-07-20'
    OR DATE(transaction.timestamp) = '2024-03-13')
ORDER BY amount DESC;

-- **** Exercici 3 ****

SELECT count(transaction.id), company_name
FROM transaction
INNER JOIN company ON transaction.company_id = company.id
GROUP BY transaction.company_id, company.company_name;

-- **** Exercici 4 ****
# ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD 

DELETE FROM transaction WHERE ID = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';


-- **** Exercici 5 ****

CREATE VIEW VistaMarketing AS
SELECT company_name, phone, country, AVG(amount) AS mitjana
FROM company
INNER JOIN transaction ON transaction.company_id = company.id
GROUP BY company_name, phone, country
ORDER BY mitjana DESC;

SELECT * FROM VistaMarketing; -- invoco la vista como si fuera tabla más, pero esta no existes



-- ****||| NIVELL 3 |||****

-- **** Exercici 1 ****
SELECT credit_card_id, declined
FROM transaction
WHERE declined <> 0;

describe transaction; 

SELECT credit_card_id, declined, -- creo ventana y con partition reinicio contador de orden en cada tarjeta
        ROW_NUMBER() OVER (         
            PARTITION BY credit_card_id
            ORDER BY date(timestamp) DESC
        ) AS orden
    FROM transaction;
-- =====================================================================
-- TABLA PUENTE: transaction_product
-- =====================================================================
CREATE TABLE transaction_product AS
SELECT
	-- cambio nombre de la primera columna
    transaction.Id AS transaction_id,
    -- Columna 2 del resultado: un único product_id 
    TRIM(
        -- SUBSTRING_INDEX(texto, ',', -1) devuelve todo lo que hay. 
        SUBSTRING_INDEX(
            -- SUBSTRING_INDEX(texto, ',', N) devuelve todo el texto
            -- ANTES (e incluyendo) la coma número N contando desde
            -- la izquierda. Ejemplo con product_ids = "12,45,3":
            -- "corta" el texto 
            SUBSTRING_INDEX(transaction.product_ids, ',', numeros.numero),
            -- Al resultado de arriba ("12,45" si numero=2, por ejemplo)
            -- le volvemos a aplicar SUBSTRING_INDEX, pero pidiendo el
            -- con el -1 nos deja solo con el ÚLTIMO elemento de ese corte
            ',', -1
        )
    -- TRIM() quita espacios en blanco sueltos 
    ) AS product_id

FROM transaction
-- para poder repetir cada transacción tantas veces como productos tenga.
JOIN (
--  generamos 10 filas con los números del 1 al 10 mediante UNION ALL (cada
-- SELECT aporta una fila). 
    SELECT 1 AS numero
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
    UNION ALL SELECT 6
    UNION ALL SELECT 7
    UNION ALL SELECT 8
    UNION ALL SELECT 9
    UNION ALL SELECT 10 -- max. 10, no hay mas en el CSV
) AS numeros
    -- Esta condición ON es la parte más delicada de toda la consulta:
    -- decide CUÁNTAS filas de "numeros" se combinan con cada
    -- transacción, para no generar de más ni de menos.
    ON
        -- CHAR_LENGTH(product_ids) = longitud total del texto,
        -- por ejemplo CHAR_LENGTH("12,45,3") = 7.
        CHAR_LENGTH(transaction.product_ids)
        -- REPLACE(product_ids, ',', '') quita todas las comas del texto
        - CHAR_LENGTH(REPLACE(transaction.product_ids, ',', ''))
        -- una transacción con solo 1 producto (0 comas) solo se
        -- combinará con numero=1, y no generará filas de más con
        -- numero=2 o numero=3 (que no le corresponden).
        >= numeros.numero - 1
-- Descartamos transacciones sin product_ids, para no generar filas vacias
WHERE transaction.product_ids IS NOT NULL
  AND transaction.product_ids <> '';

-- **** Exercici 2 ****

CREATE TABLE products (
id INT PRIMARY KEY, 
product_name VARCHAR(50),
price DECIMAL(5,2),
colour VARCHAR(10),
weight DECIMAL(2,1),
warehouse_id VARCHAR(5),
category VARCHAR(15),
brand VARCHAR(20),
cost DECIMAL(5,2),
launch_date DATE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, @price_raw, colour, weight, warehouse_id, category, brand, @cost_raw, launch_date)
SET
    price = REPLACE(@price_raw, '$', ''),
    cost  = REPLACE(@cost_raw, '$', '');
 
-- el product_ids son valores separados por coma, hay que convertirlo
-- creamos tabla para separar cada producto por su id de transaccion
CREATE TABLE transaction_product AS  
SELECT
    transaction.Id AS transaction_id,
    TRIM(
        SUBSTRING_INDEX( 
            SUBSTRING_INDEX(transaction.product_ids, ',', numeros.numero),
            ',', -1
        )
    ) AS product_id
FROM transaction
JOIN (
    SELECT 1 AS numero
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
    UNION ALL SELECT 6
    UNION ALL SELECT 7
    UNION ALL SELECT 8
    UNION ALL SELECT 9
    UNION ALL SELECT 10
) AS numeros
    ON CHAR_LENGTH(transaction.product_ids)
       - CHAR_LENGTH(REPLACE(transaction.product_ids, ',', '')) >= numeros.numero - 1
WHERE transaction.product_ids IS NOT NULL
  AND transaction.product_ids <> '';
  
select * from transaction_product;

SELECT product_ids FROM transaction LIMIT 5;
describe transaction_product;

-- creo una consulta para ver las veces que se ha vendido cada producto
SELECT products.id, products.product_name, COUNT(*) AS veces_vendido 
FROM transaction_product
INNER JOIN products ON transaction_product.product_id = products.id
GROUP BY products.id, products.product_name
ORDER BY veces_vendido DESC;






#
#
# proves
#
#
SELECT DISTINCT t.credit_card_id
FROM transaction t
LEFT JOIN credit_card c ON t.credit_card_id = c.id
WHERE c.id IS NULL;
SELECT COUNT(*) FROM credit_card;
SELECT credit_card_id, COUNT(*) AS total_huerfanas
FROM transaction
WHERE credit_card_id IS NOT NULL 
  AND credit_card_id NOT IN (
      SELECT id FROM credit_card
  )
GROUP BY credit_card_id;



-- =====================================================================
-- EJERCICIO: estado de cada tarjeta de crédito (activo / inactivo)
-- según sus 3 transacciones más recientes, guardando el resultado
-- en una tabla nueva con CREATE TABLE ... AS SELECT (CTAS).
-- Regla: si las 3 últimas transacciones fueron TODAS declinadas
-- (declined = 1) -> inactivo. Si AL MENOS UNA no fue declinada
-- (declined = 0) -> activo.
-- =====================================================================

-- CREATE TABLE ... AS al principio: en vez de solo mostrar el
-- resultado del SELECT, MySQL crea una tabla nueva (credit_card_status)
-- con las columnas que devuelva el SELECT, y la rellena con esas filas
-- en el mismo paso. Si la tabla ya existe, esta sentencia dará error
-- (hay que hacer antes un DROP TABLE IF EXISTS credit_card_status;).
CREATE TABLE credit_card_status AS

-- PASO 1: CTE "ultimas"
-- Una CTE (Common Table Expression) es una subconsulta con nombre,
-- definida con WITH, que se usa como si fuera una tabla en el SELECT
-- principal. No crea nada físico por sí sola: solo existe mientras
-- se ejecuta esta sentencia (la tabla física la crea el CREATE TABLE
-- de fuera, no la CTE).
WITH ultimas AS (

    SELECT
        credit_card_id,   -- identificador de la tarjeta
        declined,         -- 0 = aceptada, 1 = declinada (rechazada)

        -- ROW_NUMBER() es una función de ventana: numera las filas
        -- 1, 2, 3... según el criterio indicado en OVER (...).
        ROW_NUMBER() OVER (

            -- PARTITION BY reinicia la numeración cada vez que cambia
            -- credit_card_id. Sin esto, la numeración sería global
            -- (mezclando transacciones de tarjetas distintas).
            PARTITION BY credit_card_id

            -- ORDER BY fecha DESC decide el criterio de numeración
            -- DENTRO de cada partición: la transacción más reciente
            -- de cada tarjeta recibe el número 1, la siguiente el 2,
            -- etc. Cambia "fecha" por el nombre real de tu columna
            -- de fecha (compruébalo con DESCRIBE transaction).
            ORDER BY DATE(timestamp) DESC

        ) AS orden           -- alias: posición de la transacción
                              -- dentro de su propia tarjeta

    FROM transaction

)
-- Fin de la CTE. En este punto "ultimas" contiene TODAS las
-- transacciones de la tabla, cada una con su número de orden
-- (1 = más reciente de su tarjeta, 2 = la siguiente, ...).
-- Todavía no se ha descartado nada.


-- PASO 2: consulta principal, que sí usa la CTE.
-- Estas son las columnas que tendrá la tabla credit_card_status.
SELECT

    credit_card_id,

    -- CASE ... END es una expresión condicional (no es una función):
    -- evalúa una condición y devuelve un valor u otro, como un
    -- if/else. Aquí hay dos CASE anidados.
    CASE

        -- SUM(...) SÍ es una función agregada real: suma un valor
        -- numérico por cada fila del grupo actual (ver GROUP BY).
        WHEN SUM(

            -- CASE interior: convierte la condición "no declinada" en numero para sumar. Por cada fila del grupo:
            --   declined = 0 defino declined como acptada cuando es 1 -> aporta 1 al SUM
            --   declined = 1 (declinada) -> aporta 0 al SUM
            CASE WHEN declined = 0 THEN 1 ELSE 0 END

        -- Si la suma total de "aceptadas" dentro del grupo es 0,
        -- significa que NINGUNA de las filas del grupo fue aceptada
        -- (es decir, las 3 últimas transacciones fueron declinadas).
        ) = 0

        THEN 'inactivo'   -- las 3 últimas declinadas -> inactivo
        ELSE 'activo'     -- al menos 1 no declinada  -> activo

    END AS estado

FROM ultimas

-- PASO 3: filtro que limita el análisis a las 3 últimas.
-- Se aplica ANTES del GROUP BY: de cada tarjeta solo sobreviven
-- las filas con orden 1, 2 o 3 (las 3 transacciones más recientes).
-- Sin este WHERE, el SUM de más abajo contaría TODO el historial
-- de la tarjeta, no solo las 3 últimas.
WHERE orden <= 3

-- PASO 4: agrupa las filas restantes (máximo 3 por tarjeta) para
-- que el CASE/SUM del SELECT se calcule una vez por cada tarjeta,
-- no fila a fila. Cada grupo (cada credit_card_id) genera UNA fila
-- de la tabla credit_card_status.
GROUP BY credit_card_id;


-- =====================================================================
-- Comprobación: ver el contenido de la tabla recién creada
-- =====================================================================
SELECT *
FROM credit_card_status;


-- =====================================================================
-- Consulta adicional: cuántas tarjetas quedaron "activas".
-- Como el resultado ya está guardado en una tabla física
-- (credit_card_status), aquí NO hace falta repetir la CTE ni el
-- CASE/SUM: solo se cuenta directamente sobre la tabla.
-- =====================================================================
SELECT COUNT(*) AS tarjetas_activas
FROM credit_card_status
WHERE estado = 'activo';

select count(*) from credit_card_status;
select count(*) from credit_card;

