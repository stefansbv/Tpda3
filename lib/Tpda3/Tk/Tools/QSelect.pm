package Tpda3::Tk::Tools::QSelect;

use strict;
use warnings;

use Data::Dumper;
use utf8;

use Tk::widgets qw(DateEntry JComboBox Table Checkbox); #

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);
use File::Spec;

use Tpda3::Utils;
use Tpda3::Config;

=head1 NAME

Tpda3::Tk::App::Fpimm::QSelect screen.

=head1 VERSION

Version 0.50

=cut

our $VERSION = 0.50;

=head1 SYNOPSIS

    require Tpda3::App::Fpimm::QSelect;

    my $scr = Tpda3::App::Fpimm::QSelect->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb, $scrcfg ) = @_;

    $self->_init($scrcfg);

    my $rec_page  = $nb->page_widget('rec');
    my $det_page  = $nb->page_widget('det');
    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $locale_data  = $self->{cfg}->localize->{search};
    my $opt_contains = $locale_data->{opt_contains};
    my $opt_starts   = $locale_data->{opt_starts};
    my $opt_ends     = $locale_data->{opt_ends};

    # For DateEntry day names
    my @daynames = ();
    foreach ( 0 .. 6 ) {
        push @daynames, strftime( "%a", 0, 0, 0, 1, 1, 1, $_ );
    }

    #-  Frame TOP

    my $top = $rec_page->Frame()->pack(
        -side   => 'top',
        -fill   => 'both',
        -expand => 0,
    );

    #-- LabFrame top - left

    my $frm_tl = $top->LabFrame(
        -foreground => 'blue',
        -label      => 'Criterii',
        -labelside  => 'acrosstop'
        )->pack(
        -side   => 'left',
        -expand => 0,
        -fill   => 'both',
        );

    my $f1d = 90;              # distance from left

    $self->{columns} = $self->{scr}->main_table_columns;

    # Screen table columns metadata
    # TODO: sort field labels
    my (@fields, @labels);
    foreach my $field ( keys %{ $self->{columns} } ) {
        push @fields, $field;
        push @labels, $self->{columns}{$field}{label};
    }

    $self->{fields} = \@fields; # ??? !!!

    my $rows_no = scalar @fields;

    $self->{table} = $frm_tl->Table(
        -columns    => 5,
        -rows       => 6,
        -fixedrows  => 1,
        -scrollbars => 'oe',
        -relief     => 'raised',
        -background => 'white'
    );

    my $j = 0;
    my $i = 0;

    my @ents;

    foreach my $j ( 1 .. $rows_no ) {

        my $tmp_label = $self->{table}->Label(
            -text   => $i,
            -width  => 2,
            -relief => 'raised'
        );

        my $tmp_label1 = $self->{table}->Label(
            -text   => $labels[$i],
            -width  => 15,
            -relief => 'sunken',
            -anchor => 'w',
            -bg     => 'white',
        );

        my $var;
        my $tmp_cbx = $self->{table}->Checkbox(
            -variable => \$var,
            -relief => 'raised',
        );

        my $selected;
        my $searchopt = $self->{table}->JComboBox(
            -entrywidth   => 10,
            -textvariable => \$selected,
            -choices      => [
                { -name => $opt_contains, -value => 'C', -selected => 1 },
                { -name => $opt_starts,   -value => 'S', },
                { -name => $opt_ends,     -value => 'E', },
                { -name => '=',           -value => '==', },
                { -name => '>',           -value => '>', },
                { -name => '>=',          -value => '>=', },
                { -name => '<',           -value => '<', },
                { -name => '<=',          -value => '<=', },
            ],
        );

        my $tmp_label2 = $self->{table}->Entry(
            -width    => 20,
            -relief   => 'sunken',
            -bg       => 'white',
            -validate => 'key',

            #-validatecommand=>sub{ $_[1] =~m/\d\d/} ,
            #-invalidcommand=>sub{$mw->bell}
        );

        $self->{table}->put( $j, 1, $tmp_label );
        $self->{table}->put( $j, 2, $tmp_label1 );
        $self->{table}->put( $j, 3, $tmp_cbx );
        $self->{table}->put( $j, 4, $searchopt );
        $self->{table}->put( $j, 5, $tmp_label2 );

        push @ents, $tmp_label2;

        $i++;
    }

    $self->{table}->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    #-- LabFrame top - right

    my $frm_tr = $top->LabFrame(
        -foreground => 'blue',
        -label      => 'Select',
        -labelside  => 'acrosstop',
        )->pack(
        -side   => 'left',
        -expand => 1,
        -fill   => 'both',
        );

    my $addB = $frm_tr->Button(
        -text => 'Query',
        -command => sub { $self->make_query($scrcfg) },
    )->pack(-side => 'right', -padx => 12);

    #--- Details
    #-
    #

    #- Frame middle

    my $frm_m = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Records',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 1,
        -fill   => 'both',
    );

    #-- Toolbar
    $self->make_toolbar_for_table('tm1', $frm_m);

    #- TableMatrix

    my $header = $self->{scrcfg}->dep_table_header_info('tm1');
    my $xtvar = {};

    my $xtable = $frm_m->Scrolled(
        'TM',
        -rows           => 6,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -validate       => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -colstretchmode => 'unset',
        -bg             => 'white',
        -scrollbars     => 'osw',
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    $xtable->init($frm_m, $header);

    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {
        # id_rep   => [ undef, $eid_rep ],
        # repofile => [ undef, $erepofile ],
        # title    => [ undef, $etitle ],
        # descr    => [ undef, $tdescr ],
    };

    #- TableMatrix objects; just one for now :)

    $self->{tm_controls} = {
        rec => {
            tm1 => \$xtable,
        },
    };

    # Prepare screen configuration data for tables
    # foreach my $tm_ds ( keys %{ $self->{tm_controls}{rec} } ) {
    #     $validation->init_cfgdata( 'deptable', $tm_ds );
    # }

    return;
}

sub _init {
    my ($self, ) = @_;

    $self->{cfg} = Tpda3::Config->instance();
    $self->{scr} = Tpda3::Config::Screen->new('firme');

    return;
}

# # &defineOrder(@ents);

# sub defineOrder {
#     my $widget;
#     for ( my $i = 0; defined( $_[ $i + 1 ] ); $i++ ) {
#         $_[$i]->bind( '<Key-Return>', [ \&focus, $_[ $i + 1 ] ] );
#         $_[$i]->bind( '<Tab>',        [ \&focus, $_[ $i + 1 ] ] );
#     }

#     # Uncomment this line if you want to wrap around
#     $_[$#_]->bind( '<Key-Return>', [ \&focus, $_[0] ] );
#     $_[$#_]->bind( '<Tab>',        [ \&focus, $_[0] ] );

#     $_[0]->focus;
# }

# sub focus {
#     my ( $tk, $self ) = @_;
#     $self->focus;
# }

sub make_query {
    my ($self, $scrcfg) = @_;

    print " build query...\n";

    my $para = $self->build_query($scrcfg);

    print " query...\n";

    my ($ary_ref, $limit) = $self->{view}->tbl_find_query($para);

    print Dumper( $ary_ref );
    return;
}

sub build_query {
    my ($self, $scrcfg) = @_;

    $self->table_entry_read();

    my $params = {};

    # Add findtype info to screen data
    while ( my ( $field, $value ) = each( %{ $self->{_scrdata} } ) ) {
        chomp $value;
        my $findtype = $self->{columns}{$field}{findtype};

        # Create a where clause like this:
        #  field1 IS NOT NULL and field2 IS NULL
        # for entry values equal to '%' or '!'
        $findtype = q{notnull} if $value eq q{%};
        $findtype = q{isnull}  if $value eq q{!};

        $params->{where}{$field} = [ $value, $findtype ];
    }

    # Table data
    $params->{table} = $self->{scr}->main_table_view; # use view
    $params->{pkcol} = $self->{scr}->main_table_pkcol;

    return $params;
}

sub table_entry_read {
    my $self = shift;

    my $col_idx = 5;
    my $rows = $self->{table}->totalRows;

    for (my $row_idx = 1; $row_idx < $rows; $row_idx++) {

        my $row_pos = $row_idx - 1;
        my $field   = $self->{fields}->[$row_pos];
        my $widget  = $self->{table}->get($row_idx, $col_idx);
        my $value   = $widget->get;

        if ($value) {
            $self->{_scrdata}{$field} = $value;
        }
        else {
            # ctrl type is 'e'
            # Can't use numeric eq (==) here
            if ( $value =~ m{^0+$} ) {
                $self->{_scrdata}{$field} = $value;
            }
        }
    }

    return;
}

=head1 AUTHOR

Ștefan Suciu, C<< <stefbv70 la gmail punct com> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

Inspired by an answer on PerlMonks by zentara [id://969264].

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Ștefan Suciu

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::App::Fpimm::QSelect

