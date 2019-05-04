package Tpda3::Db::Connection::Cubrid;

# ABSTRACT: Connect to a Cubrid database

use strict;
use warnings;

use DBI;
use Log::Log4perl qw(get_logger :levels);
use Regexp::Common;
use Try::Tiny;

require Tpda3::Exceptions;

sub new {
    my ( $class, $model ) = @_;

    my $self = {};

    $self->{model} = $model;

    bless $self, $class;

    return $self;
}

sub driver {
    return 'CUBRID';
}

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
            RaiseError        => 1,
            PrintError        => 0,
            LongReadLen       => 524288,
            HandleError       => sub { $self->handle_error() },
        }
    );

    return $self->{_dbh};
}

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

sub parse_error {
    my ( $self, $cb ) = @_;

    my $log = get_logger();

    $log->error("EE: $cb");

    my $message_type
        = $cb eq q{}                                         ? "nomessage"
        : $cb =~ m/Cannot connect to CUBRID CAS/smi          ? "servererr"
        : $cb =~ m/Failed to connect to database server, ($RE{quoted})/smi
                                                             ? "serverdb:$1"
        : $cb =~ m/Cannot communicate with server/smi        ? "servererr"
        : $cb =~ m/User ($RE{quoted}) is invalid/smi         ? "username:$1"
        : $cb =~ m/Incorrect or missing password/smi         ? "password"
        : $cb =~ m/Missing value for attribute ($RE{quoted}) with the NOT NULL constraint/smi
                                                             ? "attrib:$1"
        :                                                      "unknown"
        ;

    # Analize and translate

    my ( $type, $name ) = split /:/, $message_type, 2;
    $name = $name ? $name : '';

    my $translations = {
        driver     => "error#Database driver for CUBRID not found",
        serverdb   => "error#Database not available $name",
        servererr  => "error#Server not available",
        username   => "error#User $name is invalid",
        attrib     => "error#Attribute $name error (NULL)",
        password   => "error#Incorrect or missing password",
    };

    my $message;
    if ( exists $translations->{$type} ) {
        $message = $translations->{$type};
    }
    else {
        $log->error("EE: Translation error for: $type!");
    }

    return $message;
}

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

sub has_feature_returning { 0 }

1;

=head1 SYNOPSIS

    use Tpda3::Db::Connection::Cubrid;

    my $db = Tpda3::Db::Connection::Cubrid->new();

    $db->db_connect($connection);

=head2 new

Constructor method.

=head2 db_connect

Connect to the database.

=head2 handle_error

Log errors.

=head2 parse_error

Parse a database error message, and translate it for the user.

RDBMS specific (and maybe version specific?).

=head2 table_list

Return list of tables from the database.

=head2 table_info_short

Table info 'short'.  The 'table_info' method from the Cubrid driver
doesn't seem to be reliable.

=head2 table_keys

Get the primary key field name of the table.

=head2 table_exists

Check if table exists in the database.

=head2 type_and_length

Parse the TYPE_NAME attribute and return SQL type and a length.  The
TYPE_NAME can be something like VARCHAR(30) or INTEGER.  If there is
no length, return 10.

=head2 has_feature_returning

Returns no for CUBRID, meaning that is has not the INSERT... RETURNING
feature.

=cut
