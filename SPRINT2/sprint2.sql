CREATE DATABASE transaction_bis;
USE transaction_bis;



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
SELECT DISTINCT company_name AS nom, ROUND(AVG(amount), 2) AS promig_transaccions
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

-- a continuación cargo los datos desde datos_introducir_credito.csv

SELECT count(*) FROM credit_card;

ALTER TABLE credit_card ADD COLUMN expiring_date_fmt DATE;

ALTER TABLE transaction -- reltransactionaciono tablas
ADD CONSTRAINT fk_transaction_creditcard
FOREIGN KEY (card_id) REFERENCES credit_card(id); -- me da error por registros NULL!!

SET SQL_SAFE_UPDATES = 0; -- quito salvaguarda de datos
UPDATE credit_card
SET expiring_date_fmt = STR_TO_DATE(expiring_date, '%m/%d/%y'); -- modifico la cadena de texto a formato ISO
SET SQL_SAFE_UPDATES = 1; -- vuelvo a activar la salvaguarda de datos
ALTER TABLE credit_card DROP COLUMN expiring_date; -- elimino la columna de fecha en formato VARCHAR
ALTER TABLE credit_card CHANGE expiring_date_fmt expiring_date DATE; -- renombro columna creada antes con fecha formato DATE
describe credit_card;


SELECT * FROM credit_card;
SELECT * FROM transaction;


-- **** APARTAT 5 ****
SELECT * FROM credit_card
WHERE id='CcU-2938';

SET SQL_SAFE_UPDATES = 0;
update credit_card set id = 'CcU-2938' where iban = 'TR323456312213576817699999';
SET SQL_SAFE_UPDATES = 1;

select *
from credit_card
where id = 'CcU-9999';

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

DESCRIBE credit_card;

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
 select * from transaction;

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

ALTER TABLE users1 -- afegim columna per no perdre granularitat
ADD COLUMN continent VARCHAR(50) NOT NULL DEFAULT 'american';

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
    income_band    VARCHAR(15),
    continent      VARCHAR(50) NOT NULL DEFAULT 'european'
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
ALTER TABLE users2 DROP COLUMN birth_date;
ALTER TABLE users2 CHANGE birth_date_fmt birth_date DATE;

SET SQL_SAFE_UPDATES = 1; -- rehabilito proteccion de modificación

describe users2;
select * from users2;

ALTER TABLE transaction -- relaciono tablas
ADD CONSTRAINT fk_transaction_id_users
FOREIGN KEY (user_id) REFERENCES users1(id); -- ya no me da error!!



CREATE TABLE junts_users AS  -- fusiono las tablas de usuarios, dado que en transactions hay datos de USA y de Europa. es una nueva dimension de la BBDD.
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band, continent
FROM users1
UNION ALL
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band, continent
FROM users2;

-- creo primary key
ALTER TABLE junts_users ADD PRIMARY KEY (id);
describe users_junts;

-- relaciono amb transaction
ALTER TABLE transaction 
ADD CONSTRAINT fk_transaction_users_junts
FOREIGN KEY (user_id) REFERENCES junts_users(id);

DESCRIBE junts_users;
SELECT * FROM junts_users;

-- **** EXERCICI 9 ****
SELECT id, name, surname
FROM junts_users;

SELECT junts_users.id, junts_users.name, junts_users.surname, transaction_counts.num_transactions
FROM junts_users
JOIN (
    SELECT user_id, COUNT(*) AS num_transactions
    FROM transaction
    GROUP BY user_id
    HAVING COUNT(*) > 80
) AS transaction_counts
ON junts_users.id = transaction_counts.user_id
ORDER BY transaction_counts.num_transactions DESC;

SELECT user_id
    FROM transaction
    GROUP BY user_id
    HAVING COUNT(user_id) > 80;
    
select * from transaction;
-- **** Exercici 10 ****

SELECT credit_card.iban, ROUND(AVG(amount), 2) AS mitjana_amount
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
show columns from transaction;
SELECT card_id, declined
FROM transaction
WHERE declined <> 0;

describe transaction; 

-- Creo una tabla temporal con las últimas 3 transacciones por tarjeta
CREATE TABLE card_status AS
WITH last_transactions AS (
    SELECT
        transaction.card_id,
        transaction.declined,
        ROW_NUMBER() OVER (PARTITION BY transaction.card_id ORDER BY transaction.timestamp DESC) AS row_num
    FROM transaction
),
calculated_status AS (
    SELECT
        credit_card.id,
        credit_card.iban,
        COUNT(last_transactions.card_id) AS total_last_3,
        SUM(CASE WHEN last_transactions.declined = 1 THEN 1 ELSE 0 END) AS last_3_declined,
        CASE
            WHEN SUM(CASE WHEN last_transactions.declined = 0 THEN 1 ELSE 0 END) >= 1 THEN 'ACTIVA'
            ELSE 'INACTIVA'
        END AS status
    FROM credit_card
    LEFT JOIN last_transactions ON credit_card.id = last_transactions.card_id AND last_transactions.row_num <= 3
    GROUP BY credit_card.id, credit_card.iban
)
SELECT * FROM calculated_status;

-- consulto cuántas tarjetas son activas
SELECT
    status,
    COUNT(*) AS total_cards
FROM card_status
GROUP BY status;

-- **** Exercici 2 ****

-- Creo la tabla products
CREATE TABLE products (
    id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price VARCHAR(20),
    colour VARCHAR(20),
    weight DECIMAL(5,2),
    warehouse_id VARCHAR(10),
    category VARCHAR(50),
    brand VARCHAR(50),
    cost VARCHAR(20),
    launch_date DATE
);


-- Cargo los datos en la tabla
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id, category, brand, cost, launch_date);

SELECT COUNT(*) FROM products;
SELECT * FROM products LIMIT 10;

SELECT
    products.id AS product_id,
    products.product_name,
    products.category,
    products.brand,
    COUNT(*) AS veces_vendido
FROM products
JOIN transaction ON FIND_IN_SET(products.id, transaction.product_ids) > 0
GROUP BY products.id, products.product_name, products.category, products.brand
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

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id, category, brand, cost, launch_date);
SHOW VARIABLES LIKE 'secure_file_priv';