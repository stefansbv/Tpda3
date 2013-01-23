package Tpda3::Model;

use strict;
use warnings;

use Try::Tiny;
use SQL::Abstract;
use List::Compare;
use Data::Compare;
use Regexp::Common;
use Log::Log4perl qw(get_logger :levels);

use Tpda3::Exceptions;

require Tpda3::Config;
require Tpda3::Codings;
require Tpda3::Observable;
require Tpda3::Db;
require Tpda3::Utils;

=head1 NAME

Tpda3::Model - The Model

=head1 VERSION

Version 0.62

=cut

our $VERSION = 0.62;

=head1 SYNOPSIS

    use Tpda3::Model;

    my $model = Tpda3::Model->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {
        #_exception   => Tpda3::Observable->new(),
        _connected   => Tpda3::Observable->new(),
        _stdout      => Tpda3::Observable->new(),
        _appmode     => Tpda3::Observable->new(),
        _scrdata_rec => Tpda3::Observable->new(),
        _cfg         => Tpda3::Config->instance(),
        _msg_dict    => {},
        _log         => get_logger(),
    };

    bless $self, $class;

    return $self;
}

=head2 cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 _log

Return log instance variable.

=cut

sub _log {
    my $self = shift;

    return $self->{_log};
}

=head2 db_connect

Connect to the database.

=cut

sub db_connect {
    my $self = shift;

    # Connect to database or retry to connect
    if (Tpda3::Db->has_instance) {
        $self->{_dbh} = Tpda3::Db->instance->db_connect($self)->dbh;
    }
    else {
        $self->{_dbh} = Tpda3::Db->instance($self)->dbh;
    }

    return;
}

=head2 dbh

Return the database handler.

=cut

sub dbh {
    my $self = shift;

    if ( Tpda3::Db->has_instance ) {
        my $db = Tpda3::Db->instance;
        return $db->dbh if $self->is_connected;
    }

    Tpda3::Exception::Db::Connect->throw(
        logmsg  => 'not connected to the database',
        usermsg => 'Please restart and login',
    );

    return;
}

=head2 dbc

Return the Connection module handler.

=cut

sub dbc {
    my $self = shift;

    my $db = Tpda3::Db->instance;

    return $db->dbc;
}

=head2 is_connected

Return true if connected

TODO: What if the connection is lost?

=cut

sub is_connected {
    my $self = shift;

    return $self->get_connection_observable->get;
}

=head2 get_connection_observable

Get connection observable status

=cut

sub get_connection_observable {
    my $self = shift;

    return $self->{_connected};
}

=head2 get_stdout_observable

Get STDOUT observable status

=cut

sub get_stdout_observable {
    my $self = shift;

    return $self->{_stdout};
}

=head2 _print

Put a message on a text controll

=cut

sub _print {
    my ( $self, $data ) = @_;

    $self->get_stdout_observable->set($data);

    return;
}

=head2 set_mode

Set mode

=cut

sub set_mode {
    my ( $self, $mode ) = @_;

    $self->get_appmode_observable->set($mode);

    return;
}

=head2 is_mode

Return true if is mode

=cut

sub is_mode {
    my ( $self, $ck_mode ) = @_;

    my $mode = $self->get_appmode_observable->get;

    return unless $mode;

    return 1 if $mode eq $ck_mode;

    return;
}

=head2 get_appmode_observable

Return add mode observable status

=cut

sub get_appmode_observable {
    my $self = shift;

    return $self->{_appmode};
}

=head2 get_appmode

Return application mode

=cut

sub get_appmode {
    my $self = shift;

    return $self->get_appmode_observable->get;
}

=head2 set_scrdata_rec

Set screen data status for the I<rec> tab.

 false = loaded
 true  = modified
 undef = unloaded

=cut

sub set_scrdata_rec {
    my ( $self, $state ) = @_;

    $self->get_scrdata_rec_observable->set($state);

    return;
}

=head2 unset_scrdata_rec

Clear data status for the I<rec> tab.

 false = loaded
 true  = modified
 undef = unloaded *

=cut

sub unset_scrdata_rec {
    my $self = shift;

    $self->get_scrdata_rec_observable->unset();

    return;
}

=head2 get_scrdata_rec_observable

Return screen data status for the I<rec> tab.

=cut

sub get_scrdata_rec_observable {
    my $self = shift;

    return $self->{_scrdata_rec};
}

=head2 is_modified

Return true if screen data record is modified.

=cut

sub is_modified {
    my $self = shift;

    return $self->get_scrdata_rec_observable->get;
}

=head2 is_loaded

Return true if screen data record is loaded, if is not then the value
is undef.

=cut

sub is_loaded {
    my $self = shift;

    return defined $self->get_scrdata_rec_observable->get;
}

=head2 query_records_count

Count records in table. TODO.

=cut

sub query_records_count {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $pkcol = $opts->{pkcol} ? $opts->{pkcol} : '*';
    my $where = $self->build_sql_where($opts);

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, ["COUNT($pkcol)"], $where );

    my $record_count;
    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
        ($record_count) = $sth->fetchrow_array();
    }
    catch {
        $self->throw_exception_db($_);
    };

    $record_count = 0 unless defined $record_count;

    return $record_count;
}

=head2 query_records_find

Count records in table.  Here we need the contents of the screen to
build an sql where clause and also the column names from the
I<columns> configuration.

=cut

sub query_records_find {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $cols  = $opts->{columns};
    my $pkcol = $opts->{pkcol}{name};
    my $where = $self->build_sql_where($opts);

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $pkcol );

    my $search_limit = $self->cfg->application->{limits}{search} || 100;
    my $args = { MaxRows => $search_limit };    # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->dbh->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->throw_exception_db($_);
    };

    return ($ary_ref, $search_limit);
}

=head2 query_filter_find

Same as C<query_records_find> but returns an AoH suitable for TM fill.

=cut

sub query_filter_find {
    my ( $self, $opts, $debug ) = @_;

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


    # p $stmt;
    # p @bind;

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
        $self->throw_exception_db($_);
    };

    return \@records;
}

=head2 query_record

Return a record as hash reference

=cut

sub query_record {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $where = $opts->{where};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, undef, $where );

    # p $stmt;
    # p @bind;

    my $hash_ref;
    try {
        $hash_ref = $self->dbh->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->throw_exception_db($_);
    };

    return $hash_ref;
}

=head2 table_batch_query

Query records.

Option to add row count field to the returned data structure.

=cut

sub table_batch_query {
    my ( $self, $opts ) = @_;

    my $table    = $opts->{table};
    my $colslist = $opts->{colslist};
    my $where    = $opts->{where};
    my $order    = $opts->{order};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $colslist, $where, $order );

    my @records;
    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);

        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            push( @records, $record );
        }
    }
    catch {
        $self->throw_exception_db($_);
    };

    return \@records;
}

=head2 query_dictionary

Query a dictionary table

=cut

sub query_dictionary {
    my ( $self, $opts ) = @_;

    my $table   = $opts->{table};
    my $options = $opts->{options};
    my $order   = $opts->{order};
    my $cols    = $opts->{columns};

    my $where = $self->build_sql_where($opts);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $order );

    my $lookup_limit = $self->cfg->application->{limits}{lookup} || 50;
    my $args = { MaxRows => $lookup_limit };    # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->dbh->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->throw_exception_db($_);
    };

    return $ary_ref;
}

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

=cut

sub build_sql_where {
    my ( $self, $opts ) = @_;

    my $where = {};

    while ( my ( $field, $attrib ) = each( %{ $opts->{where} } ) ) {

        my $searchstr = $attrib->[0];
        my $find_type = $attrib->[1];

        unless ($find_type) {
            die "Unknown 'find_type': $find_type for '$field'";
        }

        if ( $find_type eq 'contains' ) {
            my $cmp = $self->cmp_function($searchstr);
            $where->{$field} = {
                $cmp => Tpda3::Utils->quote4like(
                    $searchstr, $opts->{options}
                )
            };
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

=head2 cmp_function

Compare function to use in SQL::Abstract, falls back to I<LIKE> for
unrecognised I>driver> names.

For B<Postgresql> and B<Firebird> uses functions that ignore case.

If the search string contains at least one upper case letter, make a
case sensitive search, else case insensitive.

=cut

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
        /cubrid/i && do {
            $cmp = $ignore_case ? '-LIKE' : '-LIKE';
            last SWITCH;
        };
        /firebird/i && do {
            $cmp = $ignore_case ? '-CONTAINING' : '-LIKE';
            last SWITCH;
        };
        /postgresql/i && do {
            $cmp = $ignore_case ? '-ILIKE' : '-LIKE';
            last SWITCH;
        };
        /sqlite/i && do {
            $cmp = $ignore_case ? '-LIKE' : '-LIKE';
            last SWITCH;
        };

        # Default
        warn "WW: Unknown database driver name: $driver!\n";
        $cmp = '-LIKE';
    }

    return $cmp;
}

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

=cut

sub tbl_dict_query {
    my ( $self, $para, $label_label, $value_label ) = @_;

    my $where;
    if ( $para->{table} eq 'codificari' ) {
        $where->{variabila} = $para->{field};
    }

    my $table  = $para->{table};
    my $fields = [ $para->{code}, $para->{name} ];
    my $order  = $para->{orderby} || $para->{name};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );

    my $sth;
    try { $sth = $self->dbh->prepare($stmt); }
    catch {
        $self->throw_exception_db($_);
    };

    my @dictrows;
    try {
        if (@bind) {
            $sth->execute(@bind);
        }
        else {
            $sth->execute();
        }

        while ( my $row_rf = $sth->fetchrow_arrayref() ) {
            push @dictrows, {
                $label_label => $row_rf->[1],
                $value_label => $row_rf->[0],
            };
        }
    }
    catch {
        $self->throw_exception_db($_);
    };

    return \@dictrows;
}

=head2 tbl_lookup_query

Lookup query.

=cut

sub tbl_lookup_query {
    my ( $self, $para ) = @_;

    my $table  = $para->{table};
    my $fields = [ $para->{field} ];
    my $where  = $para->{where};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where );

    my $sth;
    try { $sth = $self->dbh->prepare($stmt); }
    catch {
        $self->throw_exception_db($_);
    };

    my $row_rf;
    try {
        if (@bind) {
            $sth->execute(@bind);
        }
        else {
            $sth->execute();
        }

        $row_rf = $sth->fetchrow_arrayref();
    }
    catch {
        $self->throw_exception_db($_);
    };

    return $row_rf;
}

=head2 get_codes

Return the data structure used to fill the list of choices.

=cut

sub get_codes {
    my ( $self, $field, $para, $widget ) = @_;

    my $codings = Tpda3::Codings->new($self);
    my $codes = $codings->get_coding_init( $field, $para, $widget );

    return $codes;
}

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

=cut

sub table_record_insert {
    my ( $self, $table, $pkcol, $record ) = @_;

    my $has_feature = $self->dbc->has_feature_returning();

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind );
    if ($has_feature) {
        ( $stmt, @bind )
            = $sql->insert( $table, $record, { returning => $pkcol } );
    }
    else {
        ( $stmt, @bind ) = $sql->insert( $table, $record );
    }

    my $pk_id;
    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
        if ($has_feature) {
            $pk_id = $sth->fetch()->[0];
        }
        else {
            # The parameters are required, $table is ignord for CUBRID
            $pk_id = $self->dbh->last_insert_id(undef, undef, $table, undef);
        }
    }
    catch {
        $self->throw_exception_db($_);
    };

    return $pk_id;
}

=head2 table_record_update

Save screen data to a record in the DB.

=cut

sub table_record_update {
    my ( $self, $table, $record, $where ) = @_;

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->update( $table, $record, $where );

    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->throw_exception_db($_);
    };

    return;
}

=head2 table_record_select

Select record from table.

=cut

sub table_record_select {
    my ( $self, $table, $where ) = @_;

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, undef, $where );

    my $hash_ref;
    try {
        $hash_ref = $self->dbh->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->throw_exception_db($_);
    };

    return $hash_ref;
}

=head2 table_batch_insert

Save records from Table widget into DB.

Prepares the statement for every record, not only once!

TODO: Experiment with the example code from the I<PERFORMANCE> section
      in SQL::Abstract manual.

=cut

sub table_batch_insert {
    my ( $self, $table, $records ) = @_;

    my $sql = SQL::Abstract->new();

    # AoH refs
    foreach my $record ( @{$records} ) {

        my ( $stmt, @bind ) = $sql->insert( $table, $record );

        try {
            my $sth = $self->dbh->prepare($stmt);
            $sth->execute(@bind);
        }
        catch {
            $self->throw_exception_db($_);
        };
    }

    return;
}

=head2 table_record_delete

Deletes all records using a required WHERE SQL clause.

=cut

sub table_record_delete {
    my ( $self, $table, $where ) = @_;

    my $sql = SQL::Abstract->new();

    # Safety net..., is enough ???
    die "Empty TABLE name in DELETE command!" unless $table;
    die "Empty SQL WHERE in DELETE command!"  unless ( %{$where} );

    $self->_log->debug("Deleting from $table: ");
    #$self->_log->debug( sub { Dumper($where) } );

    my ( $stmt, @bind ) = $sql->delete( $table, $where );

    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->throw_exception_db($_);
    };

    return;
}

=head2 prepare_record_insert

Inserts a record.

The I<$record> parameter holds a complex AoH containing data colected
from the Screen controls (widgets) and the metadata needed to
construct the SQL commands.

=cut

sub prepare_record_insert {
    my ( $self, $record ) = @_;

    my $mainrec = $record->[0];    # main record first

    my $mainmeta = $mainrec->{metadata};
    my $maindata = $mainrec->{data};

    my $table = $mainmeta->{table};
    my $pkcol = $mainmeta->{pkcol};

    #- Main record

    my $pk_id = $self->table_record_insert( $table, $pkcol, $maindata );

    return unless $pk_id;

    #- Dependent records

    my $deprec = $record->[1];

    # One table at a time ...
    foreach my $tm ( keys %{$deprec} ) {
        my $depmeta = $deprec->{$tm}{metadata};
        my $depdata = $deprec->{$tm}{data};

        my $updstyle = $depmeta->{updstyle};
        my $table    = $depmeta->{table};
        my $pkcol    = $depmeta->{pkcol};

        # Update params for where
        $depmeta->{where}{$pkcol} = [ $pk_id, 'full' ];

        # Update PK column with the new $pk_id
        foreach my $rec ( @{$depdata} ) {
            $rec->{$pkcol} = $pk_id;
        }

        $self->table_batch_insert( $table, $depdata );
    }

    return $pk_id;
}

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

=cut

sub prepare_record_update {
    my ( $self, $record ) = @_;

    #- Main record

    my $mainmeta = $record->[0]{metadata};
    my $maindata = $record->[0]{data};

    my $table = $mainmeta->{table};
    my $where = $mainmeta->{where};

    $self->table_record_update( $table, $maindata, $where );

    #- Dependent records

    # One table at a time ...
    foreach my $tm ( keys %{ $record->[1] } ) {
        my $depmeta = $record->[1]{$tm}{metadata};
        my $depdata = $record->[1]{$tm}{data};

        my $updstyle = $depmeta->{updstyle};
        my $table    = $depmeta->{table};
        my $where    = $depmeta->{where};

        if ( $updstyle eq 'delete+add' ) {

            # Delete all articles and reinsert from TM ;)
            $self->table_record_delete( $table, $where );
            $self->table_batch_insert( $table, $depdata );
        }
        else {

            # Update based on comparison between the database table
            # data and TableMatrix data
            $self->table_batch_update( $depmeta, $depdata );
        }
    }

    return;
}

=head2 prepare_record_delete

Delete all detail records and then the record.

=cut

sub prepare_record_delete {
    my ( $self, $record ) = @_;

    #- Dependent records

    # One table at a time ...
    foreach my $tm ( keys %{ $record->[1] } ) {
        my $depmeta = $record->[1]{$tm}{metadata};

        my $table = $depmeta->{table};
        my $where = $depmeta->{where};

        # Delete all articles
        $self->table_record_delete( $table, $where );
    }

    #- Main record

    my $mainmeta = $record->[0]{metadata};

    my $table = $mainmeta->{table};
    my $where = $mainmeta->{where};

    # Delete record
    $self->table_record_delete( $table, $where );

    return;
}

=head2 table_batch_update

Compare article number for data in TM with data in DB and decide what
to insert, update or delete.

=cut

sub table_batch_update {
    my ( $self, $depmeta, $depdata ) = @_;

    my $compare_col = $depmeta->{fkcol};

    my $tb_data = $self->table_selectcol_as_array($depmeta);
    my $tm_data = $self->aoh_column_extract( $depdata, $compare_col );

    my $lc = List::Compare->new( $tm_data, $tb_data );

    my @to_update = $lc->get_intersection;
    my @to_insert = $lc->get_unique;
    my @to_delete = $lc->get_complement;

    my $to_update
        = $self->table_update_compare( \@to_update, $depmeta, $depdata );

    print "To update: @{$to_update}\n" if ref $to_update;
    print "To insert: @to_insert\n";
    print "To delete: @to_delete\n";

    $self->table_update_prepare( $to_update, $depmeta, $depdata );
    $self->table_insert_prepare( \@to_insert, $depmeta, $depdata );
    $self->table_delete_prepare( \@to_delete, $depmeta );

    return;
}

=head2 table_update_compare

Compare data in TM with the data in DB row by row and update only if
different.

=cut

sub table_update_compare {
    my ( $self, $to_update, $depmeta, $depdata ) = @_;

    return unless scalar( @{$to_update} ) > 0;

    my $table = $depmeta->{table};
    my $fkcol = $depmeta->{fkcol};
    my $where = $depmeta->{where};

    my @toupdate;
    foreach my $fk_id ( @{$to_update} ) {
        $where->{$fkcol} = $fk_id;

        # Filter data; record is Aoh
        my $record = ( grep { $_->{$fkcol} == $fk_id } @{$depdata} )[0];

        my $oldrec = $self->table_record_select( $table, $where );

        my $dc = Data::Compare->new( $oldrec, $record );

        push @toupdate, $fk_id if !$dc->Cmp;
    }

    return \@toupdate;
}

=head2 table_update_prepare

Prepare data for batch update.

=cut

sub table_update_prepare {
    my ( $self, $to_update, $depmeta, $depdata ) = @_;

    return unless $to_update;
    return unless scalar( @{$to_update} ) > 0;

    my $table = $depmeta->{table};
    my $fkcol = $depmeta->{fkcol};
    my $where = $depmeta->{where};

    foreach my $fk_id ( @{$to_update} ) {
        $where->{$fkcol} = $fk_id;

        # Filter data; record is Aoh
        my $record = ( grep { $_->{$fkcol} == $fk_id } @{$depdata} )[0];

        ### delete $record->{$fkcol}; # remove FK col from update data;
        # does NOT work, it's like remove
        # from the original datastructure?!

        $self->table_record_update( $table, $record, $where );
    }

    return;
}

=head2 table_insert_prepare

Prepare data for batch insert.

=cut

sub table_insert_prepare {
    my ( $self, $to_insert, $depmeta, $depdata ) = @_;

    return unless scalar( @{$to_insert} ) > 0;

    my $table = $depmeta->{table};
    my $fkcol = $depmeta->{fkcol};

    my @records;
    foreach my $fk_id ( @{$to_insert} ) {

        # Filter data; record is Aoh
        my $rec = ( grep { $_->{$fkcol} == $fk_id } @{$depdata} )[0];

        push @records, $rec;
    }

    # print "insert: $table\n";

    $self->table_batch_insert( $table, \@records );

    return;
}

=head2 table_delete_prepare

Prepare data for batch delete.

=cut

sub table_delete_prepare {
    my ( $self, $to_delete, $depmeta ) = @_;

    return unless scalar( @{$to_delete} ) > 0;

    my $table = $depmeta->{table};
    my $where = $depmeta->{where};

    $self->table_record_delete( $table, $where );

    return;
}

=head2 aoh_column_extract

Extract only a column from an AoH data structure.

=cut

sub aoh_column_extract {
    my ( $self, $depdata, $column ) = @_;

    my @dep_data;
    foreach my $rec ( @{$depdata} ) {
        my $data = $rec->{$column};
        push @dep_data, $data;
    }

    return \@dep_data;
}

=head2 table_selectcol_as_array

Return an array reference of column values.

=cut

sub table_selectcol_as_array {
    my ( $self, $opts ) = @_;

    my $table  = $opts->{table};
    my $pkcol  = $opts->{pkcol};
    my $fields = $opts->{fkcol};
    my $where  = $opts->{where};
    my $order  = $fields;

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );

    my $records;
    try {
        $records = $self->dbh->selectcol_arrayref( $stmt, undef, @bind );
    }
    catch {
        $self->throw_exception_db($_);
    };

    return $records;
}

=head2 record_compare

Compare the data structure created when a new record was loaded, the
witness record, with the current data structure from the screen.

=cut

sub record_compare {
    my ( $self, $witness, $record ) = @_;

    my $dc = Data::Compare->new( $witness, $record );

    # print 'Structures of $witness and $record are ',
    #     $dc->Cmp ? "" : "not ", "identical.\n";

    return !$dc->Cmp;
}

=head2 user_message

Parse the error string from the database and pass the relevant text to
the C<status_message> method in the View class.

=cut

sub user_message {
    my ($self, $error) = @_;

    $error =~ s{[\n\r]}{ }gmix;
    my $user_message = $self->dbc->parse_db_error($error);
    $user_message =~ s{"\."}{\.}gmix;        # "d"."t" ->  "d.t"

    $self->_print($user_message);

    return $user_message;
}

=head2 throw_exception_db

Try to catch existing exceptions.  (Re)Throw an exception on SQL or
Connection errors.

=cut

sub throw_exception_db {
    my ($self, $msg) = @_;

    print "(RE)Throw: '$msg'\n";

    if ( my $e = Exception::Base->catch($_) ) {
        if ( $e->isa('Tpda3::Exception::Db::Connect') ) {
            print "M: Not connected!\n";
            $e->throw;      # rethrow the exception
        }
        elsif ( $e->isa('Tpda3::Exception::Db::SQL')) {
            print "M: SQL exception!\n";
            $e->throw;      # rethrow the exception
        } {
            print 'Error!: ', $e->logmsg, "\n";
        }
    }
    else {
        Tpda3::Exception::Db::SQL->throw(
            logmsg  => $msg,
            usermsg => 'Database - SQL Error',
        );
    }

    return;
}

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

=cut

sub report_data {
    my ( $self, $mainmeta, $parentrow ) = @_;

    $parentrow = defined $parentrow ? $parentrow : 0;

    my $records = $self->table_batch_query($mainmeta);
    my $pk_col  = $mainmeta->{pkcol};
    my $cnt_col = $mainmeta->{rowcount};

    # Seperate ...
    my (@records, @uplevel);

    my %levelmeta;
    my $rc = 1;    # row count
    foreach my $r ( @{$records} ) {
        my ( $rec, $upl ) = ( {}, {} );
        foreach my $fld ( keys %{$r} ) {
            if ( $fld eq $pk_col ) {
                $upl->{$fld} = $r->{$fld};
            }
            else {
                $rec->{$fld} = $r->{$fld};
            }
        }
        $rec->{$cnt_col} = $rc;                  # add row count

        push @records, $rec;
        push @uplevel, { $rc => $upl };

        $rc++;
    }

    $levelmeta{$parentrow} = [@uplevel];

    return (\@records, \%levelmeta);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Model
