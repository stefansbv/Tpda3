#!/bin/bash
#
# Load Classic Models data into tables for Firebird, PostgreSQL,
# or SQLite
#
# Version: 0.87
# Author: Stefan Suciu, (C) 2009-2012

# With help from:
#  Advanced Bash-Scripting Guide
#    by Mendel Cooper
# :-) Thank You

# TODO: Rewrite this in Perl !!! ???

PERL=$(which perl)
echo Perl is $PERL

#--
echo
echo ' Loading test data into classicmodels database...'
echo
echo ' For Firebird and PostgreSQL:'
echo '  the database classicmodels has to be online and the structure'
echo '  must be created with tpda/sql/??/create_classicmodels.sql'
echo '        where ?? is fb|pg|my depending on the RDBMS used.'
echo ' Note: For SQLite: creates the test database if it does not exists.'
echo
#--

if [ -z "$1" ]; then
    echo "Usage: $0 <fb|pg|si> [user]"
    echo
    exit 1
fi

if [ -z "$2" ]; then
    USER=sysdba
else
    USER=$2
fi

SEARCH_STR=FBPGMYSI
SEARCH_FOR=$1

if ! echo "$SEARCH_STR" | grep -i -q "$SEARCH_FOR"; then
    echo "Usage: $0 <fb|pg|si>"
    exit 1
fi

# Variables
IMPORT_SCRIPT=script/csv-import.pl
DATA_DIR=data
DBNAME=classicmodels
DBD=$1

#-- for SQLite

if [ $DBD == "si" ]; then
    if [[ -f $DBNAME ]]; then
        echo 'Database classicmodels exists,'
        echo 'Move | delete, to recreate!'
        exit
    else
        echo -n "Creating database ... "
        sqlite3 $DBNAME < sql/classicmodels-si.sql
        echo done
    fi
fi

# echo $PERL $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR

# Load data ... [ I know it needs a loop ;) ]

perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/country.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/offices.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/employees.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/customers.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/productlines.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/products.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/orders.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/orderdetails.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/payments.dat;
perl $IMPORT_SCRIPT -b  -db "$DBNAME" -mo "$DBD" -user "$USER" -f $DATA_DIR/status.dat;

echo Finished.
