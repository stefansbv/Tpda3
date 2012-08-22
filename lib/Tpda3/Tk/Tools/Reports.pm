package Tpda3::Tk::Tools::Reports;

use strict;
use warnings;
use utf8;

use Tk::widgets qw(); # DateEntry JComboBox

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);
use File::Spec;

use Tpda3::Utils;

=head1 NAME

Tpda3::Tk::Tools::Reports screen.

=head1 VERSION

Version 0.57

=cut

our $VERSION = 0.57;

=head1 SYNOPSIS

    require Tpda3::Tools::Reports;

    my $scr = Tpda3::Tools::Reports->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb, $scr_cfg ) = @_;

    my $rec_page  = $nb->page_widget('rec');
    my $det_page  = $nb->page_widget('det');
    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $validation = Tpda3::Tk::Validation->new($scr_cfg);

    # For DateEntry day names
    my @daynames = ();
    foreach ( 0 .. 6 ) {
        push @daynames, strftime( "%a", 0, 0, 0, 1, 1, 1, $_ );
    }

    #- Top Frame

    my $frm_top = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Report',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 0,
        -fill   => 'x',
    );

    my $f1d = 110;              # distance from left

    #- id_rep (id_rep)

    my $lid_rep = $frm_top->Label( -text => 'Id. report', );
    $lid_rep->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );

    my $eid_rep = $frm_top->MEntry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eid_rep->form(
        -top  => [ '&', $lid_rep, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- repofile (repofile)

    my $lrepofile = $frm_top->Label( -text => 'File', );
    $lrepofile->form(
        -top     => [ $lid_rep, 8 ],
        -left    => [ %0,       0 ],
        -padleft => 5,
    );

    my $erepofile = $frm_top->MEntry(
        -width              => 50,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $erepofile->form(
        -top  => [ '&', $lrepofile, 0 ],
        -left => [ %0,  $f1d ],
    );
    $erepofile->bind(
        '<KeyPress-Return>' => sub {
            $self->report_file();
        }
    );

    #- title (title)

    my $ltitle = $frm_top->Label( -text => 'Title', );
    $ltitle->form(
        -top     => [ $lrepofile, 8 ],
        -left    => [ %0,         0 ],
        -padleft => 5,
    );

    my $etitle = $frm_top->MEntry(
        -width              => 50,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $etitle->form(
        -top       => [ '&', $ltitle, 0 ],
        -left      => [ %0,  $f1d ],
        -padbottom => 5,
    );

    my $my_font = $eid_rep->cget('-font');    # font

    #-- Frame bottom

    my $txt_frame = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    )->pack(
        -expand => 0,
        -fill   => 'x',
    );

    my $tdescr =  $txt_frame->Scrolled(
        'Text',
        -width      => 10,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'e',
        -font       => $my_font
    )->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    #--- Details
    #-
    #

    #- Frame middle

    my $frm_m = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Parameters',
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
        id_rep   => [ undef, $eid_rep ],
        repofile => [ undef, $erepofile ],
        title    => [ undef, $etitle ],
        descr    => [ undef, $tdescr ],
    };

    #- TableMatrix objects; just one for now :)

    $self->{tm_controls} = {
        rec => {
            tm1 => \$xtable,
        },
    };

    # Prepare screen configuration data for tables
    foreach my $tm_ds ( keys %{ $self->{tm_controls}{rec} } ) {
        $validation->init_cfgdata( 'deptable', $tm_ds );
    }

    return;
}

sub report_file {
    my $self = shift;

    my $types = [ [ 'Fisier raport', '.rep' ], [ 'All Files', '*', ], ];

    # my $rep_path =  $conf->{CONFIG}{misc}{rep_path};
    # $rep_path = File::Spec->canonpath($rep_path);

    my $path = $self->{view}->getOpenFile(
        -filetypes  => $types,
        -initialdir => '.',
    );

    return unless $path;

    my ( $vol, $dir, $file ) = File::Spec->splitpath($path);

    eval {
        my $state = $self->{controls}{repofile}[1]->cget(-state);
        $self->{controls}{repofile}[1]->configure( -state => 'normal' );
        $self->{controls}{repofile}[1]->delete( 0, 'end' );
        $self->{controls}{repofile}[1]->insert( 0, $file );
        $self->{controls}{repofile}[1]->xview('end');
        $self->{controls}{repofile}[1]->configure( -state => $state );
    };

    return;
}

=head1 AUTHOR

Ștefan Suciu, C<< <stefbv70 la gmail punct com> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Ștefan Suciu

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Tools::Reports
