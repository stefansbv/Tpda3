package Tpda3::Tk::Dialog::Search;

use strict;
use warnings;

use Tk::LabFrame;
use Tk::MListbox;
use Tk::StatusBar;
use Tk::JComboBox;

=head1 NAME

Tpda3::Tk::Dialog::Search - Dialog for dictionary search

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Search;

    my $fd = Tpda3::Tk::Dialog::Search->new;

    $fd->run_dialog($self);

=head1 METHODS

=head2 new

Constructor method

=cut

# Variabile locale
my $box;
my $field_ref;

sub new {
    my $type = shift;

    my $self = {};

    $self->{box} = {};    # Search results list box
                          # $self->{caut} = shift;    # Search object
                          # $self->{conf} = shift;    # Config object

    # $self->{mesg} = {};       # Message object
    # $self->{filt} = {};       # Filter

    # $self->{src_str}     = q{ };    # A space

    bless( $self, $type );

    return $self;
}

=head2 run_dialog

Show dialog

=cut

sub run_dialog {
    my ( $self, $mw, $table, $filter ) = @_;

    my $columns_ref;    # = $self->{conf}->get_general_conf_search($table);

    #--- Dialog Box

    my $dlg = $mw->DialogBox(
        -title   => 'Search dialog',
        -buttons => [ 'Load', 'Cancel' ]
    );

    #--- Main frame

    my $mf = $dlg->Frame()->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'both',
    );

    #-- Frame 1

    my $frm1 = $mf->Frame( -foreground => 'blue', )->pack(
        -expand => 1,
        -fill   => 'x',
        -ipady  => 3,
    );

    my $lblcamp = $frm1->Label()->grid(
        -row    => 0,
        -column => 0,
        -sticky => 'e',
        -padx   => 5,
    );

    #- Search string

    my $esir = $frm1->Entry( -width => 20, );

    my $selected;
    my $searchopt = $frm1->JComboBox(
        -entrywidth   => 10,
        -textvariable => \$selected,
        -choices      => [
            { -name => 'contains',    -value => 'C', -selected => 1 },
            { -name => 'starts with', -value => 'S' },
            { -name => 'ends with',   -value => 'E' },
        ],
    )->grid(
        -row    => 0,
        -column => 1,
        -padx   => 5,
        -pady   => 6,
    );

    $esir->grid(
        -row    => 0,
        -column => 2,
        -padx   => 5,
        -pady   => 5,
    );

    # Focus on Entry
    $esir->focus;

    # Buton cautare
    my $find_button = $frm1->Button(
        -text    => 'Find',
        -width   => 4,
        -command => [
            sub {
                my ($self) = @_;
                $self->search_command( $esir, $table, $columns_ref, \$selected,
                    $filter );
            },
            $self,
        ],
    );
    $find_button->grid(
        -row    => 0,
        -column => 3,
        -padx   => 5,
        -pady   => 5,
    );

    #-- Frame (lista rezultate)

    my $frm2 = $mf->LabFrame(
        -label      => 'Rezult',
        -foreground => 'darkgreen',
      )->pack(
        -expand => 1,
        -fill   => 'both',
        -ipadx  => 5,
        -ipady  => 3,
      );

    $self->{box} = $frm2->Scrolled(
        'MListbox',
        -scrollbars         => 'ose',
        -background         => 'white',
        -highlightthickness => 2,
        -width              => 0,
        -selectmode         => 'browse',
        -relief             => 'sunken',
    )->pack(
        -expand => 1,
        -fill   => 'both',
        -ipadx  => 5,
        -ipady  => 3,
    );

    # Box header

    my $den_label;
    my $colcnt = 0;

    foreach my $col ( @{$columns_ref} ) {

        $den_label = $col->{label} if $col->{key} eq 'scol1';    # label name
        my $label = $col->{label};
        my $name  = $col->{name};
        my $width = $col->{width};
        my $sort  = $col->{sort};

        $self->{box}->columnInsert( 'end', -text => $label );
        $self->{box}->columnGet($colcnt)->Subwidget("heading")
          ->configure( -background => 'tan' );
        $self->{box}->columnGet($colcnt)->Subwidget("heading")
          ->configure( -width => $width );

        if ( defined $sort ) {
            if ( $sort eq 'N' ) {
                $self->{box}->columnGet($colcnt)
                  ->configure( -comparecommand => sub { $_[0] <=> $_[1] } );
            }
        }
        else {
            warn "Warning: no sort option for $name\n";
        }

        $colcnt++;
    }

    # Search in field ...
    $den_label = $den_label || q{};    # Empty string if not defined
    $lblcamp->configure( -text => "[ $den_label ]", -foreground => 'blue' );

    $esir->bind(
        '<Return>',
        sub {

            # do find
            $find_button->focus;
            $find_button->invoke;
            $self->{box}->focus;
            Tk->break;
        }
    );

    #-- Frame

    my $frm3 = $mf->Frame()->pack(
        -expand => 1,
        -fill   => 'x',
        -ipady  => 3,
    );

    #- Label

    my $fltlbl = $frm3->Label(
        -text => 'Filter:',
    )->grid(
        -row    => 0,
        -column => 0,
        -sticky => 'e',
        -padx   => 5,
    );

    #- Filter label

    $self->{filt} = $frm3->Label(
        -relief => 'groove',
        -width  => 50,
    )->grid(
        -row    => 0,
        -column => 1,
        -padx   => 5,
        -pady   => 5,
    );

    #-- Frame

    my $frm4 = $mf->Frame()->pack( -expand => 1, -fill => 'x' );

    # Mesage label

    $self->{mesg} = $frm4->Label( -relief => 'sunken', )->pack(
        -expand => 1,
        -fill   => 'x',
        -padx   => 8,
    );

    # Callback for search JCombobox

    $searchopt->configure(
        -browsecmd => sub {
            my ( $self, $esir, $sele ) = @_;

            # Sterg continutul tabelului - init
            $self->{box}->delete( 0, 'end' );
        },
    );

    # Filter?

    if ($filter) {
        my $mesg = '';
        my ( $fltcmp, $fltval );
        my @filtre = split( /:/, $filter );
        foreach (@filtre) {
            ( $fltcmp, $fltval ) = split( /=/, $_ );
            $mesg .= "$fltcmp=$fltval ";
        }
        if ($fltval) {
            $self->refresh_filt( $mesg, 'red' );
        }
    }

    #---

    my $result = $dlg->Show;
    my $ind_cod;

    if ( $result =~ /Load/ ) {

        # Sunt inreg. in lista?
        eval { $ind_cod = $self->{box}->curselection(); };
        if ($@) {
            warn "Error: $@";

            # &status_mesaj_l('selectati o inreg.');
            return;
        }
        else {
            unless ($ind_cod) { $ind_cod = 0; }
        }
        my @valret = $self->{box}->getRow($ind_cod);

        # print "valret = @valret\n";
        return ( \@valret, $field_ref );
    }
    else {
        return "";
    }
}

=head2 search_command

Lookup in dictionary and display result in list box

=cut

sub search_command {
    my ( $self, $esir, $table, $columns, $sele, $filter ) = @_;

    my $src_opt = ${$sele};

    $self->{src_str} = $esir->get;

    # Sterg continutul tabelului - init
    $self->{box}->delete( 0, 'end' );

    # Search tabel for code -> name pairs
    my $inreg_ref;
    ( $inreg_ref, $field_ref ) =
      $self->{caut}->{tpda}->{conn}
      ->tbl_dict_search( $table, $columns, $self->{src_str}, $filter, $src_opt,
      );

    # Found records
    my $rowcnt = 0;
    if ($inreg_ref) {
        my $nrinreg = scalar @{$inreg_ref};
        my $mesaj = $nrinreg == 1 ? "one record" : "$nrinreg records";

        # $self->refresh_mesg( $mesaj, 'darkgreen' );
        foreach my $hashref ( @{$inreg_ref} ) {
            my @row = ();
            foreach my $field_width (@$field_ref) {
                my ( $field, $width ) = split( ':', $field_width );
                push @row, $hashref->{$field};
            }
            $self->{box}->insert( 'end', [@row] );

            # $self->{box}->see('active');
            # $self->{box}->update;
            $rowcnt++;
        }
        $self->{box}->selectionClear( 0, 'end' );
        $self->{box}->activate(0);
        $self->{box}->selectionSet(0);
        $self->{box}->see('active');
        $self->{box}->focus;
    }

    return $field_ref;
}

=head2 refresh_mesg

Refresh the message on the screen

=cut

sub refresh_mesg {
    my ( $self, $text, $color ) = @_;

    $self->{mesg}->configure( -textvariable => \$text ) if defined $text;
    $self->{mesg}->configure( -foreground   => $color ) if defined $color;

    return;
}

=head2 refresh_filt

Refresh the filter message on the screen

=cut

sub refresh_filt {
    my ( $self, $text, $color ) = @_;

    $self->{filt}->configure( -textvariable => \$text ) if defined $text;
    $self->{filt}->configure( -foreground   => $color ) if defined $color;

    return;
}

1;    # End of Tpda3::Tk::Dialog::Search
