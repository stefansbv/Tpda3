package Tpda3::Db::Connection::OdbcFb;

use strict;
use warnings;

use DBI;
use Log::Log4perl qw(get_logger :levels);
use Regexp::Common;
use Try::Tiny;

require Tpda3::Exceptions;

=head1 NAME

Tpda3::Db::Connection::OdbcFb - Connect to a Odbc Firebird database.

=head1 VERSION

Version 0.70

=cut

our $VERSION = 0.70;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::OdbcFb;

    my $db = Tpda3::Db::Connection::OdbcFb->new();

    $db->db_connect($connection);


=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my ( $class, $model ) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

=head2 db_connect

Connect to database

=cut

sub db_connect {
    my ( $self, $conf ) = @_;

    my $log = get_logger();

    my ( $dbname, $host, $port ) = @{$conf}{qw(dbname host port)};
    my ( $driver, $user, $pass ) = @{$conf}{qw(driver user pass)};

    $log->trace("Database driver is: $driver");
    $log->trace("Parameters:");
    $log->trace( " > Database = ", $dbname ? $dbname : '?', "\n" );
    $log->trace( " > Host     = ", $host   ? $host   : '?', "\n" );
    $log->trace( " > Port     = ", $port   ? $port   : '?', "\n" );
    $log->trace( " > User     = ", $user   ? $user   : '?', "\n" );

    my $dsn = qq{dbi:ODBC:DSN=$dbname};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName => 'NAME_lc',
            AutoCommit       => 1,
            RaiseError       => 0,
            PrintError       => 0,
            LongReadLen      => 524288,
            HandleError      => sub { $self->handle_error() },
            odbc_enable_utf8 => 1,
        }
    );

    # Default date format: ISO?

    return $self->{_dbh};
}

=head2 handle_error

Log errors.

=cut

sub handle_error {
    my $self = shift;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        my $errorstr = $self->{_dbh}->errstr;
        Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }
    else {
        my $errorstr = DBI->errstr;
        Exception::Db::Connect->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }

    return;
}

=head2 parse_error

Parse a database error message, and translate it for the user.

RDBMS specific (and maybe version specific?).

=cut

sub parse_error {
    my ( $self, $fb ) = @_;

    my $log = get_logger();

    print "\nFB: $fb\n\n";

    my $message_type
        = $fb eq q{} ? "nomessage"
        : $fb =~ m/operation for file ($RE{quoted})/smi ? "dbnotfound:$1"
        : $fb =~ m/\-Table unknown\s*\-(.*)\-/smi       ? "relnotfound:$1"
        : $fb =~ m/Your user name and password/smi      ? "userpass"
        : $fb =~ m/no route to host/smi                 ? "network"
        : $fb =~ m/network request to host ($RE{quoted})/smi ? "nethost:$1"
        : $fb =~ m/install_driver($RE{balanced}{-parens=>'()'})/smi
                                                        ? "driver:$1"
        : $fb =~ m/not connected/smi                    ? "notconn"
        :                                                 "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        driver      => "error#Database driver $name not found",
        dbnotfound  => "error#Database $name not found",
        relnotfound => "error#Relation $name not found",
        userpass    => "error#Authentication failed",
        nethost     => "error#Network problem: host $name",
        network     => "error#Network problem",
        unknown     => "error#Database error",
        notconn     => "error#Not connected",
    };

    my $message;
    if ( exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        $log->error('EE: Translation error for: $fb!');
    }

    return $message;
}

=head2 table_list

Return list of tables from the database.

=cut

sub table_list {
    my $self = shift;

    my $log = get_logger();
    $log->info('Geting list of tables... not implemented');

    return;
}

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the OdbcFb driver
doesn't seem to be reliable.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Geting table info for $table... not implemented");

    return;
}

=head2 table_keys

Get the primary key field name of the table.

=cut

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    my $log = get_logger();
    $log->info("Geting '$table' table primary key(s) names... not implemented");

    return;
}

=head2 table_exists

Check if table exists in the database.

=cut

sub table_exists {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists... not implemented");

    return;
}

=head2 has_feature_returning

Returns yes for OdbcFb, meaning that is has the
INSERT... RETURNING feature.

Should check for the OdbcFb version?

=cut

sub has_feature_returning { 0 }

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Information schema queries inspired from:

 - http://www.alberton.info/firebird_sql_meta_info.html by Lorenzo Alberton
 - Flamerobin Copyright (c) 2004-2013 The FlameRobin Development Team

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Db::Connection::OdbcFb
