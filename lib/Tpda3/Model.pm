package Tpda3::Model;

# ABSTRACT: The Model

use 5.010;
use strict;
use warnings;

use Data::Compare;
use List::Compare;
use Log::Log4perl qw(get_logger :levels);
use Regexp::Common;
use SQL::Abstract;
use Try::Tiny;

use Tpda3::Exceptions;
use Tpda3::Config;
use Tpda3::Codings;
use Tpda3::Observable;
use Tpda3::Db;
use Tpda3::Utils;

use Data::Dump;

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

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub verbose {
    my $self = shift;
    return $self->cfg->verbose;
}

sub debug {
    my $self = shift;
    return $self->cfg->debug;
}

sub _log {
    my $self = shift;
    return $self->{_log};
}

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

sub dbh {
    my $self = shift;
    if ( Tpda3::Db->has_instance ) {
        my $db = Tpda3::Db->instance;
        return $db->dbh if $self->is_connected;
    }
    Exception::Db::Connect->throw(
        usermsg => 'Please restart and login',
        logmsg  => 'error#Not connected',
    );
    return;
}

sub dbc {
    my $self = shift;
    my $db = Tpda3::Db->instance;
    return $db->dbc;
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
    $self->debug_print_sql('query_records_count', $stmt, \@bind);

    my $record_count;
    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
        ($record_count) = $sth->fetchrow_array();
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
    $self->debug_print_sql('query_records_find', $stmt, \@bind);

    my $search_limit = $self->cfg->application->{limits}{search} || 100;
    my $args = { MaxRows => $search_limit };    # limit search result
    my $ary_ref;
    try {
        $ary_ref = $self->dbh->selectall_arrayref( $stmt, $args, @bind );
    }
    catch {
        $self->db_exception($_, 'Find failed');
    };

    return ($ary_ref, $search_limit);
}

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
    $self->debug_print_sql('query_filter_find', $stmt, \@bind);

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

sub query_record {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $cols  = $opts->{columns};
    my $where = $opts->{where};

    my $sql = SQL::Abstract->new( special_ops => Tpda3::Utils->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where );
    $self->debug_print_sql('query_record', $stmt, \@bind);

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
    $self->debug_print_sql('table_batch_query', $stmt, \@bind);

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
    $self->debug_print_sql('query_dictionary', $stmt, \@bind);

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
    $self->debug_print_sql('tbl_dict_query', $stmt, \@bind);

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
    $self->debug_print_sql('tbl_lookup_query', $stmt, \@bind);

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

sub table_record_insert {
    my ( $self, $table, $pkcol, $record ) = @_;

    my $sql = SQL::Abstract->new();

    my $has_feature = $self->dbc->has_feature_returning();
    my $attrib = $has_feature ? { returning => $pkcol } : {};

    my ( $stmt, @bind ) = $sql->insert( $table, $record, $attrib );
    $self->debug_print_sql('table_record_insert', $stmt, \@bind);

    my $pk_id;
    if ( exists $record->{$pkcol} ) {
        $pk_id = $record->{$pkcol};
    }

    try {
        my $dbh = $self->dbh;

        my $sth = $dbh->prepare($stmt) or die $dbh->errstr;

        $sth->execute(@bind) or die $dbh->errstr;

        unless (defined $pk_id) {
            $pk_id = $has_feature
            ? $sth->fetch()->[0]
            : $self->dbh->last_insert_id(undef, undef, $table, undef);
        }
    }
    catch {
        $self->db_exception($_, 'Insert failed');
    };

    return $pk_id;
}

sub table_record_update {
    my ( $self, $table, $record, $where ) = @_;

    my $sql = SQL::Abstract->new();
    my ( $stmt, @bind ) = $sql->update( $table, $record, $where );
    $self->debug_print_sql('table_record_update', $stmt, \@bind);

    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->db_exception($_, 'Update failed');
    };

    return;
}

sub table_record_select {
    my ( $self, $table, $where ) = @_;

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, undef, $where );
    $self->debug_print_sql('table_record_select', $stmt, \@bind);

    my $hash_ref;
    try {
        $hash_ref = $self->dbh->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->db_exception($_, 'Select failed');
    };

    return $hash_ref;
}

sub table_batch_insert {
    my ( $self, $table, $records ) = @_;
    my $sql = SQL::Abstract->new();

    # AoH refs
    foreach my $record ( @{$records} ) {
        my ( $stmt, @bind ) = $sql->insert( $table, $record );
        $self->debug_print_sql('table_batch_insert', $stmt, \@bind);
        try {
            my $sth = $self->dbh->prepare($stmt);
            $sth->execute(@bind);
        }
        catch {
            $self->db_exception($_, 'Batch insert failed');
        };
    }
    return;
}

sub table_record_delete {
    my ( $self, $table, $where ) = @_;

    my $sql = SQL::Abstract->new();

    # Safety net..., is enough ???
    die "Empty TABLE name in DELETE command!" unless $table;
    die "Empty SQL WHERE in DELETE command!"  unless ( %{$where} );

    $self->_log->debug("Deleting from $table: ");
    # $self->_log->debug( sub { Dumper($where) } );

    my ( $stmt, @bind ) = $sql->delete( $table, $where );

    try {
        my $sth = $self->dbh->prepare($stmt);
        $sth->execute(@bind);
    }
    catch {
        $self->db_exception($_, 'Delete failed');
    };

    return;
}

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

sub prepare_record_update {
    my ( $self, $record ) = @_;

    #- Main record

    my $mainmeta = $record->[0]{metadata};
    my $maindata = $record->[0]{data};

    my $table = $mainmeta->{table};
    my $where = $mainmeta->{where};

    if ( %{$maindata} ) {
        $self->table_record_update( $table, $maindata, $where );
    }
    else {
        say "No main data to update for '$table'" if $self->verbose;
    }

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
        elsif ( $updstyle eq 'update' ) {

            # Update based on comparison between the database table
            # data and TableMatrix data
            $self->table_batch_update( $depmeta, $depdata );
        }
        else {
            die "TM table update style '$updstyle' not implemented!\n";
        }
    }

    return;
}

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

sub table_batch_update {
    my ( $self, $depmeta, $depdata ) = @_;

    my $compare_col = $depmeta->{tmpkcol};

    my $tb_data = $self->table_selectcol_as_array($depmeta);
    my $tm_data = $self->aoh_column_extract( $depdata, $compare_col );

    my $lc = List::Compare->new( $tm_data, $tb_data );
    my @to_update = $lc->get_intersection;
    my @to_insert = $lc->get_unique;
    my @to_delete = $lc->get_complement;
    my $to_update
        = $self->table_update_compare( \@to_update, $depmeta, $depdata );

    if ( $self->debug ) {
        say "To update: @{$to_update}" if ref $to_update;
        say "To insert: @to_insert";
        say "To delete: @to_delete";
    }

    $self->table_update_prepare( $to_update, $depmeta, $depdata );
    $self->table_insert_prepare( \@to_insert, $depmeta, $depdata );
    $self->table_delete_prepare( \@to_delete, $depmeta );

    return;
}

sub table_update_compare {
    my ( $self, $to_update, $depmeta, $depdata ) = @_;

    return unless scalar( @{$to_update} ) > 0;

    my $table   = $depmeta->{table};
    my $fkcol   = $depmeta->{fkcol};
    my $tmpkcol = $depmeta->{tmpkcol};
    my $where   = $depmeta->{where};

    my @toupdate;
    foreach my $id ( @{$to_update} ) {
        $where->{$tmpkcol} = $id;

        # Filter data; record is Aoh
        my $record = ( grep { $_->{$tmpkcol} == $id } @{$depdata} )[0];
        my $oldrec = $self->table_record_select( $table, $where );
        my $dc = Data::Compare->new( $oldrec, $record );
        if (!$dc->Cmp) {
            push @toupdate, $id;
            say" add $id to Update" if $self->verbose;
        }
    }
    return \@toupdate;
}

sub table_update_prepare {
    my ( $self, $to_update, $depmeta, $depdata ) = @_;

    return unless ref $to_update;
    return unless scalar( @{$to_update} ) > 0;

    my $table   = $depmeta->{table};
    my $fkcol   = $depmeta->{fkcol};
    my $tmpkcol = $depmeta->{tmpkcol};
    my $where   = $depmeta->{where};

    if ($self->debug) {
        say '*** table_update_prepare:';
        say " table = $table";
        say " fkcol = $fkcol";
        say " where (orig):";
        dd $where;
    }

    foreach my $id ( @{$to_update} ) {
        $where->{$tmpkcol} = $id;

        # Filter data; record is Aoh
        my $record = ( grep { $_->{$tmpkcol} == $id } @{$depdata} )[0];

        ### delete $record->{$fkcol}; # remove FK col from update data;
        # does NOT work, it's like remove
        # from the original datastructure?!

        if ($self->debug) {
            say "update in $table:";
            say "*** record ***\n";
            dd $record;
            say " where:\n";
            dd $where;
        }
        $self->table_record_update( $table, $record, $where );
    }

    return;
}

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
    if ($self->debug) {
        say "insert in $table:";
        dd @records;
    }

    $self->table_batch_insert( $table, \@records );
    return;
}

sub table_delete_prepare {
    my ( $self, $to_delete, $depmeta ) = @_;

    return unless scalar( @{$to_delete} ) > 0;

    my $table = $depmeta->{table};
    my $where = $depmeta->{where};

    $self->table_record_delete( $table, $where );

    return;
}

sub aoh_column_extract {
    my ( $self, $depdata, $column ) = @_;
    my @dep_data;
    foreach my $rec ( @{$depdata} ) {
        my $data = $rec->{$column};
        push @dep_data, $data;
    }
    return \@dep_data;
}

sub table_selectcol_as_array {
    my ( $self, $opts ) = @_;

    my $table  = $opts->{table};
    my $fields = $opts->{tmpkcol};
    my $where  = $opts->{where};
    my $order  = $fields;

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where, $order );

    my $records;
    try {
        $records = $self->dbh->selectcol_arrayref( $stmt, undef, @bind );
    }
    catch {
        $self->db_exception($_, 'Select failed');
    };

    return $records;
}

sub record_compare {
    my ( $self, $witness, $record ) = @_;
    my $dc = Data::Compare->new( $witness, $record );
    if ( $self->debug ) {
        say 'Structures of $witness and $record are ',
            $dc->Cmp ? "" : "not ", "identical.";
    }
    return !$dc->Cmp;
}

sub user_message {
    my ($self, $error) = @_;

    $error =~ s{[\n\r]}{ }gmix;
    my $user_message = $self->dbc->parse_error($error);
    $user_message =~ s{"\."}{\.}gmix;        # "d"."t" ->  "d.t"

    #$self->_print($user_message);

    return $user_message;
}

sub db_exception {
    my ( $self, $exc, $context ) = @_;

    say "Exception: '$exc'";
    say "Context  : '$context'";

    if ( my $e = Exception::Base->catch($exc) ) {
        say "Catched!";

        if ( $e->isa('Exception::Db::Connect') ) {
            my $logmsg  = $e->logmsg;
            my $usermsg = $e->usermsg;
            say "ExceptionConnect: $usermsg :: $logmsg";
            $e->throw;    # rethrow the exception
        }
        elsif ( $e->isa('Exception::Db::SQL') ) {
            my $logmsg  = $e->logmsg;
            my $usermsg = $e->usermsg;
            say "ExceptionSQL: $usermsg :: $logmsg";
            $e->throw;    # rethrow the exception
        }
        else {

            # Throw other exception
            say "ExceptioOther new";
            my $message = $self->user_message($exc);
            say "Message:   '$message'";
            Exception::Db::SQL->throw(
                logmsg  => $message,
                usermsg => $context,
            );
        }
    }
    else {
        say "New thrown (model)";
        Exception::Db::SQL->throw(
            logmsg  => "error#$exc",
            usermsg => $context,
        );
    }

    return;
}

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

sub table_columns {
    my ($self, $table_name) = @_;

    my $table_info = $self->dbc->table_info_short($table_name);
    my @fields;
    foreach my $k ( sort { $a <=> $b } keys %{$table_info} ) {
        my $name = $table_info->{$k}{name};
        my $info = $table_info->{$k};
        push @fields, $name;
    }

    return \@fields;
}

sub table_keys {
    my ($self, $table_name) = @_;
    return $self->dbc->table_keys($table_name);
}

sub get_template_datasources {
    my ($self, $id_tt) = @_;

    # Get datasources
    my $args = {};
    $args->{table}    = 'templates';
    $args->{colslist} = [qw{table_name view_name common_data}];
    $args->{where}    = { id_tt => $id_tt };
    $args->{order}    = 'id_tt';
    my $datasources = $self->table_batch_query($args);

    return $datasources->[0];
}

sub other_data {
    my ($self, $model_name) = @_;

    # Specific data for the current template
    my $args = {};
    $args->{table}    = 'templates';
    $args->{colslist} = [qw{id_tt}];
    $args->{where}    = { tt_file => $model_name };
    my $tt_aref       = $self->table_batch_query($args);
    my $id_tt         = $tt_aref->[0]{id_tt};

    # Common data for all templates
    my $tt_datasources = $self->get_template_datasources($id_tt);
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
        my $common_aref = $self->table_batch_query($args);
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

sub update_or_insert {
    my ($self, $table, $columns, $matching, $records) = @_;

    my $cols_list  = join ",", @{$columns};
    my $match_list = join ",", @{$matching};
    my $sql = qq{UPDATE OR INSERT INTO $table
                            ($cols_list)
                     VALUES (?, ?, ?, ?)
                     MATCHING ($match_list)
    };

    my $sth;
    try {
        $sth = $self->dbh->prepare($sql);
    }
    catch {
        $self->db_exception( $_, "'update_or_insert' prepare failed" );
    };

    foreach my $rec ( @{$records} ) {
        my @bind = @$rec{ @{$columns} };     # hash slice
        try {
            $sth->execute(@bind);
        }
        catch {
            $self->db_exception( $_, "'update_or_insert' failed" );
        };
    }

    return;
}

sub debug_print_sql {
    my ( $self, $meth, $stmt, $bind ) = @_;
    die "debug_print_sql: wrong params!"
        unless $meth and $stmt and ref $bind;
    my $bind_params_no = scalar @{$bind};
    my $params = 'none';
    if ( $bind_params_no > 0 ) {
        my @para = map { defined $_ ? $_ : 'undef' } @{$bind};
        $params  = scalar @para > 0 ? join( ', ', @para ) : 'none';
    }
    if ( $self->debug ) {
        say "---";
        say "$meth:";
        say "  SQL=$stmt";
        say "  Params=($params)";
        say "---";
    }
    return;
}

1;

=head1 SYNOPSIS

    use Tpda3::Model;

    my $model = Tpda3::Model->new();

=head2 new

Constructor method.

=head2 cfg

Return configuration instance object.

=head2 _log

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

Count records in table.  Here we need the contents of the screen to
build an sql where clause and also the column names from the
I<columns> configuration.

=head2 query_filter_find

Same as C<query_records_find> but returns an AoH suitable for TM fill.

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

=head2 table_update_prepare

Prepare data for batch update.

=head2 table_insert_prepare

Prepare data for batch insert.

=head2 table_delete_prepare

Prepare data for batch delete.

=head2 aoh_column_extract

Extract only a column from an AoH data structure.

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
