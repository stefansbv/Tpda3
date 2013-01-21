package Tpda3::Db::Connection::Cubrid;

use strict;
use warnings;

use Regexp::Common;
use Log::Log4perl qw(get_logger :levels);

use Tpda3::Exceptions;

use Try::Tiny;
use DBI;

=head1 NAME

Tpda3::Db::Connection::Cubrid - Connect to a Cubrid database.

=head1 VERSION

Version 0.62

=cut

our $VERSION = 0.62;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Cubrid;

    my $db = Tpda3::Db::Connection::Cubrid->new();

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

    my $dsn = qq{dbi:cubrid:database=$dbname;host=$host;port=$port};

    $self->{_dbh} = DBI->connect(
        $dsn, $user, $pass,
        {   FetchHashKeyName  => 'NAME_lc',
            AutoCommit        => 1,
            RaiseError        => 0,
            PrintError        => 0,
            LongReadLen       => 524288,
            HandleError       => sub { $self->handle_error() },
            #mysql_enable_utf8 => 1,
        }
    );

    return $self->{_dbh};
}

=head2 handle_error

Log errors.

=cut

sub handle_error {
    my $self = shift;

    my $errorstr;

    if ( defined $self->{_dbh} and $self->{_dbh}->isa('DBI::db') ) {
        $errorstr = $self->{_dbh}->errstr;
        Tpda3::Exception::Db::SQL->throw(
            logmsg  => $errorstr,
            usermsg => $self->parse_error($errorstr),
        );
    }
    else {
        $errorstr = DBI->errstr;
        Tpda3::Exception::Db::Connect->throw(
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
    my ( $self, $cb ) = @_;

    my $log = get_logger();

    $log->error("EE: $cb");

    my $message_type
        = $cb eq q{}                                         ? "nomessage"
        : $cb =~ m/Failed to connect to database server, ($RE{quoted})/smi
                                                             ? "serverdb:$1"
        : $cb =~ m/Cannot communicate with server/smi        ? "servererr"
        : $cb =~ m/User ($RE{quoted}) is invalid/smi         ? "username:$1"
        : $cb =~ m/Incorrect or missing password/smi         ? "password"
        :                                                      "unknown"
        ;

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        driver     => "fatal#Database driver $name not found",
        serverdb   => "fatal#Database not available $name",
        servererr  => "fatal#Server not available",
        username   => "warn#User $name is invalid",
        password   => "warn#Incorrect or missing password",
    };

    my $message;
    if ( exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        $log->error('EE: Translation error for: $type!');
    }

    return $message;
}

=head2 table_list

Return list of tables from the database.

=cut

sub table_list {
    my $self = shift;

    my $log = get_logger();

    $log->info('Geting list of tables');

    my $sql = q{SELECT class_name
                    FROM db_class WHERE is_system_class = 'NO';
    };

    $self->{_dbh}{AutoCommit} = 1;    # disable transactions
    $self->{_dbh}{RaiseError} = 0;

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

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the Cubrid driver
doesn't seem to be reliable.

=cut

sub table_info_short {
    my ( $self, $table ) = @_;

    my $log = get_logger();

    my $sth = $self->{_dbh}->column_info(undef, undef, $table, undef);

    my $flds_ref;
    try {
        while ( my $rec = $sth->fetchrow_hashref() ) {
            my ( $type, $length )
                = $self->type_and_length( $rec->{TYPE_NAME} );
            my $pos = $rec->{ORDINAL_POSITION};

            $flds_ref->{$pos} = {
                pos         => $pos,
                name        => $rec->{COLUMN_NAME},
                type        => $type,
                defa        => undef,                    # how to get?
                is_nullable => $rec->{NULLABLE},
                length      => $rec->{COLUMN_SIZE},      # $length?
                prec        => $rec->{COLUMN_SIZE},
                scale       => $rec->{DECIMAL_DIGITS},
            };
        }
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    return $flds_ref;
}

=head2 table_keys

Get the primary key field name of the table.

=cut

sub table_keys {
    my ( $self, $table, $foreign ) = @_;

    # $self->{_dbh}{AutoCommit} = 1;    # disable transactions
    # $self->{_dbh}{RaiseError} = 0;

    my $log = get_logger();

    #my $type = $foreign ? 'FOREIGN KEY' : 'PRIMARY KEY'; ???

    $log->info("Geting '$table' table primary key(s) names");

    #my @keys;
    my $pkf;
    try {
        my $sth = $self->{_dbh}->primary_key_info( undef, undef, $table );
        # table_cat table_schem table_name COLUMN_NAME key_seq pk_name
        # 0         1           2          3           4       5
        $pkf = [ ( $sth->fetchall_arrayref() )->[0][3] ];
        # All keys
        # while ( my $row_rf = $sth->fetchrow_arrayref() ) {
        #     push @keys, $row_rf->[3];
        # }
    }
    catch {
        $log->fatal("Transaction aborted because $_")
            or print STDERR "$_\n";
    };

    #return \@keys;
    return $pkf;
}

=head2 table_exists

Check if table exists in the database.

=cut

sub table_exists {
    my ( $self, $table ) = @_;

    my $log = get_logger();
    $log->info("Checking if $table table exists");

    my $sql = qq(SELECT class_name
                    FROM db_class
                    WHERE is_system_class = 'NO'
                           AND class_name = '$table';
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

=head2 type_and_length

Parse the TYPE_NAME attribute and return SQL type and a length.  The
TYPE_NAME can be something like VARCHAR(30) or INTEGER.  If there is
no length, return 10.

=cut

sub type_and_length {
    my ($self, $type_name) = @_;

    my ($type, $length);
    if ( $type_name =~ /^(\w+)($RE{balanced}{-parens=>'()'})/ ) {
        $type   = $1;
        $length = $2;
        ( $length = $2 ) =~ s/[()]//g;
    }
    else {
        $type_name =~ /^(\w+)/;
        $type   = $1;
        $length = 10;
    }

    return (lc($type), $length);
}

=head2 has_feature_returning

Returns no for CUBRID, meaning that is has not the INSERT... RETURNING
feature.

=cut

sub has_feature_returning { 0 }

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Db::Connection::Cubrid
