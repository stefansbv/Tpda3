package Tpda3::Model;

use strict;
use warnings;

use Data::Dumper;
use Carp;

use Try::Tiny;
use SQL::Abstract;
use List::Compare;

use Tpda3::Config;
use Tpda3::Observable;
use Tpda3::Db;
use Tpda3::Codings;
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
        _connected => Tpda3::Observable->new(),
        _stdout    => Tpda3::Observable->new(),
        _appmode   => Tpda3::Observable->new(),
        _modified  => Tpda3::Observable->new(),
        _cfg       => Tpda3::Config->instance(),
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
        $self->get_connection_observable->set( 1 ); # yes
        $self->_print('Connected');
        # print "Connected\n";
    }
    else {
        $self->get_connection_observable->set( 0 ); # no ;)
        $self->_print('Connection error!');
        print "Connection error!\n";
    }

    return;
}

=head2 _disconnect

Disconnect from the database

=cut

sub _disconnect {
    my $self = shift;

    $self->{_dbh}->disconnect;
    $self->get_connection_observable->set( 0 );
    $self->_print('Disconnected');

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
    my ( $self, $msg ) = @_;

    $self->get_stdout_observable->set($msg);

    return;
}

=head2 set_mode

Set mode

=cut

sub set_mode {
    my ($self, $mode) = @_;

    $self->get_appmode_observable->set($mode);

    return;
}

=head2 is_mode

Return true if is mode

=cut

sub is_mode {
    my ($self, $mode) = @_;

    if ($self->get_appmode_observable->get eq $mode) {
        return 1;
    }
    else {
        return;
    }
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

=head2 set_modified

Set modified

=cut

sub set_modified {
    my ($self, $state) = @_;

    $self->get_modified_observable->set($state);

    return;
}

=head2 get_modified_observable

Return add mode observable status

=cut

sub get_modified_observable {
    my $self = shift;

    return $self->{_modified};
}

=head2 is_modified

Return true if record is modified

=cut

sub is_modified {
    my $self = shift;

    if ($self->get_modified_observable->get) {
        return 1;
    }
    else {
        return;
    }
}

=head2 query_records_count

Count records in table

=cut

sub query_records_count {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $pkcol = $data_hr->{pkcol};

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select(
        $table, ["COUNT($pkcol)"], $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $record_count;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);

        $sth->execute(@bind);

        ($record_count) = $sth->fetchrow_array();
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    $self->_print("$record_count records found") ;

    return;
}

=head2 query_records_find

Count records in table.  Here we need the contents of the screen to
build an sql where clause and also the column names from the
I<columns> configuration.

=cut

sub query_records_find {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $pkcol = $data_hr->{pkcol};

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $data_hr->{columns}, $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $search_limit = $self->_cfg->application->{limits}{search} || 100;
    my $args = { MaxRows => $search_limit }; # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->{_dbh}->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    my $record_count = scalar @{$ary_ref};
    $self->_print("$record_count records listed") ;

    return $ary_ref;
}

=head2 query_record

Return a record as hash reference

=cut

sub query_record {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $pkcol = $data_hr->{pkcol};
    my $where = $data_hr->{where};

    # my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, undef, $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $hash_ref;
    try {
        $hash_ref = $self->{_dbh}->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return $hash_ref;
}

=head2 table_batch_query

Query records.

=cut

sub table_batch_query {
    my ( $self, $data_hr ) = @_;

    my $table  = $data_hr->{table};
    my $pkcol  = $data_hr->{pkcol};
    my $order  = $data_hr->{fkcol};
    my $fields = $data_hr->{colslist};

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );

    # print "SQL : $stmt\    # print "bind: @bind\n";

    my @records;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);

        while ( my $record = $sth->fetchrow_hashref('NAME_lc') ) {
            push( @records, $record );
        }
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return \@records;
}

=head2 query_dictionary

Query a dictionary table

=cut

sub query_dictionary {
    my ( $self, $data_hr ) = @_;

    my $table = $data_hr->{table};
    my $opt   = $data_hr->{options};
    my $order = $data_hr->{order};
    my $cols  = $data_hr->{columns};

    my $where = $self->build_where($data_hr, $opt);

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where, $order );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $lookup_limit = $self->_cfg->application->{limits}{lookup} || 50;
    my $args = { MaxRows => $lookup_limit }; # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->{_dbh}->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return $ary_ref;
}

=head2 build_where

Return a hash reference containing where clause attributes.  Table
columns (fields) used in the screen has a configuration named
I<findtype> used for choosing which form to use in the ...

Valid configuration options are:

=over

=item contains - the field value contains the search string

=item allstr   - the field value equals the search string

=item date     - special case for date type fields

=item none     - no search for this field

=back

Second parameter 'option' is passed to quote4like.

=cut

sub build_where {
    my ( $self, $data_hr, $opt ) = @_;

    my $where = {};

    while ( my ( $field, $attrib ) = each( %{ $data_hr->{where} } ) ) {
        my $find_type = $attrib->[1];

        unless ($find_type) {
            croak "Config error: unknown 'findtype' configured for '$field'";
        }

        if ( $find_type eq 'contains' ) {
            $where->{$field} =
                { -like => Tpda3::Utils->quote4like( $attrib->[0], $opt ) };
        }
        elsif ( $find_type eq 'allstr' ) {
            $where->{$field} = $attrib->[0];
        }
        elsif ( $find_type eq 'date' ) {
            $where->{$field} =
              Tpda3::Utils->process_date_string( $attrib->[0] );
        }
        elsif ( $find_type eq 'none' ) {

            # just skip
        }
    }

    return $where;
}

=head2 get_codes

Return the data structure used to fill the list of choices.

=cut

sub get_codes {
    my ($self, $field, $para) = @_;

    my $codings = Tpda3::Codings->new();
    my $codes   = $codings->get_coding_init($field, $para);

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

    my ( $stmt, @bind ) = $sql->insert( $table, $record, {returning => $pkcol} );

    my $pk_id;
    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
        $pk_id = $sth->fetch()->[0];
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
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
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return 1;
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
    foreach my $rec ( @{$records} ) {

        my ( $stmt, @bind ) = $sql->insert( $table, $rec );

        try {
            my $sth = $self->{_dbh}->prepare($stmt);
            $sth->execute(@bind);
        }
        catch {
            $self->_print("Database error!");
            croak("Transaction aborted: $_");
        };
    }

    return;
}

=head2 table_batch_delete

Deletes all records using a required WHERE SQL clause.

=cut

sub table_batch_delete {
    my ( $self, $table, $where ) = @_;

    my $sql = SQL::Abstract->new();

    croak "Empty SQL WHERE in DELETE command!"
        unless ( %{$where} );   # safety net, is enough ???

    my ( $stmt, @bind ) = $sql->delete( $table, $where );

    try {
        my $sth = $self->{_dbh}->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return;
}

=head2 store_record

Inserts a record.

The I<$record> parameter holds a complex AoH containing data colected
from the Screen controls (widgets) and the metadata needed to
construct the SQL commands.

=cut

sub store_record_insert {
    my ( $self, $record) = @_;

    my $mainrec = $record->[0];              # main record first

    my $mainmeta = $mainrec->{metadata};
    my $maindata = $mainrec->{data};
    my $table    = $mainmeta->{table};
    my $pkcol    = $mainmeta->{pkcol};

    my $where = $self->build_where($mainmeta);

    #- Main record

    my $pk_id = $self->table_record_insert($table, $pkcol, $maindata);

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

        my $where = $self->build_where($depmeta);

        # Update PK column with the new $pk_id
        foreach my $rec ( @{$depdata} ) {
            $rec->{$pkcol} = $pk_id;
        }

        $self->table_batch_insert($table, $depdata);
     }

    return $pk_id;
}

=head2 store_record_update

Updates a record.

The I<$record> parameter holds a complex AoH containing data colected
from the Screen controls (widgets) and the metadata needed to
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

sub store_record_update {
    my ( $self, $record) = @_;

    my $mainrec = $record->[0];              # main record first

    my $mainmeta = $mainrec->{metadata};
    my $maindata = $mainrec->{data};
    my $table    = $mainmeta->{table};
    my $pkcol    = $mainmeta->{pkcol};

    my $where = $self->build_where($mainmeta);

    #- Main record

    $self->table_record_update($table, $maindata, $where);

    #- Dependent records

    my $deprec = $record->[1];

    # One table at a time ...
    foreach my $tm ( keys %{$deprec} ) {
        my $depmeta = $deprec->{$tm}{metadata};
        my $depdata = $deprec->{$tm}{data};

        my $updstyle = $depmeta->{updstyle};
        my $table    = $depmeta->{table};
        my $pkcol    = $depmeta->{pkcol};
        my $fkcol    = $depmeta->{fkcol};
        my $where    = $self->build_where($depmeta);

        if ( $updstyle eq 'delete+add' ) {
            # Delete all articles and reinsert from TM ;)
            $self->table_batch_delete($table, $where);
            $self->table_batch_insert($table, $depdata);
        }
        else {
            # Update based on comparison between the database table
            # data and TableMatrix data
            $self->table_batch_update($depmeta, $depdata);
        }
     }

    return 1;
}

sub table_batch_update {
    my ($self, $depmeta, $depdata) = @_;

    my $compare_col = $depmeta->{fkcol};

    my $tb_data = $self->table_selectcol_as_array($depmeta);
    my $tm_data = $self->aoh_column_extract($depdata, $compare_col);

    my $lc = List::Compare->new($tm_data, $tb_data);

    my @to_update = $lc->get_intersection;
    my @to_insert = $lc->get_unique;
    my @to_delete = $lc->get_complement;

    print "To update: @to_update\n";
    print "To insert: @to_insert\n";
    print "To delete: @to_delete\n";

    $self->table_update_prepare(\@to_update, $depmeta, $depdata);
    $self->table_insert_prepare(\@to_insert, $depmeta, $depdata);
    $self->table_delete_prepare(\@to_delete, $depmeta);

    return;
}

sub table_update_prepare {
    my ( $self, $to_update, $depmeta, $depdata ) = @_;

    return unless scalar( @{$to_update} ) > 0;

    my $table = $depmeta->{table};
    my $pkcol = $depmeta->{pkcol};
    my $fkcol = $depmeta->{fkcol};
    my $pk_id = $depmeta->{where}{$pkcol}[0];

    foreach my $fk_id ( @{$to_update} ) {
        my $where = {
            $pkcol => $pk_id,
            $fkcol => $fk_id,
        };

        # Filter data; record is Aoh
        my $record = ( grep { $_->{$fkcol} == $fk_id } @{$depdata} )[0];

        ### delete $record->{$fkcol}; # remove FK col from update data;
                                      # does NOT work, it's like remmove
                                      # from the original datastructure?!

        $self->table_record_update( $table, $record, $where );
    }

    return;
}

sub table_insert_prepare {
    my ( $self, $to_insert, $depmeta, $depdata ) = @_;

    return unless scalar( @{$to_insert} ) > 0;

    my $table = $depmeta->{table};
    my $pkcol = $depmeta->{pkcol};
    my $fkcol = $depmeta->{fkcol};
    my $pk_id = $depmeta->{where}{$pkcol}[0];

    my @records;
    foreach my $fk_id ( @{$to_insert} ) {

        # Filter data; record is Aoh
        my $rec = ( grep { $_->{$fkcol} == $fk_id } @{$depdata} )[0];

        push @records, $rec;
    }

    $self->table_batch_insert($table, \@records);

    return;
}

sub table_delete_prepare {
    my ($self, $to_delete, $depmeta) = @_;

    return unless scalar( @{$to_delete} ) > 0;

    my $table = $depmeta->{table};
    my $pkcol = $depmeta->{pkcol};
    my $fkcol = $depmeta->{fkcol};
    my $pk_id = $depmeta->{where}{$pkcol}[0];

    my $where  = {
        $pkcol => $pk_id,
        $fkcol => { -in => $to_delete },
    };

    $self->table_batch_delete($table, $where);

    return;
}

sub aoh_column_extract {
    my ($self, $depdata, $column) = @_;

    my @dep_data;
    foreach my $rec (@$depdata) {
        my $data = $rec->{$column};
        push @dep_data, $data;
    }

    return \@dep_data;
}

sub table_selectcol_as_array {
    my ($self, $data_hr) = @_;

    my $table  = $data_hr->{table};
    my $pkcol  = $data_hr->{pkcol};
    my $fields = $data_hr->{fkcol};
    my $order  = $fields;

    my $where = $self->build_where($data_hr);

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );

    my $records;
    try {
       $records = $self->{_dbh}->selectcol_arrayref($stmt, undef, @bind);
    }
    catch {
        $self->_print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return $records;
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

1; # End of Tpda3::Model
