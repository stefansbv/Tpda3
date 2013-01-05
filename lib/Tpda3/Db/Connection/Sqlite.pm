package Tpda3::Db::Connection::Sqlite;

use strict;
use warnings;

use Regexp::Common;
use Log::Log4perl qw(get_logger :levels);
use File::HomeDir;
use File::Spec::Functions;

use Try::Tiny;
use DBI;

=head1 NAME

Tpda3::Db::Connection::Sqlite - Connect to a SQLite database.

=head1 VERSION

Version 0.61

=cut

our $VERSION = 0.61;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Sqlite;

    my $db = Tpda3::Db::Connection::Sqlite->new();

    $db->db_connect($connection);

=head1 METHODS

=head2 new

Constructor

=cut

sub new {
    my ($class, $model) = @_;

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

    #$log->level($TRACE);                     # set log level

    my ($dbname, $host, $driver) = @{$conf}{qw(dbname host driver)};

    $log->trace("Database driver is: $driver");
    $log->trace("Parameters:");
    $log->trace(" > Database = ", $dbname ? $dbname : '?', "\n");
    $log->trace(" > Host     = ", $host   ? $host   : '?', "\n");

    # Fixed path for SQLite databases
    my $dbfile = $conf->{dbfile} = get_testdb_filename($dbname);

    my $dsn = qq{dbi:SQLite:dbname=$dbfile};

    try {
        $self->{_dbh} = DBI->connect(
            $dsn, '', '',
            {   FetchHashKeyName => 'NAME_lc',
                AutoCommit       => 1,
                RaiseError       => 1,
                PrintError       => 0,
                LongReadLen      => 524288,
                HandleError      => sub { $self->handle_error(DBI->errstr) },
                sqlite_unicode   => 1,
            }
        ) or $self->handle_error(DBI->errstr);

        $log->info("Connected to '$dbname'");
    }
    catch {
        # Connection errors
        my $user_message = $self->parse_db_error($_);
        $self->{model}->exception_log($user_message)
            if defined $self->{model}
            and $self->{model}->isa('Tpda3::Model');
    };

    return $self->{_dbh};
}

=head2 handle_error

Log errors.

=cut

sub handle_error {
    my ($self, $message) = @_;

    my $log = get_logger();
    $log->error("Db error: '$message'");

    return;
}

=head2 parse_db_error

Parse a database error message, and translate it for the user.

=cut

sub parse_db_error {
    my ($self, $si) = @_;

    my $log = get_logger();

    # print "\nSI: $si\n\n";

    my $message_type =
         $si eq q{}                                        ? "nomessage"
       : $si =~ m/prepare failed: no such table: (\w+)/smi ? "relnotfound:$1"
       : $si =~ m/prepare failed: near ($RE{quoted}):/smi  ? "notsuported:$1"
       : $si =~ m/not connected/smi                        ? "notconn"
       :                                                     "unknown";

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        nomessage   => "weird#Error without message!",
        notsuported => "fatal#Syntax not supported: $name!",
        relnotfound => "fatal#Relation $name not found",
        unknown     => "fatal#Database error",
        notconn     => "error#Not connected",
    };

    my $message;
    if (exists $translations->{$type} ) {
        $message = $translations->{$type}
    }
    else {
        $log->error('EE: Translation error for: $si!');
    }

    return $message;
}

=head2 table_info_short

Table info 'short'.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;
    return;
}

=head2 table_exists

Check if table exists in the database.

=cut

sub table_exists {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists");

    my $sql = qq( SELECT COUNT(name)
                FROM sqlite_master
                WHERE type = 'table'
                    AND name = '$table';
    );

    $log->trace("SQL= $sql");

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $val_ret;
}

sub table_keys {
    my ( $self, $table ) = @_;

    my $log = get_logger();

    my $sql = qq( SELECT name
                FROM sqlite_master
                WHERE type = 'index'
                    AND name = '$table'
                    AND sql IS NULL;
    );

    my $val_ret;
    try {
        ($val_ret) = $self->{_dbh}->selectrow_array($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $val_ret;
}

sub table_list {
    my $self = shift;

    my $log = get_logger();

    my $sql = qq( SELECT name
                FROM sqlite_master
                WHERE type = 'table';
    );

    my $table_list;
    try {
        $table_list = $self->{_dbh}->selectcol_arrayref($sql);
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $table_list;
}

sub get_testdb_filename {
    my $dbname = shift;

    return catfile(File::HomeDir->my_data, "$dbname.db");
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1;    # End of Tpda3::Db::Connection::Sqlite
