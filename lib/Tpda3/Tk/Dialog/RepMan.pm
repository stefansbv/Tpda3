package Tpda3::Tk::Dialog::RepMan;

use strict;
use warnings;

use Data::Dumper;
use utf8;

use Tk;
use IO::File;

use Tpda3::Config;
use Tpda3::Tk::TB;
use Tpda3::Tk::TM;

=head1 NAME

Tpda3::Tk::Dialog::RepMan - Dialog for preview and print RepMan reports.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Help;

    my $fd = Tpda3::Tk::Dialog::Help->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {
        tb4 => {},    # ToolBar
        tlw => {},    # TopLevel
        _tm => undef, # TableMatrix
        _rl => undef, # report titles list
        _rd => undef, # report details
    };

    return bless( $self, $class );
}

=head2 search_dialog

Define and show search dialog.

=cut

sub repman_dialog {
    my ( $self, $view ) = @_;

    $self->{tlw} = $view->Toplevel();
    $self->{tlw}->title('Preview and print reports');

    my $f1d = 110;              # distance from left

    #- Toolbar frame

    my $tbf0 = $self->{tlw}->Frame();
    $tbf0->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'x',
    );

    my $bg = $self->{tlw}->cget('-background');

    # Frame for main toolbar
    my $tbf1 = $tbf0->Frame();
    $tbf1->pack( -side => 'left', -anchor => 'w' );

    #-- ToolBar

    $self->{tb4} = $tbf1->TB();

    my $attribs = {
        'tb4pr' => {
            'tooltip' => 'Preview and print report',
            'icon'    => 'fileprint16',
            'sep'     => 'none',
            'help'    => 'Preview and print report',
            'method'  => sub { $self->preview_report(); },
            'type'    => '_item_normal',
            'id'      => '20101',
        },
        'tb4qt' => {
            'tooltip' => 'Close',
            'icon'    => 'actexit16',
            'sep'     => 'after',
            'help'    => 'Quit',
            'method'  => sub { $self->dlg_exit; },
            'type'    => '_item_normal',
            'id'      => '20102',
        }
    };

    my $toolbars = [ 'tb4pr', 'tb4qt', ];

    $self->{tb4}->make_toolbar_buttons( $toolbars, $attribs );

    #-- end ToolBar

    #-- StatusBar

    my $sb = $self->{tlw}->StatusBar();

    my ($label_l, $label_d, $label_r);

    $sb->addLabel(
        -relief       => 'flat',
        -textvariable => \$label_l,
    );

    $sb->addLabel(
        -width        => '10',
        -anchor       => 'center',
        -textvariable => \$label_d,
        -side         => 'right'
    );

    $sb->addLabel(
        -width        => '10',
        -anchor       => 'center',
        -textvariable => \$label_r,
        -side         => 'right',
        -foreground   => 'blue'
    );

    #-- end StatusBar

    #- Main frame

    my $mf = $self->{'tlw'}->Frame();
    $mf->pack(
        -side   => 'top',
        -anchor => 'n',
        -expand => 0,
        -fill   => 'both',
    );

    #-  Frame top - TM

    my $frm_top = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'List',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 0,
        -fill   => 'x',
    );

    my $xtvar1 = {};
    $self->{_tm} = $frm_top->Scrolled(
        'TM',
        -rows           => 6,
        -cols           => 3,
        -width          => -1,
        -height         => 6,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar1,
        -selectmode     => 'single',
        -selecttype     => 'row',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -colstretchmode => 'unset',
        -bg             => 'white',
        -scrollbars     => 'osw',
    );
    $self->{_tm}->pack(
        -expand => 1,
        -fill => 'both',
    );

    #-- Bindings for selection handling

    # Clean up if mouse leaves the widget
    $self->{_tm}->bind(
        '<FocusOut>',
        sub {
            my $w = shift;
            $w->selectionClear('all');
        }
    );

    # Highlight the cell under the mouse
    $self->{_tm}->bind(
        '<Motion>',
        sub {
            my $w  = shift;
            my $Ev = $w->XEvent;
            if ( $w->selectionIncludes( '@' . $Ev->x . "," . $Ev->y ) ) {
                Tk->break;
            }
            $w->selectionClear('all');
            $w->selectionSet( '@' . $Ev->x . "," . $Ev->y );
            Tk->break;
        }
    );

    # MouseButton 1 toggles the value of the cell
    $self->{_tm}->bind(
        '<1>',
        sub {
            my $w = shift;
            $w->focus;
            my ($rc) = @{ $w->curselection };
            my ( $r, $c ) = split( ',', $rc );
            $self->{_tm}->set_selected($r);
            $self->load_report_details($view);
        }
    );

    #-  Frame middle - Entries

    my $frm_middle = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Details',
        -labelside  => 'acrosstop'
    );
    $frm_middle->pack(
        -expand => 0,
        -fill   => 'x',
        -ipadx  => 3,
        -ipady  => 3,
    );

    #-- ID report (id_rep)

    my $lid_rep = $frm_middle->Label(
        -text => 'ID report',
    );
    $lid_rep->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );
    #--
    my $eid_rep = $frm_middle->Entry(
        -width => 12,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $eid_rep->form(
        -top  => [ %0, 0  ],
        -left => [ %0, $f1d ],
    );

    # #-+ id_user

    # my $eid_user = $frm_middle->Entry(
    #     -width => 12,
    # );
    # $eid_user->form(
    #     -top   => [ '&', $lid_rep, 0 ],
    #     -right => [ %100, -10 ],
    # );
    # my $lid_user = $frm_middle->Label(
    #     -text => 'User',
    # );
    # $lid_user->form(
    #     -top   => [ '&', $lid_rep, 0 ],
    #     -right => [ $eid_user, -15 ],
    #     -padleft => 5,
    # );

    #-- repofile

    my $lrepofile = $frm_middle->Label( -text => 'Report file', );
    $lrepofile->form(
        -top     => [ $lid_rep, 5 ],
        -left    => [ %0,       0 ],
        -padleft => 10,
    );

    my $erepofile = $frm_middle->Entry(
        -width              => 40,
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $erepofile->form(
        -top  => [ '&', $lrepofile, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-- Parameter 1

    #-- label
    my $lparameter1 = $frm_middle->Label( -text => 'Parameter 1' );
    $lparameter1->form(
        -top     => [ $lrepofile, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    #-- hint
    my $eparahnt1 = $frm_middle->Entry(
        -width => 30,
    );
    $eparahnt1->form(
        -top  => [ '&', $lparameter1, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- value
    my $eparaval1 = $frm_middle->Entry(
        -width => 8,
    );
    $eparaval1->form(
        -top   => [ '&', $lparameter1, 0 ],
        -right => [ '&', $erepofile,   0 ],
    );

    #-- Parameter 2

    #-- label
    my $lparameter2 = $frm_middle->Label( -text => 'Parameter 2' );
    $lparameter2->form(
        -top     => [ $lparameter1, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    #-- hint
    my $eparahnt2 = $frm_middle->Entry(
        -width => 30,
    );
    $eparahnt2->form(
        -top  => [ '&', $lparameter2, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- value
    my $eparaval2 = $frm_middle->Entry(
        -width => 8,
    );
    $eparaval2->form(
        -top   => [ '&', $lparameter2, 0 ],
        -right => [ '&', $erepofile,   0 ],
    );

    #-- Parameter 3

    #-- label
    my $lparameter3 = $frm_middle->Label( -text => 'Parameter 3' );
    $lparameter3->form(
        -top     => [ $lparameter2, 8 ],
        -left    => [ %0, 0 ],
        -padleft => 10,
    );

    #-- hint
    my $eparahnt3 = $frm_middle->Entry(
        -width => 30,
    );
    $eparahnt3->form(
        -top  => [ '&', $lparameter3, 0 ],
        -left => [ %0, $f1d ],
    );

    #-- value
    my $eparaval3 = $frm_middle->Entry(
        -width => 8,
    );
    $eparaval3->form(
        -top   => [ '&', $lparameter3, 0 ],
        -right => [ '&', $erepofile,   0 ],
    );

    #-  Frame Bottom - Description

    my $frm_bottom = $mf->LabFrame(
        -foreground => 'blue',
        -label      => 'Description',
        -labelside  => 'acrosstop',
    );
    $frm_bottom->pack(
        -expand => 1,
        -fill   => 'both',
     );

    #- Detalii

    my $tdes = $frm_bottom->Scrolled(
        'Text',
        -width      => 40,
        -height     => 3,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'white',
    );
    $tdes->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    my $fonttdes = $tdes->cget('-font');

    #-- End Frame 3

    # Definim dialoguri
    my $dialog1 = $mf->Dialog(
        -text           => 'Nimic de cautat!',
        -bitmap         => 'question',
        -title          => 'Info',
        -default_button => 'OK',
        -buttons        => [qw/OK/]
    );

    # Entry objects fld_name => [0-tip_entry, 1-w|r-updatable? 2-var_asoc,
    #               3-var_obiect, 4-state, 5-color, 6-decimals, 7-type_of_find]
    # Type_of_find: 0=none, 1=all number, 2=contains_str, 3=all_str
    $self->{controls} = {
        id_rep   => [ 'e','r',undef,$eid_rep  ,'disabled', $bg   ,undef, 0 ],
        repofile => [ 'e','r',undef,$erepofile,'disabled', $bg   ,undef, 0 ],
        parahnt1 => [ 'e','w',undef,$eparahnt1,'disabled','white',undef, 0 ],
        paraval1 => [ 'e','w',undef,$eparaval1,'normal'  ,'white',undef, 0 ],
        parahnt2 => [ 'e','w',undef,$eparahnt2,'disabled','white',undef, 0 ],
        paraval2 => [ 'e','w',undef,$eparaval2,'normal'  ,'white',undef, 0 ],
        parahnt3 => [ 'e','w',undef,$eparahnt3,'disabled','white',undef, 0 ],
        paraval3 => [ 'e','w',undef,$eparaval3,'normal'  ,'white',undef, 0 ],
        des      => [ 't','r',undef,$tdes     ,'disabled', $bg   ,undef, 0 ],
    };

    #-- TM header

    my $header = {
        colstretch => '1',
        columns    => {
            repno => {
                places     => 0,
                width      => 3,
                validation => 'numeric',
                order      => 'N',
                id         => 0,
                label      => '#',
                tag        => 'ro_center',
                rw         => 'ro'
            },
            title => {
                places     => 0,
                width      => 25,
                validation => 'alphanum',
                order      => 'A',
                id         => 1,
                label      => 'Report name',
                tag        => 'ro_left',
                rw         => 'ro'
            },
            repid => {
                places     => 0,
                width      => 3,
                validation => 'numeric',
                order      => 'N',
                id         => 2,
                label      => 'Id',
                tag        => 'ro_center',
                rw         => 'ro'
            },

        },
        selectorcol => 3,
    };

    $self->{_tm}->init( $frm_top, $header );

    $self->load_report_list($view, $header->{selectorcol} );

    $self->{_tm}->configure(-state => 'disabled');

    $self->load_report_details($view);

    return;
}

=head2 dlg_exit

Quit Dialog.

=cut

sub dlg_exit {
    my $self = shift;

    $self->{'tlw'}->destroy;

    return;
}

sub load_report_list {
    my ($self, $view, $sc) = @_;

    my $args = {};
    $args->{table}    = 'reports';
    $args->{colslist} = [qw{id_rep title}]; #  id_user
    $args->{where}    = undef;
    $args->{order}    = 'title';

    my $reports_list = $view->{_model}->table_batch_query($args);

    my $recno = 0;
    foreach my $rec ( @{$reports_list} ) {
        $recno++;
        my $titles = {
            repno => $recno,
            repid => $rec->{id_rep},
            title => $rec->{title},
        };

        push @{ $self->{_rl} }, $titles;
    }

    # Clear and fill
    $self->{_tm}->clear_all();
    $self->{_tm}->fill( $self->{_rl} );
    $self->{_tm}->tmatrix_make_selector($sc);

    return;
}

sub load_report_details {
    my ($self, $view) = @_;

    my $selected_row = $self->{_tm}->get_selected;

    my $idx    = $selected_row - 1;                 # index for array
    my $id_rep = $self->{_rl}->[$idx]{repid};

    my $args = {};
    $args->{table}    = 'reports';
    $args->{colslist} = [qw{id_rep repofile title des script
                            paradef1 parahnt1 paraval1
                            paradef2 parahnt2 paraval2
                            paradef3 parahnt3 paraval3}];
    $args->{where}    = {id_rep => $id_rep};
    $args->{order}    = 'title';

    $self->{_rd} = $view->{_model}->table_batch_query($args);

    # Get widgets object defs from dialog
    my $eobj = $self->get_controls();

    # Reset bg color for all 'parahnt' widgets
    foreach my $field ( keys %{$eobj} ) {
        my $start_idx = $field eq 'des' ? "1.0" : 0; # 'des' is a text control
        my $value = $self->{_rd}->[0]{$field};
        $eobj->{$field}[3]->delete( $start_idx, 'end' );
        $eobj->{$field}[3]->insert( $start_idx, $value ) if $value;

        if ($field =~ m{parahnt[0-9]:e} ) {
            $eobj->{$field}[3]->configure(
                -background => 'white',
            );
        }
    }

    # Make bg color lightgreen for 'parahnt' field
    # when 'paradef' field contains a ':'
    # while ( my ( $field, $value ) = each( %{ $self->{tpda}{scrdata} } ) ) {

    #     # Scan value fields from dialog screen
    #     # 'paradef' and 'paraval' entry types == 'e'!
    #     if ( $field =~ m{paradef([0-9]):e} ) {
    #         my $idx = $1;
    #         my $def = $self->{tpda}{scrdata}{"paradef$idx:e"};
    #         if ( $def =~ m{:} ) {
    #             my $hnt_field = "parahnt$idx";
    #             $eobj->{$hnt_field}[3]->configure(
    #                 -state      => 'normal',
    #                 -background => 'lightgreen',
    #             );
    #         }
    #     }
    # }

    return;
}

sub preview_report {
    my $self = shift;

    print Dumper( $self->{_rd} );

    # Get widgets object defs from dialog
    my $eobj = $self->get_controls();

    # Reset bg color for all 'parahnt' widgets

    # Get parameter details from Entries
    my $parameters = q{};        # Empty
    foreach my $field ( keys %{$eobj} ) {
        next if $field eq 'des';

        my $value = $eobj->{$field}[3]->get;
        print "$field -> $value\n";
        # Scan value fields from dialog screen
        # 'paradef' and 'paraval' entry types == 'e'!
        if ( $field =~ m{paraval([0-9])} ) {
            my $idx = $1;
            print "idx: $idx\n";

            my $def = $eobj->{"paradef$idx"}[3]->get;
            print " def is $def\n";
            next if not $def;

            # separator is
            # : for values entered into paraval field using dialog
            # . for values entered into paraval field
            my ( $tbl, $fld ) = split( /[.:]/, $def );
            $parameters .= "-param$fld=$value ";
        }
    }
    print "Parameters: [ $parameters ]\n";

    # Get report filename
    my $report_file = $self->{_rd}[0]{repofile};

    my $cfg = Tpda3::Config->instance();

    my $report_path = $cfg->config_rep_file($report_file);
    unless (-f $report_path) {
        print "Report file not found: $report_path\n";
        return;
    }
    print " $report_path\n";

    #-- run Script
    # if ($script) {
    #     print " run Script NOT implemented\n";
    #     $script = 'main::' . $script;
    #     no strict 'refs';
    #     my $retval = &{$script}();
    # }

    # Metaviewxp param for pages:  -from 1 -to 1

    # my $report_exe  = $self->_cfg->cfextapps->{repman}{exe_path};

    # my $conf_dir = $self->{tpda}->get_config_path('conf_dir');
    # my $report_file = catfile($conf_dir, $repo_path, $report);

    # my $cmd;
    # if ($parameters) {
    #     $cmd = "$printrepxp -preview $parameters \"$report_file\"";
    # }
    # else {
    #     $cmd = "$printrepxp -preview \"$report_file\"";
    # }
    # print $cmd. "\n";
    # if ( system($cmd) ) {
    #     print "metaprintxp failed\n";
    # }

    return;
}

sub get_controls { return $_[0]->{controls}; }

1;
