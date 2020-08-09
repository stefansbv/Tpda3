package Tpda3::Model;

# ABSTRACT: The Model

use feature 'say';
use Moo;
#use Log::Log4perl qw(get_logger :levels);
use Try::Tiny;
use Tpda3::Types qw(
    Bool
    DBIxConnector
    HashRef
    Maybe
    Tpda3Config
    Tpda3ConfigConnection
    Tpda3ModelDB
    Tpda3Observable
    Tpda3Target
);
use Tpda3::Exceptions;
use Tpda3::Config;
use Tpda3::Codings;
use Tpda3::Observable;
use Tpda3::Utils;
use Tpda3::Model::Update;
use Tpda3::Model::Update::Compare;
use Tpda3::Model::DB;
use namespace::autoclean;

# sub new {
#     my $class = shift;
#     my $self = {
#         _connected   => Tpda3::Observable->new(),
#         _stdout      => Tpda3::Observable->new(),
#         _appmode     => Tpda3::Observable->new(),
#         _scrdata_rec => Tpda3::Observable->new(),
#         _cfg         => Tpda3::Config->instance(),
#         _msg_dict    => {},
#         _log         => get_logger(),
#     };
#     bless $self, $class;
#     return $self;
# }

sub _log {
    my $self = shift;
    return $self->{_log};
}

has 'verbose' => (
    is      => 'ro',
    isa     => Bool,
    default => sub {
        my $self = shift;
        return $self->cfg->verbose;
    },
);

has 'debug' => (
    is      => 'ro',
    isa     => Bool,
    default => sub {
        my $self = shift;
        return $self->cfg->debug;
    },
);

has 'cfg' => (
    is      => 'ro',
    isa     => Tpda3Config,
    default => sub {
        return Tpda3::Config->instance;
    },
);

has 'info_db' => (
    is      => 'ro',
    isa     => Tpda3ConfigConnection,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Tpda3::Config::Connection->new;
    },
);

has 'target' => (
    is      => 'ro',
    isa     => Tpda3Target,
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->info_db->dbname;       # need to call this before 'uri'
        return Tpda3::Target->new(
            uri => $self->info_db->uri,
        );
    },
);

has 'connector' => (
    is      => 'ro',
    isa     => DBIxConnector,
    default => sub {
        my $self = shift;
        return $self->target->engine->connector;
    },
);

has 'db' => (
    is      => 'ro',
    isa     => Tpda3ModelDB,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Tpda3::Model::DB->new(
            cfg       => $self->cfg,
            debug     => $self->debug,
            target    => $self->target,
            connector => $self->connector,
        );
    },
);

my $observables = [
    qw{
        _connected
        _stdout
        _appmode
        _scrdata_rec
      }
];

has $observables => (
    is      => 'ro',
    isa     => Tpda3Observable,
    default => sub {
        return Tpda3::Observable->new;
    },
);

has '_msg_dict' => (
    is      => 'ro',
    isa     => Maybe[HashRef],
    default => sub {
        return {},
    },
);

sub db_connect {
    my $self = shift;
    try {
        my $engine = $self->target->engine;
        $engine->reset_connector;
        $self->{_dbh} = $engine->dbh;
    }
    catch {
        $self->db_exception($_, 'Connection failed');
    };
    $self->get_connection_observable->set(1);
    $self->_print('info#Connected');
    return;
}

sub dbh {
    my $self = shift;
    return $self->{_dbh} if $self->{_dbh}->isa('DBI::db');
}

sub is_connected {
    my $self = shift;
    return $self->get_connection_observable->get;
}

sub get_connection_observable {
    my $self = shift;
    return $self->{_connected};
}

sub get_stdout_observable {
    my $self = shift;
    return $self->{_stdout};
}

sub _print {
    my ( $self, $data ) = @_;
    $self->get_stdout_observable->set($data);
    return;
}

sub set_mode {
    my ( $self, $mode ) = @_;
    $self->get_appmode_observable->set($mode);
    return;
}

sub is_mode {
    my ( $self, $ck_mode ) = @_;
    my $mode = $self->get_appmode_observable->get;
    return unless $mode;
    return 1 if $mode eq $ck_mode;
    return;
}

sub get_appmode_observable {
    my $self = shift;
    return $self->{_appmode};
}

sub get_appmode {
    my $self = shift;
    return $self->get_appmode_observable->get;
}

sub set_scrdata_rec {
    my ( $self, $state ) = @_;
    $self->get_scrdata_rec_observable->set($state);
    return;
}

sub unset_scrdata_rec {
    my $self = shift;
    $self->get_scrdata_rec_observable->unset();
    return;
}

sub get_scrdata_rec_observable {
    my $self = shift;
    return $self->{_scrdata_rec};
}

sub is_modified {
    my $self = shift;
    return $self->get_scrdata_rec_observable->get;
}

sub is_loaded {
    my $self = shift;
    return defined $self->get_scrdata_rec_observable->get;
}

sub query_records_count {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $pkcol = $opts->{pkcol} ? $opts->{pkcol} : '*';
    my $where = $self->build_sql_where($opts);

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, ["COUNT($pkcol)"], $where );
    $self->debug_print_sql('query_records_count', $stmt, \@bind)
        if $self->debug;

    my $record_count;
    try {
        my $sth = $self->connector->run(
            fixup => sub {
                my $sth = $_->prepare($stmt);
                $sth->execute(@bind);
                ($record_count) = $sth->fetchrow_array();
                return $sth;
            });
    }
    catch {
        $self->db_exception($_, 'Count failed');
    };

    $record_count = 0 unless defined $record_count;

    return $record_count;
}

sub query_records_find {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $cols  = $opts->{columns};
    my $pkcol = $opts->{pkcol};
    my $where = $self->build_sql_where($opts);

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $pkcol );
    $self->debug_print_sql('query_records_find', $stmt, \@bind)
        if $self->debug;

    my $search_limit = $self->cfg->application->{limits}{search} || 100;
    my $args = { MaxRows => $search_limit };    # limit search result
    my $aref;
    try {
        $aref = $self->connector->run(
            fixup => sub {
                my $aref = $self->dbh->selectall_arrayref( $stmt, $args, @bind );
                return $aref;
            });
    }
    catch {
        $self->db_exception($_, 'Find failed');
    };
    return ($aref, $search_limit);
}

sub query_filter_find {
    my ( $self, $opts, $debug, $limit ) = @_;

    my $table = $opts->{table};
    my $cols  = $opts->{columns};
    my $order = $opts->{order} ? $opts->{order} : $opts->{pkcol};
    my $where = $opts->{where};

    # Remove 'id_art'; for 'SELECT *', $cols have to be undef
    if (ref $cols) {
        my @columns = grep { $_ ne 'id_art' } @{$cols};
        $cols = \@columns;
    }

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );
    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $order );
    $stmt .= qq{ LIMIT $limit} if defined $limit and $limit > 0;

    $self->debug_print_sql('query_filter_find', $stmt, \@bind)
        if $self->debug;

    my @records;
    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
        my $recnum = 0;
        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            $recnum++;
            $record->{id_art} = $recnum;     # add id_art column
            push( @records, $record );
        }
    }
    catch {
        $self->db_exception($_, 'Filter error');
    };

    return \@records;
}

sub query_filter_count {
    my ( $self, $opts, $debug ) = @_;

    my $table = $opts->{table};
    my $pkcol = $opts->{pkcol} ? $opts->{pkcol} : '*';
    my $where = $opts->{where};

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );
    my ( $stmt, @bind ) = $sql->select( $table, ["COUNT($pkcol)"], $where );

    $self->debug_print_sql('query_filter_count', $stmt, \@bind)
        if $self->debug;

    my $record_count;
    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
        ($record_count) = $sth->fetchrow_array();
    }
    catch {
        $self->db_exception($_, 'Count failed');
    };

    return $record_count;
}

sub query_record {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $cols  = $opts->{columns};
    my $where = $opts->{where};

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where );
    $self->debug_print_sql('query_record', $stmt, \@bind) if $self->debug;

    my $hash_ref;
    try {
        $hash_ref = $self->dbh->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->db_exception($_, 'Query failed');
    };

    return $hash_ref;
}

sub table_batch_query {
    my ( $self, $opts ) = @_;

    my $table    = $opts->{table};
    my $colslist = $opts->{colslist};
    my $where    = $opts->{where};
    my $order    = $opts->{order};

    die "Empty TABLE name in SELECT command!" unless $table;
    die "Empty COLUMN list in SELECT command for table '$table'!"
        unless scalar @{$colslist};

    # XXX Workaround for PostgreSQL procedure call -> "function_name()"
    if ( $self->dbc->driver eq 'PostgreSQL' ) {
        unless ( $self->dbc->table_exists( $table, 'or view' ) ) {
            $table .= '()';
            $self->_log->debug("Call $table as a function");
        }
    }

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $colslist, $where, $order );
    $self->debug_print_sql('table_batch_query', $stmt, \@bind)
        if $self->debug;

    my @records;
    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            push( @records, $record );
        }
    }
    catch {
        $self->db_exception($_, 'Batch query failed');
    };

    return \@records;
}

sub query_dictionary {
    my ( $self, $opts ) = @_;

    my $table   = $opts->{table};
    my $options = $opts->{options};
    my $order   = $opts->{order};
    my $cols    = $opts->{columns};

    my $where = $self->build_sql_where($opts);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $order );
    $self->debug_print_sql('query_dictionary', $stmt, \@bind)
        if $self->debug;

    my $lookup_limit = $self->cfg->application->{limits}{lookup} || 50;
    my $args = { MaxRows => $lookup_limit };    # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->dbh->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->db_exception($_, 'Dictionary query failed');
    };

    return $ary_ref;
}

sub query_exec_proc {
    my ( $self, $opts ) = @_;

    my $func  = $opts->{func};
    my $cols  = $opts->{columns};
    my $param = $opts->{param};

    my $place = '?';
    $place = ( '?,' x $#{$param} ) . '?' if ref $param eq 'ARRAY';

    my $cols_list = join ",", @{$cols};
    my $sql = qq{SELECT $cols_list
                     FROM ${func}($place);
                };
    my $sth;
    try {
        $sth = $self->dbh->prepare($sql);
    }
    catch {
        $self->db_exception( $_, "'query_exec_proc' prepare failed" );
    };
    my @records;
    try {
        if ( ref $param eq 'ARRAY' ) {
            $sth->execute( @{$param} );
        }
        else {
            $sth->execute($param);
        }
        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            push( @records, $record );
        }
    }
    catch {
        $self->db_exception( $_, 'Batch query procedure failed' );
    };
    return \@records;
}

sub build_sql_where {
    my ( $self, $opts ) = @_;

    my $where = {};

    foreach my $field ( keys %{ $opts->{where} } ) {
        my $attrib    = $opts->{where}{$field};
        my $searchstr = $attrib->[0];
        my $find_type = $attrib->[1];

        unless ($find_type) {
            die "Unknown 'find_type': $find_type for '$field'";
        }

        if ( $find_type eq 'contains' ) {
            my $cmp = $self->cmp_function($searchstr);
            if ($cmp eq '-CONTAINING') {
                # Firebird specific
                $where->{$field} = { $cmp => $searchstr };
            }
            else {
                $where->{$field} = {
                    $cmp => Tpda3::Utils->quote4like(
                        $searchstr, $opts->{options}
                    )
                };
            }
        }
        elsif ( $find_type eq 'full' ) {
            $where->{$field} = $searchstr;
        }
        elsif ( $find_type eq 'date' ) {
            my $ret = Tpda3::Utils->process_date_string($searchstr);
            if ( $ret eq 'dataerr' ) {
                $self->_print('warn#Wrong search parameter');
                return;
            }
            else {
                $where->{$field} = $ret;
            }
        }
        elsif ( $find_type eq 'isnull' ) {
            $where->{$field} = undef;
        }
        elsif ( $find_type eq 'notnull' ) {
            $where->{$field} = undef;
            my $notnull = q{IS NOT NULL};
            $where->{$field} = \$notnull;
        }
        elsif ( $find_type eq 'none' ) {

            # just skip
        }
        else {
            die "Unknown 'find_type': $find_type for '$field'";
        }
    }

    return $where;
}

sub cmp_function {
    my ( $self, $search_str ) = @_;

    my $ignore_case = 1;
    if ( $search_str =~ m/\p{IsLu}{1,}/ ) {
        $ignore_case = 0;
    }

    my $driver = $self->cfg->connection->{driver};

    my $cmp;
  SWITCH: for ($driver) {
        /^$/ && warn "EE: Unknown database driver name!\n";
        /cubrid/xi && do {
            $cmp = $ignore_case ? '-LIKE' : '-LIKE';
            last SWITCH;
        };
        /fb|firebird/xi && do {
            $cmp = $ignore_case ? '-CONTAINING' : '-LIKE';
            last SWITCH;
        };
        /pg|postgresql/xi && do {
            $cmp = $ignore_case ? '-ILIKE' : '-LIKE';
            last SWITCH;
        };
        /sqlite/xi && do {
            $cmp = $ignore_case ? '-LIKE' : '-LIKE';
            last SWITCH;
        };
        /odbcfb/xi && do {
            $cmp = $ignore_case ? '-CONTAINING' : '-LIKE';
            last SWITCH;
        };

        # Default
        warn "WW: Unknown database driver name: $driver!\n";
        $cmp = '-LIKE';
    }

    return $cmp;
}

sub tbl_dict_query {
    my ( $self, $para, $label_lbl, $value_lbl ) = @_;

    my $where;
    if ( $para->{table} eq 'codificari' ) {
        $where->{variabila} = $para->{field};
    }

    my $table  = $para->{table};
    my $fields = [ $para->{code}, $para->{name} ];
    my $order  = $para->{orderby} || $para->{name};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );
    $self->debug_print_sql('tbl_dict_query', $stmt, \@bind) if $self->debug;

    my $sth;
    try { $sth = $self->dbh->prepare($stmt); }
    catch {
        $self->db_exception($_, 'Table dictionary query failed');
    };

    my @dictrows;
    try {
        @bind ? $sth->execute(@bind) : $sth->execute();
        while ( my $row_rf = $sth->fetchrow_arrayref() ) {
            push @dictrows, {
                $label_lbl => Tpda3::Utils->decode_unless_utf( $row_rf->[1] ),
                $value_lbl => Tpda3::Utils->decode_unless_utf( $row_rf->[0] ),
            };
        }
    }
    catch {
        $self->db_exception($_, 'Table dictionary query failed');
    };

    return \@dictrows;
}

sub tbl_lookup_query {
    my ( $self, $para, $debug ) = @_;

    my $table  = $para->{table};
    my $fields = [ $para->{field} ];
    my $where  = $para->{where};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where );
    $self->debug_print_sql('tbl_lookup_query', $stmt, \@bind) if $self->debug;

    my $sth;
    try { $sth = $self->dbh->prepare($stmt); }
    catch {
        $self->db_exception($_, 'Lookup failed');
    };

    my $row_rf;
    try {
        @bind ? $sth->execute(@bind) : $sth->execute();
        $row_rf = $sth->fetchrow_arrayref();
    }
    catch {
        $self->db_exception($_, 'Lookup failed');
    };

    return $row_rf;
}

sub get_codes {
    my ( $self, $field, $para, $widget ) = @_;
    my $codings = Tpda3::Codings->new($self);
    my $codes = $codings->get_coding_init( $field, $para, $widget );
    return $codes;
}

sub other_data {
    my ($self, $model_name) = @_;

    # Specific data for the current template
    my $args = {};
    $args->{table}    = 'templates';
    $args->{colslist} = [qw{id_tt}];
    $args->{where}    = { tt_file => $model_name };
    my $tt_aref       = $self->db->table_batch_query($args);
    my $id_tt         = $tt_aref->[0]{id_tt};

    # Common data for all templates
    my $tt_datasources = $self->db->get_template_datasources($id_tt);
    my $common_table
        = ( ref $tt_datasources eq 'HASH' )
        ? $tt_datasources->{common_data}
        : undef;
    my %common;
    if ($common_table) {
        $args             = {};
        $args->{table}    = $common_table;              # ex: semnaturi
        $args->{colslist} = [qw{var_name var_value}];
        $args->{order}    = undef;
        $args->{where}    = undef;
        my $common_aref = $self->db->table_batch_query($args);
        %common = map { $_->{var_name} => $_->{var_value} } @{$common_aref};
    }
    else {
        %common = ();
    }

    # Specific data for the current template
    $args = {};
    $args->{table}    = 'templates_var';
    $args->{colslist} = [qw{var_name var_value}];
    $args->{where}    = { id_tt => $id_tt };
    $args->{order}    = 'id_tt';
    my $specif_aref   = $self->table_batch_query($args);
    my %specific = map { $_->{var_name} => $_->{var_value} } @{$specif_aref};

    # Merge and return
    return Hash::Merge->new->merge(
        \%common,
        \%specific,
    );
}

1;

=head1 SYNOPSIS

    use Tpda3::Model;

    my $model = Tpda3::Model->new();

=head2 new

Constructor method.

=head2 cfg

Return configuration instance object.

=head2 log

Return log instance variable.

=head2 db_connect

Connect to the database.

=head2 dbh

Return the database handler.

=head2 dbc

Return the Connection module handler.

=head2 is_connected

Return true if connected

TODO: What if the connection is lost?

=head2 get_connection_observable

Get connection observable status

=head2 get_stdout_observable

Get STDOUT observable status

=head2 _print

Put a message on a text controll

=head2 set_mode

Set mode

=head2 is_mode

Return true if is mode

=head2 get_appmode_observable

Return add mode observable status

=head2 get_appmode

Return application mode

=head2 set_scrdata_rec

Set screen data status for the I<rec> tab.

 false = loaded
 true  = modified
 undef = unloaded

=head2 unset_scrdata_rec

Clear data status for the I<rec> tab.

 false = loaded
 true  = modified
 undef = unloaded *

=head2 get_scrdata_rec_observable

Return screen data status for the I<rec> tab.

=head2 is_modified

Return true if screen data record is modified.

=head2 is_loaded

Return true if screen data record is loaded, if is not then the value
is undef.

=head2 query_records_count

Count records in table. TODO.

=head2 query_records_find

TODO: fix pod contents! Here we need the contents of the screen to build an sql
where clause and also the column names from the I<columns>
configuration.

=head2 query_filter_find

Same as C<query_records_find> but returns an AoH suitable for TM fill.

=head2 query_filter_count

=head2 query_record

Return a record as hash reference

=head2 table_batch_query

Query records and return an AoH.

Option to add row count field to the returned data structure.

=head2 query_dictionary

Query a dictionary table

=head2 build_sql_where

Return a hash reference containing where clause attributes.

Table columns (fields) used in the screen have a configuration named
I<findtype> that is used to build the appropriate where clause.

Valid configuration options are:

=over

=item contains - the field value contains the search string

=item full   - the field value equals the search string

=item date     - special case for date type fields

=item none     - no search for this field

=back

Second parameter 'option' is passed to quote4like.

If the search string equals with I<%> or I<!>, then generated where
clause will be I<field1> IS NOT NULL and respectively I<field2> IS
NULL.

=head2 cmp_function

Compare function to use in SQL::Abstract, falls back to I<LIKE> for
unrecognised I>driver> names.

For B<Postgresql> and B<Firebird> uses functions that ignore case.

If the search string contains at least one upper case letter, make a
case sensitive search, else case insensitive.

=head2 tbl_dict_query

Query a table for codes.  Return S<< key -> value >>, pairs used to
fill the I<choices> attributes of widgets like L<Tk::JComboBox>.

There is a default table for codes named 'codificari' (named so, in
the first version of TPDA).

The I<codificari> table has the following structure:

   id_ord    INTEGER NOT NULL
   variabila VARCHAR(15)
   filtru    VARCHAR(5)
   cod       VARCHAR(5)
   denumire  VARCHAR(25) NOT NULL

The I<variabila> columns contains the name of the field, because this
is a table used for many different codings.  When this table is used,
a where clause is constructed to filter only the values coresponding
to I<variabila>.

There is another column named I<filtru> than can be used to restrict
the values listed when they depend on the value of another widget in
the current screen (not yet used!).

If the configuration has an I<orderby> field use it else order by
description (name).

TODO: Change the field names

=head2 tbl_lookup_query

Lookup query.

=head2 get_codes

Return the data structure used to fill the list of choices.

=head2 table_record_insert

Insert new record in the DB.

Using the RETURNING feature...

 Postgres version 8.2 or greater
 Firebird version 2.1 or greater

BUG:

For SQLite, instead of catching and reporting the first error it
reports the last, but the relevant one is the first:

DBD::SQLite::db prepare failed: near "RETURNING": syntax error ...

Uses the B<last_insert_id> function if the database doesn't support the
INSERT... RETURNING feature.

The parameters for B{last_insert_id} are required. The $table
parameter is ignord for CUBRID.

=head2 table_record_update

Save screen data to a record in the DB.

=head2 table_record_select

Select record from table.

=head2 table_batch_insert

Save records from Table widget into DB.

Prepares the statement for every record, not only once!

TODO: Experiment with the example code from the I<PERFORMANCE> section
      in SQL::Abstract manual.

=head2 table_record_delete

Deletes all records using a required WHERE SQL clause.

=head2 prepare_record_insert

Inserts a record.

The I<$record> parameter holds a complex AoH containing data colected
from the Screen controls (widgets) and the metadata needed to
construct the SQL commands.

=head2 prepare_record_update

Updates a record.

The I<$record> parameter holds a complex AoH containing data colected
from the Screen controls (widgets) and the meta-data needed to
construct the SQL commands.

There is a new setting in the Screen configuration in the 'deptable'
section named I<updatestyle>.

=over

=item delete+add Delete all articles followed by re-insert

This is the old style behavior of Tpda. All dependent records are
deleted first and than reinserted with data from the TableMatrix
widget.  This has the advantage of automatic renumbering of the
articles, when an article is deleted - suitable for Orders.

=item update    Update the existing articles, insert new

The articles are not renumbered, as a consequence if an article is
deleted, the I<artno> of the other articles is preserved and gaps may
appear.

=back

=head2 prepare_record_delete

Delete all detail records and then the record.

=head2 table_batch_update

Compare article number for data in TM with data in DB and decide what
to insert, update or delete.

=head2 table_update_compare

Compare data in TM with the data in DB row by row and update only if
different.

=head2 table_selectcol_as_array

Return an array reference of column values.

=head2 record_compare

Compare the data structure created when a new record was loaded, the
witness record, with the current data structure from the screen.

=head2 user_message

Parse the error string from the database and pass the relevant text to
the C<status_message> method in the View class.

=head2 db_exception

Try to catch existing exceptions.  (Re)Throw an exception on SQL or
Connection errors.

=head2 report_data

Return data in custom data structures for the report style screens.

The first data structure it's a AoH to be displayed in the Tpda3::TMSHR
widget.

  [
    { 'nr_crt' => 1, 'firma' => 'Name 1' },
    { 'nr_crt' => 2, 'firma' => 'Name 2' },
    { 'nr_crt' => 3, 'firma' => 'Name 3' },
  ];

The second data structure is also an AoH used to retrieve the detail
data for each row. Maps the widget row number with the PK col value of
the database table.

  [
    { '1' => { 'id_firma' => 1 } },          # -> Name 1
    { '2' => { 'id_firma' => 3 } },          # -> Name 3
    { '3' => { 'id_firma' => 2 } },          # -> Name 2
  ];

=head2 table_columns

Return the table columns for the named table.

=head2 table_keys

Return the table keys for the named table.

=head2 get_template_datasources

Return the template data sources from the template configuration.

=head2 other_data

Get info about the datasources for the TT template from the templates table.

=head2 update_or_insert

Update or insert records in table.

BUG: Specific to Firebird!

=cut
