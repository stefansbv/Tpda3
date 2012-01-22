package Tpda3::Tree;

use strict;
use warnings;
use utf8;

use Data::Dumper;

use Tree::DAG_Node;
use base qw(Tree::DAG_Node);

my $expvar = {};                            # TODO: find better way...
our $colslist = [];

sub new {
    my ( $class, $options ) = @_;

    my $self = bless $class->SUPER::new();

    $self->attributes($options);

    return $self;
}

sub set_header {
    my ($self, $args) = @_;

    $colslist = $args;

    return;
}

sub set_attributes {
    my ( $self, $field, $val ) = @_;

    $self->attributes->{$field} = $val if $val;

    return;
}

sub get_attributes {
    my ( $self, $field ) = @_;

    return $self->attributes->{$field};
}

sub by_name {
    my ( $self, $name ) = @_;

    my @found = ();
    my $retvalue = wantarray ? 1 : 0;
    $self->walk_down(
        {   callback => sub {
                if ( $_[0]->name eq $name ) {
                    push @found, $_[0];
                    return $retvalue;
                }
                1;
                }
        }
    );
    return wantarray ? @found : @found ? $found[0] : undef;
}

sub fill_tm {
    my ( $self, $name ) = @_;

    $self->walk_down( { callback => \&process_node, _depth => 0 } );

    return $expvar;
}

sub process_node {
    my ($self, $options) = @_;

    return 1 if ! defined $self->name();

    my $depth = $options->{_depth};
    my $nodeidx = $self->get_attributes('idx');
    print ' ' x ($depth * 3);
    print $nodeidx ? $nodeidx : '', ' ', $self->name, "\n";

    if ($depth == 0) {
        # skip
    }
    elsif ($depth == 1) {
        # skip
    }
    else {
        $self->add_detail_data();
    }

    return 1;
}

sub add_detail_data {
    my ($self) = @_;

    my @vdata = (undef);                     # start with 1 element
    foreach my $field ( @{$colslist} ) {
        push @vdata, $self->get_attributes($field);
    }

    # Reversed list of ancestors indexes
    my @idxs = grep { defined $_ }
        map { $_->get_attributes('nr_crt') } $self->ancestors;

    my $depth_factor = scalar @idxs;
    my $mrow         = pop @idxs;

  SWITCH: {
        $depth_factor == 1 && do {
            $expvar->{$mrow}{tag} = 'detail';
            push @{ $expvar->{$mrow}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 2 && do {
            my $row1 = pop @idxs;
            $expvar->{$mrow}{expandData}{$row1}{tag} = 'detail2';
            push @{ $expvar->{$mrow}{expandData}{$row1}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 3 && do {
            my $row1 = pop @idxs;
            my $row2 = pop @idxs;
            $expvar->{$mrow}{expandData}{$row1}{expandData}{$row2}{tag}
                = 'detail3';
            push @{ $expvar->{$mrow}{expandData}{$row1}{expandData}{$row2}
                    {data} }, \@vdata;
            last SWITCH;
        };
        print "\$depth_factor is not equal with 1 or 2 or 3\n";
    }

    # print Dumper( \@vdata);
    return;
}

sub clear_totals {
    $_[0]->walk_down(
        {   callback => sub {
                my $self = shift;
                if ( $self->daughters ) {
                    $self->set_attributes('fact_val', 0);
                }
            }
        }
    );
}

sub sum_up {
    $_[0]->walk_down(
        {   callbackback => sub {
                my $node = shift;
                return 1 unless $node->mother;
                $node->mother->attributes->{fact_val}
                    += $node->attributes->{fact_val};
                }
        }
    );
}

sub print_wealth {
    $_[0]->walk_down(
        {   callback => sub {
                my $node = shift;
                printf "%s%.15s\t facturat: %.2f\n",
                    "  " x $_[0]->{_depth},
                    $node->name, $node->get_attributes('fact_val');;
            },
            _depth => 0,
        }
    );
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

1;    # End of Tpda3::Tree
