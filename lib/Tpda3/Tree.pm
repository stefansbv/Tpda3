package Tpda3::Tree;

use strict;
use warnings;
use utf8;

use Tree::DAG_Node;
use base qw(Tree::DAG_Node);

my $maindata = [];                          # TODO: find better way...
my $expdata  = {};
my $colslist = [];

=head2 new

Constructor.

=cut

sub new {
    my ( $class, $options ) = @_;

    my $self = bless $class->SUPER::new();

    $self->attributes($options);

    $expdata = {};

    return $self;
}

=head2 set_header

Initialize header data.

TODO: This should be integrated in the I<new> method (when I learn how).

=cut

sub set_header {
    my ($self, $args) = @_;

    $colslist = $args;

    return;
}

=head2 set_attributes

Set node attributes.

=cut

sub set_attributes {
    my ( $self, $field, $val ) = @_;

    $self->attributes->{$field} = qq{$val};

    return;
}

=head2 get_attributes

Get node attributes.

=cut

sub get_attributes {
    my ( $self, $field ) = @_;

    return $self->attributes->{$field};
}

=head2 by_name

Search node by name.

=cut

sub by_name {
    my ( $self, $name ) = @_;

    my @found = ();
    my $retvalue = wantarray ? 1 : 0;
    $self->walk_down({
        callback => sub {
            my $node = shift;
            if ( $node->name eq $name ) {
                push @found, $node;
                return $retvalue;
            }
            1;
        }
    });

    return wantarray ? @found : @found ? $found[0] : undef;
}

=head2 get_tree_data

Return tree data.

=cut

sub get_tree_data {
    my ( $self, $name ) = @_;

    $self->walk_down( { callback => \&process_node, _depth => 0 } );

    return ($maindata, $expdata);
}

=head2 process_node

Gather attributes data from each node.

=cut

sub process_node {
    my ($self, $options) = @_;

    return 1 if ! defined $self->name();

    my $depth = $options->{_depth};
    my $nodeidx = $self->get_attributes('idx');
    # print ' ' x ($depth * 3);
    # print $nodeidx ? $nodeidx : '', ' ', $self->name, "\n";

    if ($depth == 1) {
        $self->add_main_data();
    }
    elsif ($depth >= 2) {
        $self->add_detail_data();
    }
    else {
        # Ignore
    }

    return 1;
}

=head2 add_main_data

Return data from depth level 1 from the tree attributes.

=cut

sub add_main_data {
    my ($self) = @_;

    my $rec = {};
    foreach my $field ( @{$colslist} ) {
        $rec->{$field} = $self->get_attributes($field);
    }

    my $mrow = $self->get_attributes('nr_crt');

    push @{$maindata}, $rec;

    return;
}

=head2 add_detail_data

Return data from depth level > 1 from the tree attributes.

Builds expandData variable for the TMSHR widget.

Limited to 3 levels deep.

TODO: Replace the switch with some kind of a loop for arbitrary depth
level.

=cut

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
            $expdata->{$mrow}{tag} = 'detail';
            push @{ $expdata->{$mrow}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 2 && do {
            my $row1 = pop @idxs;
            $expdata->{$mrow}{expandData}{$row1}{tag} = 'detail2';
            push @{ $expdata->{$mrow}{expandData}{$row1}{data} }, \@vdata;
            last SWITCH;
        };
        $depth_factor == 3 && do {
            my $row1 = pop @idxs;
            my $row2 = pop @idxs;
            $expdata->{$mrow}{expandData}{$row1}{expandData}{$row2}{tag}
                = 'detail3';
            push @{ $expdata->{$mrow}{expandData}{$row1}{expandData}{$row2}
                    {data} }, \@vdata;
            last SWITCH;
        };
        print "\$depth_factor is not equal with 1 or 2 or 3\n";
    }

    return;
}

=head2 clear_totals

Clear totals.  The fields are those configured with I<=sumup> value in
the I<datasource> section.

=cut

sub clear_totals {
    my ( $self, $fields, $places ) = @_;

    $self->walk_down({
        callback => sub {
            my ($node, $options) = @_;
            if ( $node->daughters ) {
                foreach my $field ( @{$fields} ) {
                    $node->set_attributes( $field, 0 );
                }
            }
            1;
        }
    });

    return;
}

=head2 format_numbers

Traverse once again the tree and format the columns configured with
I<=sumup> value in the I<datasource> section.

Have to do the formatting after sum, because the format is not
preserved when summing up.

=cut

sub format_numbers {
    my ( $self, $fields, $places ) = @_;

    $self->walk_down({
        callback => sub {
            my ($node, $options) = @_;
                foreach my $field ( @{$fields} ) {
                    my $cell_value = $node->get_attributes($field);
                    $node->set_attributes( $field,
                        sprintf( "%.${places}f", $cell_value ) );
                }
            1;
        }
    });

    return;
}

=head2 sum_up

Calculate sum.  The fields are those configured with I<=sumup> value
in the I<datasource> section.

=cut

sub sum_up {
    my ( $self, $fields, $places ) = @_;

    $self->walk_down({
        callbackback => sub {
            my ($node, $options) = @_;
            return 1 unless $node->mother;
            foreach my $field ( @{$fields} ) {
                $node->mother->attributes->{$field}
                    += $node->attributes->{$field};
            }
            1;
        }
    });

    return;
}

=head2 print_wealth

Debug method.

=cut

sub print_wealth {
    my ( $self, $field ) = @_;

    $self->walk_down({
        callback => sub {
            my ($node, $options) = @_;
            printf "%s%.15s\t facturat: %s\n",
                "  " x $options->{_depth},
                    $node->name, $node->get_attributes($field);
        },
        _depth => 0,
    });

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Heavily inspired from the I<Introduction to Tree::DAG_Node> article by
gmax, from: http://www.perlmonks.org/?node_id=153259

Thank You!

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tree
