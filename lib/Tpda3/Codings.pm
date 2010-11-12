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

    my $model = Tpda3::Codings->new();

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

sub get_coding_init {
    my ($self, $field, $para) = @_;

    # check key
    # if exists return hash_ref
    # else query database

    my $cod_ref;

    if ( ! exists $self->{_code}{ $field } ) {
        # Query database table
        $self->{_code}{ $field } = $self->tbl_dict_query($para);
    }

    # Add the default value defined in config xml if not exists in table
    if ( ! exists $self->{_code}{ $field }{ $para->{default} } ) {
        $self->{_code}{ $field }{ $para->{default} } = $para->{default};
    }

    return $self->{_code}{ $field };
}

sub get_coding {
    my ($self, $field, $val) = @_;

    return $self->{_code}{$field}{$val};
}

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
