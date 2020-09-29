/****************************************************************************
 * Copyright (c) 2005 Actuate Corporation.
 * All rights reserved. This file and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *  Actuate Corporation  - initial implementation
 *
 * Classic Models Inc. sample database developed as part of the
 * Eclipse BIRT Project. For more information, see http:\\www.eclipse.org\birt
 *
 ****************************************************************************/
/*
 * BIRT Sample Database
 * From: http://www.eclipse.org/birt/phoenix/db/
 * The sample database is open source; you are free to use it for your own use
 * to experiment with other tools; to create samples for other tools, etc.
 * The sample database is provided under the terms Eclipse.org
 * Software User Agreement.
 *
 * Adapted for Firebird and TPDA by Stefan Suciu, 2009, 2014
 * Add new "system" tables reports and reports_det
 * Add new "system" tables templates, templates_var and templates_req
 * New view V_PRODUCTS
 * Added productlinecode to PRODUCTLINES table
 * Replaced productline with productlinecode in PRODUCTS table
 * New table: COUNTRY
 * Replaced country with countrycode in CUSTOMERS and OFFICES tables
 * Renamed salesrepemployeenumber in CUSTOMERS table to employeenumber
 * New table: STATUS
 * Added PRIMARY and FOREIGN KEY CONSTRAINTS
 * Created SEQUENCES and VIEWS
 *
**/

/*

Database: classicmodels

DROP DATABASE classicmodels;

createdb -E UTF8 -O username -U postgres -T template0 classicmodels

or

CREATE DATABASE classicmodels
  WITH OWNER = 'user-name'
       ENCODING = 'LATIN1'
       TABLESPACE = pg_default;

psql -U user -f sql/classicmodels-pg.sql -d classicmodels

*/

-- Drop

/*
DROP VIEW v_products;
DROP VIEW v_customers;
DROP VIEW v_employees;
DROP VIEW v_orders;
DROP VIEW v_orderdetails;
DROP VIEW v_country;

DROP TABLE reports_det;
DROP TABLE reports;
DROP TABLE templates_req;
DROP TABLE templates_var;
DROP TABLE templates;

DROP TABLE status;
DROP TABLE payments;
DROP TABLE orderdetails;
DROP TABLE orders;
DROP TABLE products;
DROP TABLE productlines;

DROP TABLE customers;
DROP TABLE employees;
DROP TABLE offices;
DROP TABLE country;
*/


-- Tpda3 system tables

--- Reports

/*
 * Name : reports
 * Type : table
 * Desc : Report Manager reports metadata
 * Deps :
 */
CREATE TABLE reports (
   id_rep       INTEGER NOT NULL
 , id_user      INTEGER
 , repofile     VARCHAR(150)
 , title        VARCHAR(50)
 , descr        TEXT
 , CONSTRAINT pk_reports_id_rep PRIMARY KEY (id_rep)
);

/*
 * Name : reports_det
 * Type : table
 * Desc : Report Manager reports metadata details
 * Deps :
 */
CREATE TABLE reports_det (
   id_rep       INTEGER      NOT NULL
 , id_art       INTEGER      NOT NULL
 , hint         VARCHAR(15)  NOT NULL
 , tablename    VARCHAR(25)  NOT NULL
 , searchfield  VARCHAR(25)  NOT NULL
 , resultfield  VARCHAR(25)  NOT NULL
 , headerlist   VARCHAR(50)  NOT NULL
 , CONSTRAINT pk_reports_det_id_rep PRIMARY KEY (id_rep, id_art)
 , CONSTRAINT fk_reports_det_id_rep FOREIGN KEY (id_rep)
       REFERENCES reports (id_rep)
           ON DELETE CASCADE
           ON UPDATE CASCADE
);

--- Templates

/*
 * Name : templates
 * Type : table
 * Desc : Template Toolkit documents metadata
 * Deps :
 */
CREATE TABLE templates (
   id_tt        INTEGER NOT NULL
 , tt_file      VARCHAR(150)
 , title        VARCHAR(50)
 , table_name   VARCHAR(100)
 , view_name    VARCHAR(100)
 , common_data  VARCHAR(100)
 , descr        TEXT
 , datasource   VARCHAR(100)
 , CONSTRAINT pk_templates_id_tt PRIMARY KEY (id_tt)
);

/*
 * Name : templates_req
 * Type : table
 * Desc : Template Toolkit documents required fields
 * Deps : templates
 */
CREATE TABLE templates_req (
   id_tt        INTEGER       NOT NULL
 , id_art       INTEGER       NOT NULL
 , var_name     VARCHAR(50)   NOT NULL
 , state        VARCHAR(10)               -- Not used, only for TM display
 , required     SMALLINT      NOT NULL
 , CONSTRAINT pk_templates_req_id_tt PRIMARY KEY (id_tt, id_art)
 , CONSTRAINT fk_templates_req_id_tt FOREIGN KEY (id_tt)
       REFERENCES templates (id_tt)
           ON DELETE CASCADE
           ON UPDATE CASCADE
 , UNIQUE (var_name)
);

/*
 * Name : templates_var
 * Type : table
 * Desc : Template Toolkit documents global variables
 * Deps :
 */
CREATE TABLE templates_var (
   id_tt        INTEGER       NOT NULL
 , id_art       INTEGER       NOT NULL
 , var_name     VARCHAR(50)   NOT NULL
 , var_value    VARCHAR(250)  NOT NULL
 , CONSTRAINT pk_templates_var_id_tt PRIMARY KEY (id_tt, id_art)
 , CONSTRAINT fk_templates_var_id_tt FOREIGN KEY (id_tt)
       REFERENCES templates (id_tt)
           ON DELETE CASCADE
           ON UPDATE CASCADE
);

-- Tables


CREATE TABLE status (
    code        VARCHAR(5) NOT NULL,
    description VARCHAR(25) NOT NULL,
    CONSTRAINT pk_status_code
               PRIMARY KEY (code)
);


CREATE TABLE country (
    code         CHAR(2) NOT NULL,
    country      VARCHAR(50) NOT NULL,
    CONSTRAINT pk_country_code
               PRIMARY KEY (code)
);


CREATE TABLE offices (
    officecode   VARCHAR(10) NOT NULL,
    city         VARCHAR(50) NOT NULL,
    phone        VARCHAR(50) NOT NULL,
    addressline1 VARCHAR(50) NOT NULL,
    addressline2 VARCHAR(50),
    state        VARCHAR(50),
    countrycode  CHAR(2) NOT NULL,
    postalcode   VARCHAR(15) NOT NULL,
    territory    VARCHAR(10) NOT NULL,
    CONSTRAINT pk_offices_ocode
               PRIMARY KEY (officecode)
);


CREATE TABLE employees (
    employeenumber SMALLINT NOT NULL,
    lastname       VARCHAR(50) NOT NULL,
    firstname      VARCHAR(50) NOT NULL,
    extension      VARCHAR(10) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    officecode     VARCHAR(10) NOT NULL,
    reportsto      SMALLINT,
    jobtitle       VARCHAR(50) NOT NULL,
    CONSTRAINT pk_employees_employeenumber
               PRIMARY KEY (employeenumber),
    CONSTRAINT fk_employees_offices_ocode
               FOREIGN KEY (officecode)
                    REFERENCES offices (officecode)
                        ON DELETE NO ACTION
                        ON UPDATE NO ACTION
);


CREATE TABLE customers (
    customernumber         SERIAL,
    customername           VARCHAR(50) NOT NULL,
    contactlastname        VARCHAR(50) NOT NULL,
    contactfirstname       VARCHAR(50) NOT NULL,
    phone                  VARCHAR(50) NOT NULL,
    addressline1           VARCHAR(50) NOT NULL,
    addressline2           VARCHAR(50),
    city                   VARCHAR(50) NOT NULL,
    state                  VARCHAR(50),
    postalcode             VARCHAR(15),
    countrycode            CHAR(2) NOT NULL,
    employeenumber         SMALLINT DEFAULT NULL,
    creditlimit            DECIMAL(10,2),
    CONSTRAINT pk_customers_cust_emp
               PRIMARY KEY (customernumber)
);


CREATE TABLE productlines (
    productlinecode    SERIAL,
    productline        VARCHAR(50) NOT NULL,
    textdescription    TEXT,
    htmldescription    TEXT,
    image              TEXT,
    CONSTRAINT pk_productlines_plinecode
               PRIMARY KEY (productlinecode)
);


CREATE TABLE products (
    productcode        VARCHAR(15) NOT NULL,
    productname        VARCHAR(64) NOT NULL,
    productlinecode    SMALLINT NOT NULL,
    productscale       VARCHAR(10) NOT NULL,
    productvendor      VARCHAR(50) NOT NULL,
    productdescription TEXT NOT NULL,
    quantityinstock    SMALLINT NOT NULL,
    buyprice           DECIMAL(10,2) NOT NULL,
    msrp               DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_products_pcode_ord
               PRIMARY KEY (productcode),
    CONSTRAINT fk_products_productlines_pline
               FOREIGN KEY (productlinecode)
                    REFERENCES productlines (productlinecode)
                        ON DELETE NO ACTION
                        ON UPDATE NO ACTION
);


CREATE TABLE orders (
    ordernumber    SERIAL,
    orderdate      DATE NOT NULL,
    requireddate   DATE NOT NULL,
    shippeddate    DATE DEFAULT NULL,
    statuscode     CHAR(1) DEFAULT NULL,
    comments       TEXT,
    customernumber SMALLINT NOT NULL,
    ordertotal     DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT pk_orders_ordernumber
               PRIMARY KEY (ordernumber),
    CONSTRAINT fk_orders_customers_cust_emp
               FOREIGN KEY (customernumber)
                    REFERENCES customers (customernumber)
                        ON DELETE NO ACTION
                        ON UPDATE NO ACTION
);


CREATE TABLE orderdetails (
    ordernumber     SMALLINT NOT NULL,
    orderlinenumber SMALLINT NOT NULL,
    productcode     VARCHAR(15) NOT NULL,
    quantityordered SMALLINT NOT NULL,
    priceeach       DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_orderdetails_ordlinnum
               PRIMARY KEY (ordernumber,orderlinenumber),
    CONSTRAINT fk_orderdetails_orders_ord
               FOREIGN KEY (ordernumber)
                    REFERENCES orders (ordernumber)
                        ON DELETE CASCADE
                        ON UPDATE CASCADE,
    CONSTRAINT fk_orderdetails_products_pcode
               FOREIGN KEY (productcode)
                    REFERENCES products (productcode)
                        ON DELETE NO ACTION
                        ON UPDATE NO ACTION
);


CREATE TABLE payments (
    customernumber SMALLINT NOT NULL,
    checknumber    VARCHAR(50) NOT NULL,
    paymentdate    TIMESTAMP NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_payments_custnum_chnum
               PRIMARY KEY (customernumber, checknumber),
    CONSTRAINT fk_payments_customers_cus
               FOREIGN KEY (customernumber)
                    REFERENCES customers (customernumber)
                        ON DELETE NO ACTION
                        ON UPDATE NO ACTION
);

-- Sequences

-- CREATE SEQUENCE g_customers_customernumber;
-- CREATE SEQUENCE g_orders_ordernumber;

-- Update sequence values acording to table data

-- ALTER SEQUENCE g_customers_customernumber OWNED BY customers.customernumber;
-- SELECT setval('g_customers_customernumber',496);
-- ALTER SEQUENCE g_orders_ordernumber OWNED BY orders.ordernumber;
-- SELECT setval('g_orders_ordernumber',10425);

-- Views

CREATE VIEW v_country (
       countrycode
     , countryname
) AS
SELECT co.code AS countrycode
     , co.country
FROM country co
;


CREATE VIEW v_products (
       productcode
     , productname
     , productlinecode, productline
     , productscale
     , productvendor
     , productdescription
     , quantityinstock
     , buyprice
     , msrp
) AS
SELECT p.productcode
     , p.productname
     , p.productlinecode, pl.productline
     , p.productscale
     , p.productvendor
     , p.productdescription
     , p.quantityinstock
     , p.buyprice
     , p.msrp
FROM products p
     LEFT JOIN productlines pl ON p.productlinecode = pl.productlinecode
;


CREATE VIEW v_orderdetails (
       ordernumber
     , orderlinenumber
     , productcode
     , productname
     , quantityordered
     , priceeach
     , ordervalue
) AS
SELECT od.ordernumber
     , od.orderlinenumber
     , od.productcode
     , p.productname
     , od.quantityordered
     , od.priceeach
     , od.quantityordered * od.priceeach AS ordervalue
FROM orderdetails od
     LEFT JOIN products p ON od.productcode = p.productcode
;


CREATE VIEW v_orders (
       customernumber, customername
     , ordernumber
     , orderdate
     , requireddate
     , shippeddate
     , comments
     , statuscode, status
     , ordertotal
) AS
SELECT
       o.customernumber, c.customername
     , o.ordernumber
     , o.orderdate
     , o.requireddate
     , o.shippeddate
     , o.comments
     , o.statuscode, s.description AS status
     , ordertotal
FROM orders o
     LEFT JOIN customers c
          ON o.customernumber = c.customernumber
     LEFT JOIN status s
          ON o.statuscode = s.code
;


CREATE VIEW v_employees (
       employeenumber
     , lastname
     , firstname
     , salesrepemployee
     , extension
     , email
     , officecode
     , reportsto
     , jobtitle
) AS
SELECT e.employeenumber
     , e.lastname
     , e.firstname
     , e.firstname || ' ' || e.lastname AS salesrepemployee
     , e.extension
     , e.email
     , e.officecode
     , e.reportsto
     , e.jobtitle
FROM employees e
;


CREATE VIEW v_customers (
       customernumber
     , customername
     , contactlastname
     , contactfirstname
     , phone
     , addressline1
     , addressline2
     , city
     , state
     , postalcode
     , countrycode, countryname
     , employeenumber, salesrepemployee
     , creditlimit
) AS
SELECT
       c.customernumber
     , c.customername
     , c.contactlastname
     , c.contactfirstname
     , c.phone
     , c.addressline1
     , c.addressline2
     , c.city
     , c.state
     , c.postalcode
     , c.countrycode, countryname
     , c.employeenumber, ve.salesrepemployee
     , c.creditlimit
FROM customers c
     LEFT JOIN v_employees ve
          ON c.employeenumber = ve.employeenumber
     LEFT JOIN v_country co
          ON c.countrycode = co.countrycode
;



/* Encode status */

/*
UPDATE orders SET statuscode = 'C'
WHERE status = 'Cancelled';

UPDATE orders SET statuscode = 'D'
WHERE status = 'Disputed';

UPDATE orders SET statuscode = 'P'
WHERE status = 'In Process';

UPDATE orders SET statuscode = 'H'
WHERE status = 'On Hold';

UPDATE orders SET statuscode = 'R'
WHERE status = 'Resolved';

UPDATE orders SET statuscode = 'S'
WHERE status = 'Shipped';
*/
