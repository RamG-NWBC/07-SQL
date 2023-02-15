-- DATA MODELING and DATA ENGINEERING

-- create creditcard_db in pgAdmin
-- after some experiementation drop tables to start afresh
DROP TABLE IF EXISTS card_holder CASCADE;
DROP TABLE IF EXISTS credit_card CASCADE;
DROP TABLE IF EXISTS merchant CASCADE;
DROP TABLE IF EXISTS merchant_category CASCADE;
DROP TABLE IF EXISTS transaction CASCADE;
--- create 5 tables with Primary and Foreign Keys as below


-- SQL file schema
CREATE TABLE merchant_category (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);


CREATE TABLE merchant (
    id SERIAL PRIMARY KEY,
    merchant_name VARCHAR(50) NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES merchant_category(id)
);



CREATE TABLE card_holder (
    id SERIAL PRIMARY KEY,
    card_holder_name VARCHAR(50) NOT NULL
);


CREATE TABLE credit_card (
    card_number BIGINT PRIMARY KEY,
    card_holder_id INTEGER NOT NULL,
    FOREIGN KEY (card_holder_id) REFERENCES card_holder(id)
);



CREATE TABLE transaction (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER NOT NULL,
  transaction_date TIMESTAMP NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  card_number BIGINT,
  merchant_id INTEGER,
  FOREIGN KEY (card_number) REFERENCES credit_card (card_number),
  FOREIGN KEY (merchant_id) REFERENCES merchant (id)
);

-- updated the seed file to make this change to fix error

-- INSERT INTO transaction (transaction_id, transaction_date, amount, card_number, merchant_id) VALUES

-- read seed data file

-- DATA Analysis

-- Part 1

---- create a VIEW that has transaction, credit_card and card_holder tables as transaction_view

CREATE VIEW transaction_view AS
SELECT
  t.id AS transaction_id,
  t.transaction_date,
  t.amount,
  c.card_number,
  ch.card_holder_name
FROM
  transaction t
  JOIN credit_card c ON t.card_number = c.card_number
  JOIN card_holder ch ON c.card_holder_id = ch.id;




--- select from transaction_view where transaction is less than $2.00


SELECT * FROM transaction_view WHERE amount < 2.00;


------- number of cards per card holder

SELECT ch.card_holder_name, COUNT(cc.card_number) as num_cards
FROM card_holder ch
JOIN credit_card cc ON ch.id = cc.card_holder_id
GROUP BY ch.card_holder_name;

---- count transactions less than $2 per card member

SELECT 
    ch.card_holder_name,
    COUNT(*) AS num_transactions_lt_2
FROM 
    card_holder ch
    JOIN credit_card cc ON ch.id = cc.card_holder_id
    JOIN transaction t ON cc.card_number = t.card_number
WHERE 
    t.amount < 2.00
GROUP BY 
    ch.card_holder_name;



--- from transaction_view identify card_holder names that had maximum number of below $2 transactions

SELECT card_holder_name, COUNT(*) AS num_transactions
FROM transaction_view
GROUP BY card_holder_name;

----------- identify top 5 owners of credit cards with highest number of less than $2 transactions
SELECT
  ch.card_holder_name,
  cc.card_number,
  COUNT(t.id) AS num_transactions_lthan2
FROM
  transaction t
  JOIN credit_card cc ON t.card_number = cc.card_number
  JOIN card_holder ch ON cc.card_holder_id = ch.id
WHERE
  t.amount < 2.00
GROUP BY
  ch.card_holder_name,
  cc.card_number
ORDER BY
  num_transactions_lthan2 DESC
LIMIT 5;



-------------- the card holders can be rank ordered as follows
--- rank order
SELECT card_holder_name, num_transactions, DENSE_RANK() OVER (ORDER BY num_transactions DESC) AS rank
FROM (
  SELECT card_holder_name, COUNT(*) AS num_transactions
  FROM transaction_view
  GROUP BY card_holder_name
) AS transaction_counts;

--------------- create transaction_merchant_view that links transaction_view of less than $2 with merchant and merchant_category

CREATE VIEW transaction_merchant_view AS
SELECT
  t.id AS transaction_id,
  t.transaction_date,
  t.amount,
  c.card_number,
  ch.card_holder_name,
  m.merchant_name,
  mc.category_name
FROM
  transaction t
  JOIN credit_card c ON t.card_number = c.card_number
  JOIN card_holder ch ON c.card_holder_id = ch.id
  JOIN merchant m ON t.merchant_id = m.id
  JOIN merchant_category mc ON m.category_id = mc.id;

---- display data from transaction_merchant_view

SELECT * FROM transaction_merchant_view WHERE amount < 2.00;


----------- rank order based on merchant_name and also display merchant_category

SELECT
  mc.category_name,
  m.merchant_name,
  COUNT(*) AS num_transactions,
  DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
FROM
  transaction_merchant_view t
  JOIN merchant m ON t.merchant_name = m.merchant_name
  JOIN merchant_category mc ON m.category_id = mc.id
GROUP BY
  mc.category_name,
  m.merchant_name;



--------- transactions between 7:00 and 9 : AM for all transactions including over $2

CREATE VIEW later_transactions AS
SELECT
  t.id,
  t.transaction_date,
  t.amount,
  c.card_number,
  ch.card_holder_name
FROM
  transaction t
  JOIN credit_card c ON t.card_number = c.card_number
  JOIN card_holder ch ON c.card_holder_id = ch.id
WHERE
  EXTRACT(HOUR FROM t.transaction_date) BETWEEN 7 AND 9;


----- display data of early transactions
SELECT * FROM early_transactions;

--------- order by customer name desc
SELECT * FROM early_transactions
ORDER BY card_holder_name DESC;


--------- create a new view on early_transactions with merchant and merchant-category

CREATE VIEW early_transactions_merchant AS
SELECT
  et.id,
  et.transaction_date,
  et.amount,
  et.card_number,
  et.card_holder_name,
  m.merchant_name,
  mc.category_name
FROM
  early_transactions et
  JOIN transaction t ON et.id = t.id
  JOIN merchant m ON t.merchant_id = m.id
  JOIN merchant_category mc ON m.category_id = mc.id;

----------- ratio of below $2 versus total transactions by cardholder in descending order
SELECT ch.card_holder_name, 
       COUNT(CASE WHEN t.amount < 2 THEN 1 END) AS count_lthan2, 
       COUNT(*) AS count_total, 
       COUNT(CASE WHEN t.amount < 2 THEN 1 END)::float / COUNT(*) AS ratio
FROM card_holder ch
JOIN credit_card cc ON ch.id = cc.card_holder_id
JOIN transaction t ON cc.card_number = t.card_number
GROUP BY ch.card_holder_name
ORDER BY ratio DESC;

------- The top 100 highest transactions made between 7:00 am and 9:00 am?
SELECT *
FROM transaction
WHERE EXTRACT(HOUR FROM transaction_date) BETWEEN 7 AND 9
ORDER BY amount DESC
LIMIT 100;

--- display results

SELECT * FROM early_transactions_merchant;

---- early transactions less than $2

SELECT * FROM early_transactions_merchant
WHERE amount < 2
ORDER BY card_holder_name;

--------- total number of transaction less than $2 in early hours
SELECT COUNT(*) AS num_transactions
FROM early_transactions_merchant
WHERE amount < 2;

--------- create later transactions view outside 7-9am

CREATE VIEW later_transactions AS
SELECT
  t.id,
  t.transaction_date,
  t.amount,
  c.card_number,
  ch.card_holder_name
FROM
  transaction t
  JOIN credit_card c ON t.card_number = c.card_number
  JOIN card_holder ch ON c.card_holder_id = ch.id
WHERE
  EXTRACT(HOUR FROM t.transaction_date) NOT BETWEEN 7 AND 9;


SELECT * FROM later_transactions;

---------- less than 2 outside 7 am to 9 am

CREATE VIEW later_transactions_lthan22 AS
SELECT
  t.id,
  t.transaction_date,
  t.amount,
  c.card_number,
  ch.card_holder_name
FROM
  transaction t
  JOIN credit_card c ON t.card_number = c.card_number
  JOIN card_holder ch ON c.card_holder_id = ch.id
WHERE
  EXTRACT(HOUR FROM t.transaction_date) NOT BETWEEN 7 AND 9
  AND t.amount < 2.00;
  
SELECT * FROM later_transactions_lthan22;


------------ top 5 merchants prone to be hacked with less than $2
SELECT 
    m.merchant_name,
    COUNT(*) AS num_transactions
FROM 
    transaction t
    JOIN merchant m ON t.merchant_id = m.id
WHERE 
    t.amount < 2.00
GROUP BY 
    m.merchant_name
ORDER BY 
    num_transactions DESC
LIMIT 
    5;
