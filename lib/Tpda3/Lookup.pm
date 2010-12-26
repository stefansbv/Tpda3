package Tpda3::Lookup;

use strict;
use warnings;

use Data::Dumper;

use Tpda3::Tk::Dialog::Search;

sub new {
    my $type = shift;

    my $self = {};

    bless( $self, $type );

    $self->{dlgc} = Tpda3::Tk::Dialog::Search->new();

    return $self;
}

sub lookup {
    my ($self, $gui, $table, $filter) = @_;

    my $record = $self->{dlgc}->run_dialog( $gui, $table, $filter );

    return $record;
}

1;
