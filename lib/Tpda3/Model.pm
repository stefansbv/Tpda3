package Tpda3::Model;

use strict;
use warnings;
use Carp;

use Try::Tiny;
use SQL::Abstract;
use List::Compare;
use Data::Compare;
use Regexp::Common;
use Log::Log4perl qw(get_logger :levels);
use Data::Dumper;

use Tpda3::Config;
use Tpda3::Codings;
use Tpda3::Observable;
use Tpda3::Db;
use Tpda3::Utils;

=head1 NAME

Tpda3::Model - The Model

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

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

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
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

=head2 toggle_db_connect

Toggle database connection

=cut

sub toggle_db_connect {
    my $self = shift;

    if ( $self->is_connected ) {
        $self->_disconnect();
    }
    else {
        $self->_connect();
    }

    return $self;
}

=head2 _connect

Connect to the database

=cut

sub _connect {
    my $self = shift;

    # Connect to database
    $self->{_dbh} = Tpda3::Db->instance->dbh;

    # Is realy connected ?
    if ( ref( $self->{_dbh} ) =~ m{DBI} ) {
        $self->get_connection_observable->set(1);    # yes
    }
    else {
        $self->get_connection_observable->set(0);    # no ;)
        $self->_print('error#Connection failed');
    }

    return;
}

=head2 _disconnect

Disconnect from the database

=cut

sub _disconnect {
    my $self = shift;

    $self->{_dbh}->disconnect;
    $self->get_connection_observable->set(0);
    $self->_print('info#Disconnected');

    return;
}

=head2 is_connected

Return true if connected

=cut

sub is_connected {
    my $self = shift;

    # TODO: What if the connection is lost?

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

=head2 message_dictionary

Hash structure used to compose user friendly messages.

=cut

sub message_dictionary {
    my ($self, $dict) = @_;

    $self->{_msg_dict} = $dict;

    return;
}

=head2 query_records_count

Count records in table. TODO.

=cut

sub query_records_count {
    my ( $self, $rec ) = @_;

    my $table = $rec->{table};
    my $pkcol = $rec->{pkcol};
    my $where = $self->build_where($rec);

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, ["COUNT($pkcol)"], $where );

    my $record_count;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);

        $sth->execute(@bind);

        ($record_count) = $sth->fetchrow_array();
    }
    catch {
        $self->error_show($_);
    };

    $self->_print("info#$record_count records");

    return;
}

=head2 query_records_find

Count records in table.  Here we need the contents of the screen to
build an sql where clause and also the column names from the
I<columns> configuration.

=cut

sub query_records_find {
    my ( $self, $rec ) = @_;

    my $table = $rec->{table};
    my $cols  = $rec->{columns};
    my $pkcol = $rec->{pkcol};
    my $where = $self->build_where($rec);

    return if !ref $where;

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $pkcol );

    my $search_limit = $self->_cfg->application->{limits}{search} || 100;
    my $args = { MaxRows => $search_limit };    # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->{_dbh}->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->error_show($_);
    };

    my $record_count = scalar @{$ary_ref};
    $self->_print("info#$record_count records");

    return $ary_ref;
}

=head2 query_record

Return a record as hash reference

=cut

sub query_record {
    my ( $self, $rec ) = @_;

    my $table = $rec->{table};
    my $where = $rec->{where};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, undef, $where );

    my $hash_ref;
    try {
        $hash_ref = $self->{_dbh}->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->error_show($_);
    };

    return $hash_ref;
}

=head2 table_batch_query

Query records.

Option to add row count field to the returned data structure.

=cut

sub table_batch_query {
    my ( $self, $rec ) = @_;

    my $table    = $rec->{table};
    my $colslist = $rec->{colslist};
    my $where    = $rec->{where};
    my $order    = $rec->{order};

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $colslist, $where, $order );

    my @records;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);

        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            push( @records, $record );
        }
    }
    catch {
        $self->error_show($_);
    };

    return \@records;
}

=head2 query_dictionary

Query a dictionary table

=cut

sub query_dictionary {
    my ( $self, $rec ) = @_;

    my $table = $rec->{table};
    my $opt   = $rec->{options};
    my $order = $rec->{order};
    my $cols  = $rec->{columns};

    my $where = $self->build_where( $rec, $opt );

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $order );

    my $lookup_limit = $self->_cfg->application->{limits}{lookup} || 50;
    my $args = { MaxRows => $lookup_limit };    # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->{_dbh}->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->error_show($_);
    };

    return $ary_ref;
}

=head2 build_where

Return a hash reference containing where clause attributes.

Table columns (fields) used in the screen have a configuration named
I<findtype> that is used to build the appropriate where clause.

Valid configuration options are:

=over

=item contains - the field value contains the search string

=item allstr   - the field value equals the search string

=item date     - special case for date type fields

=item none     - no search for this field

=back

Second parameter 'option' is passed to quote4like.

If the search string equals with I<%> or I<!>, then generated where
clause will be I<field1> IS NOT NULL and respectively I<field2> IS
NULL.

=cut

sub build_where {
    my ( $self, $rec, $opt ) = @_;

    my $where = {};

    while ( my ( $field, $attrib ) = each( %{ $rec->{where} } ) ) {

        my $searchstr = $attrib->[0];
        my $find_type = $attrib->[1];

        unless ($find_type) {
            croak "Configuration error: unknown 'findtype' for '$field'";
        }

        if ( $find_type eq 'contains' ) {
            my $cmp = $self->cmp_function($searchstr);
            $where->{$field}
                = { $cmp => Tpda3::Utils->quote4like( $attrib->[0], $opt ) };
        }
        elsif ( $find_type eq 'allstr' ) {
            $where->{$field} = $attrib->[0];
        }
        elsif ( $find_type eq 'date' ) {
            my $ret = Tpda3::Utils->process_date_string( $attrib->[0] );
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

    my $driver = $self->_cfg->connection->{driver};

    my $cmp;
SWITCH: for ($driver) {
        /^$/ && warn "EE: Unknown database driver name!\n";
        /postgresql/i && do {
            $cmp = $ignore_case ? '-ILIKE' : '-LIKE';
            last SWITCH;
        };
        /firebird/i && do {
            $cmp = $ignore_case ? '-CONTAINING' : '-LIKE';
            last SWITCH;
        };

        # Default
        warn "EE: Unknown database driver name: $driver!\n";
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

    my @dictrows;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);
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
        $self->error_show($_);
    };

    return \@dictrows;
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

Using the RETURNING ...

 Postgres version 8.2 or greater: RETURNING
 Firebird version 2.1 or greater: RETURNING - NOT tested!

=cut

sub table_record_insert {
    my ( $self, $table, $pkcol, $record ) = @_;

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind )
        = $sql->insert( $table, $record, { returning => $pkcol } );

    my $pk_id;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
        $pk_id = $sth->fetch()->[0];
    }
    catch {
        $self->error_show($_);
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
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->error_show($_);
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
        $hash_ref = $self->{_dbh}->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->error_show($_);
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
            my $sth = $self->{_dbh}->prepare($stmt);
            $sth->execute(@bind);
        }
        catch {
            $self->error_show($_);
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

    croak "Empty TABLE name in DELETE command!"
        unless $table;

    croak "Empty SQL WHERE in DELETE command!"
        unless ( %{$where} );    # safety net, is enough ???

    $self->_log->debug("Deleting from $table: ");
    $self->_log->debug( sub { Dumper($where) } );

    my ( $stmt, @bind ) = $sql->delete( $table, $where );

    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->error_show($_);
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
        $depmeta->{where}{$pkcol} = [ $pk_id, 'allstr' ];

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
        # does NOT work, it's like remmove
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
    my ( $self, $rec ) = @_;

    my $table  = $rec->{table};
    my $pkcol  = $rec->{pkcol};
    my $fields = $rec->{fkcol};
    my $where  = $rec->{where};
    my $order  = $fields;

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );

    my $records;
    try {
        $records = $self->{_dbh}->selectcol_arrayref( $stmt, undef, @bind );
    }
    catch {
        $self->error_show($_);
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

    #print Dumper( $witness, $record );

    # print 'Structures of $witness and $record are ',
    #     $dc->Cmp ? "" : "not ", "identical.\n";

    return !$dc->Cmp;
}

=head2 error_show

Parse the error string from the database and pass the relevant text to
the L<status_message> method in the View class.

TODO: Test and extend for Firebird.

Extract the quoted string as I<key> from the error message and use it
to construct an user friendly message to show in the status bar using
a hash data structure implemented in the screen module.

=cut

sub error_show {
    my ($self, $error) = @_;

    $self->_log->error($error);

    (my $key) = $error =~ m/($RE{quoted})/smi; # only for PostgreSQL
    $key ||= q{'unknown error'};
    $key =~ s{['"]}{}gmi;

    $key = $self->{_msg_dict}->{$key} if exists $self->{_msg_dict}->{$key};

    $self->_print("error#$key");

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
    my ( $self, $mainmeta ) = @_;

    my $records = $self->table_batch_query($mainmeta);
    my $pk_col  = $mainmeta->{pkcol};
    my $cnt_col = $mainmeta->{rowcount};

    # Seperate ...
    my (@records, @uplevel);

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

    return (\@records, \@uplevel);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Model
