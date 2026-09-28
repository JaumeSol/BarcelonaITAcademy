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

SELECT id, iban FROM credit_card WHERE id = 'CcU-2938';  -- está el registro?


UPDATE credit_card SET iban = 'TR323456312213576817699999' -- actualizo el IBAN del registro
WHERE id = 'CcU-2938';


SELECT id, iban FROM credit_card WHERE id = 'CcU-2938'; -- verifiquem sobre l'id

-- **** APARTAT 6 ****

INSERT INTO company (id) VALUES ('b-9999'); -- inserto registros padre
INSERT INTO credit_card (id) VALUES ('CcU-9999'); 


INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined) -- adjunto los valores de registro hijo en transaction
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999,							
        829.999, -117.999, 111.11, 0);


SELECT * FROM transaction WHERE credit_card_id = 'CcU-9999';  -- busco el nou registre a partir de la credit_card_id

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


SHOW VARIABLES LIKE 'secure_file_priv';

USE nova_transaction;
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

USE nova_transaction;
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

USE nova_transaction;
CREATE TABLE junts_users AS  -- fusiono las tablas de usuarios, dado que en transactions hay datos de USA y de Europa. es una nueva dimension de la BBDD.
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band, continent
FROM users1
UNION ALL
SELECT id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band, continent
FROM users2;

-- creo primary key
ALTER TABLE junts_users ADD PRIMARY KEY (id);
describe junts_users;

-- relaciono amb transaction
ALTER TABLE transaction 
ADD CONSTRAINT fk_transaction_users_junts
FOREIGN KEY (user_id) REFERENCES junts_users(id);

DESCRIBE junts_users;
SELECT * FROM junts_users;

USE nova_transaction;
CREATE TABLE credit_card (
    id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(4),
    cvv VARCHAR(4),
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date DATE,
    card_type VARCHAR(30),
    card_renewal_flag TINYINT(1)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_card
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, user_id, iban, pan, pin, cvv, track1, track2, @expiring_date, card_type, card_renewal_flag)
SET expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y');

DESCRIBE credit_card;
SELECT * FROM credit_card;
SELECT COUNT(*) FROM credit_card;

SELECT COUNT(*) FROM transaction
LEFT JOIN credit_card ON transaction.card_id = credit_card.id
WHERE credit_card.id IS NULL;

-- relaciono amb transaction
ALTER TABLE transaction 
ADD CONSTRAINT fk_transaction_credit_cards
FOREIGN KEY (card_id) REFERENCES credit_card(id); -- FK = la PK de credit card apunta a card_id de transaction 

show tables;

-- ahora creo companies
CREATE TABLE companies (
    company_id VARCHAR(15) PRIMARY KEY,
    company_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    country VARCHAR(50),
    website VARCHAR(255),
    merchant_category VARCHAR(50),
    merchant_price_position VARCHAR(20)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(company_id, company_name, phone, email, country, website,
 merchant_category, merchant_price_position);
-- comprovamos que no haya filas huérfanas. Si fuera <> 0 no podriamos poner las FK!!
SELECT COUNT(*) FROM transaction
LEFT JOIN companies ON transaction.business_id = companies.company_id
WHERE companies.company_id IS NULL;

-- añadimos las foreign keys con una relacion de 1-N con transaction (una compañia puede tener varias transaction)
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_companies
FOREIGN KEY (business_id) REFERENCES companies(company_id);

SELECT COUNT(*) FROM companies;
SELECT COUNT(DISTINCT country) FROM companies;

SELECT continent, COUNT(continent) AS num_usuarios FROM junts_users
GROUP BY continent;

-- **** EXERCICI 9 ****
USE nova_transaction;
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
INNER JOIN credit_card ON credit_card.id = transaction.card_id
WHERE transaction.business_id = (SELECT company_id FROM companies WHERE company_name = 'Donec Ltd')
GROUP BY credit_card.iban
ORDER BY mitjana_amount DESC;

-- ****||| NIVELL 2 |||****

-- **** Exercici 1 ****
USE nova_transaction;
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
USE nova_transaction;
SELECT company_name, phone, country, DATE(transaction.`timestamp`) AS fecha, amount
FROM companies
INNER JOIN transaction ON companies.company_id = transaction.business_id
WHERE amount > 350 AND amount < 400 AND ( 
	DATE(transaction.timestamp) = '2015-04-29'
    OR DATE(transaction.timestamp) = '2018-07-20'
    OR DATE(transaction.timestamp) = '2024-03-13')
ORDER BY amount DESC;

-- **** Exercici 3 ****

SELECT count(transaction.id), company_name
FROM transaction
INNER JOIN companies ON transaction.business_id = companies.company_id
GROUP BY transaction.business_id, companies.company_name;

SELECT business_id, COUNT(transaction.id) AS numero_transaccions, company_name,
    CASE WHEN COUNT(transaction.id) >= 400 THEN 'igual o més de 400'
         ELSE 'menys de 400'
    END AS categoria
FROM transaction 
INNER JOIN companies ON transaction.business_id = companies.company_id
GROUP BY companies.company_id, companies.company_name
ORDER BY numero_transaccions ASC;

-- **** Exercici 4 ****
# ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD 
SELECT ID FROM transaction
WHERE ID = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

DELETE FROM transaction WHERE ID = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

SELECT ID FROM transaction -- refaig consulta per comprobar que no hi ha el registre
WHERE ID = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';


-- **** Exercici 5 ****

CREATE VIEW VistaMarketing AS
SELECT company_name, phone, country, AVG(amount) AS mitjana
FROM companies
INNER JOIN transaction ON transaction.business_id = companies.company_id
GROUP BY company_name, phone, country
ORDER BY mitjana DESC;

SELECT * FROM VistaMarketing; -- invoco la vista como si fuera tabla más, pero esta no existe

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
    price VARCHAR(20), -- tiene $ en los valores, los tendré que modificar
    colour VARCHAR(20),
    weight DECIMAL(5,2),
    warehouse_id VARCHAR(10),
    category VARCHAR(50),
    brand VARCHAR(50),
    cost VARCHAR(20), -- tiene $ en los valores, los tendré que modificar
    launch_date DATE
);

SELECT * from products;

-- Cargo los datos en la tabla
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id, category, brand, cost, launch_date);

SET SQL_SAFE_UPDATES = 0; -- eliminamos los simbolos $ de los valores de cost y price
UPDATE products
SET price = REPLACE(REPLACE(price, '$', ''), ',', '.'),
    cost  = REPLACE(REPLACE(cost, '$', ''), ',', '.');
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE products MODIFY COLUMN price DECIMAL(10,2); -- cambio el tipo de dato de la columna para que sea coherente al contenido
ALTER TABLE products MODIFY COLUMN cost DECIMAL(10,2);

SELECT COUNT(*) FROM products;
SELECT * FROM products LIMIT 10;

-- esta solución funciona, pero NO SE AJUSTA a lo que pide el enunciado, 
-- que es crear una tabla intermedia
SELECT
    products.id AS product_id,
    products.product_name,
    products.category,
    products.brand,
    COUNT(*) AS veces_vendido
FROM products
JOIN transaction ON FIND_IN_SET(products.id, REPLACE(transaction.product_ids, ' ', '')) > 0 -- buscamos cadena texto y eliminamos espacios... 
GROUP BY products.id, products.product_name, products.category, products.brand -- ... ahorramos pasos intermedios, pero deberemos procesar los datos cada vez que hagamos la consulta
ORDER BY veces_vendido DESC;
-- podriamos implementar un UPDATE en la tabla products? así hariamos solo una vez esta operación. ahorramos cálculos.

# ******** solucion propuesta después de corrección **********
-- Tabla intermedia para unir los productos con las transacciones
CREATE TABLE transaction_products (
	transaction_id VARCHAR(40) NOT NULL, 
    product_id INT NOT NULL,
PRIMARY KEY (transaction_id, product_id),
FOREIGN KEY (transaction_id) REFERENCES transaction(Id),
FOREIGN KEY (product_id) REFERENCES products(id)
);

-- JSON_TABLE (JavaScript Object Notation) separa la lista en filas 
INSERT INTO transaction_products (transaction_id, product_id)
SELECT transaction.Id, jt.product_id
FROM transaction
JOIN JSON_TABLE(
	CONCAT('[', transaction.product_ids, ']'),
     '$[*]' COLUMNS (product_id INT PATH '$')
) AS jt;

select * from transaction_products;

SELECT product_id, products.product_name, count(product_id) AS veces_vendido FROM transaction_products
INNER JOIN products ON transaction_products.product_id = products.id
GROUP BY product_id 
ORDER BY veces_vendido DESC;

use nova_transaction;
 select * from transaction;







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