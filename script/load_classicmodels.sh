#!/bin/bash
#
# Load ClassicModels data into tables for Firebird, PostgreSQL or
# MySQL
#
# Author Stefan Suciu, 2009 - 2010
#

# With help from:
#  Advanced Bash-Scripting Guide
#    by Mendel Cooper
# :-) Thank You


#--
echo
echo 'Database classicmodels has to be online and the structure'
echo 'must be created with tpda/sql/??/create_classicmodels.sql'
echo '        where ?? is fb|pg|my depending on the RDBMS used.'
echo
#--

if [ -z "$1" ]; then
    echo "Usage: $0 <fb|pg|my>"
    echo
    exit 1
fi

SEARCH_STR=FBPGMYSI
SEARCH_FOR=$1

if echo "$SEARCH_STR" | grep -i -q "$SEARCH_FOR"
then
    echo "Parameter is $SEARCH_FOR"
else
    echo "Usage: $0 <fb|pg|my|si>"
    exit 1
fi

# Variables
IMPORT_SCRIPT=tpda-import_data.pl
DATA_DIR=data
DB=$1

if [ $DB == 'pg' ]; then
    echo " Press 'Enter' on Password request, if no password was set"
    echo
fi

echo -n "Enter user name: "
read USER

stty -echo # Turns off screen echo.

echo -n "Enter password: "
read PASS

stty echo  # Restores screen echo.

echo

# Load data ...

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/country.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/offices.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/employees.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/customers.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/productlines.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/products.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/orders.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/orderdetails.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/payments.dat;

perl $IMPORT_SCRIPT -u "$USER" -p "$PASS" -db 'classicmodels' -mo "$DB" \
  -f $DATA_DIR/status.dat;

echo Done.
