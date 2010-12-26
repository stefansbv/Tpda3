package Tpda3::Codings;

use strict;
use warnings;
use Carp;

use File::Spec::Functions;
use Try::Tiny;
use SQL::Abstract;

use Tpda3::Db;

=head1 NAME

Tpda3::Codings - The Codings

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

   use Tpda3::Codings;

   my $codes = Tpda3::Codings->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    $self->{_code} = {};

    $self->{_dbh} = Tpda3::Db->instance->dbh;

    bless( $self, $class );

    return $self;
}

=head2 get_coding_init

Return the data structure used to fill the list of choices (options)
of widgets like Tk::JComboBox and experimental for Tk::MatchingBE.

Initialize the datastructure from the database when needed.  The
procedure is: check key, if exists return a hash ref else query the
database.

Add the default value defined in configuration, if not exists in table.

=cut

sub get_coding_init {
    my ($self, $field, $para) = @_;

    if ( ! exists $self->{_code}{ $field } ) {
        # Query database table
        $self->{_code}{ $field } = $self->tbl_dict_query($para);
    }

    # Add the default
    if ( ! exists $self->{_code}{ $field }{ $para->{default} } ) {
        $self->{_code}{ $field }{ $para->{default} } = $para->{default};
    }

    return $self->{_code}{ $field };
}

=head2 get_coding

Return codes.

=cut

sub get_coding {
    my ($self, $field, $val) = @_;

    return $self->{_code}{$field}{$val};
}

=head2 tbl_dict_query

Query a table for codes.  Return key -> value, pairs used as the
'choices' of widgets like Tk::JComboBox.

There is a default table for codes named 'codificari' (named so, in
the first version of TPDA).

The 'codificari' table has the following structure:

   id_ord    INTEGER NOT NULL
   variabila VARCHAR(15)
   filtru    VARCHAR(5)
   cod       VARCHAR(5)
   denumire  VARCHAR(25) NOT NULL

The 'variabila' columns contains the name of the field, because this
is a table used for many different codings.  When this table is used,
a where clause is constructed to filter only the values coresponding
to 'variabila'.

There is another column named 'filtru' than can be used to restrict
the values listed when they depend on the value of another widget in
the current screen (not yet used!).

TODO: Change the field names

=cut

sub tbl_dict_query {
    my ($self, $para) = @_;

    my $where;
    if ($para->{table} eq 'codificari') {
        $where->{variabila} = $para->{field};
    }

    my $table  = $para->{table};
    my $fields = [ $para->{code}, $para->{name} ];

    my $sql = SQL::Abstract->new();

    my ( $stmt, @bind ) = $sql->select( $table, $fields, $where );

    # print "SQL : $stmt\n";
    # print "bind: @bind\n";

    my $rez;
    try {

        # Batch fetching
        my $sth = $self->{_dbh}->prepare($stmt);
        if (@bind) {
            $sth->execute(@bind);
        }
        else {
            $sth->execute();
        }

        while ( my $hashref = $sth->fetchrow_hashref('NAME_lc') ) {
            my $key = $hashref->{ $para->{code} };
            my $val = $hashref->{ $para->{name} };
            $rez->{$key} = $val;
        }
    }
    catch {
        print("Database error!") ;
        croak("Transaction aborted: $_");
    };

    return $rez;
}

1;
