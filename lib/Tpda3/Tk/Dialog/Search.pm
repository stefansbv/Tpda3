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

    $self->{caut} = shift;    # Search object
    $self->{conf} = shift;    # Config object

    $self->{topl} = {};       # TopLevel object
    $self->{mesg} = {};       # Message object
    $self->{filt} = {};       # Filter

    $self->{src_str}     = q{ };    # A space
    $self->{case_ignore} = 1;       # Ignore case checkbutton value

    bless( $self, $type );

    return $self;
}

=head2 run_dialog

Show dialog

=cut

sub run_dialog {
    my ( $self, $mw, $table, $filter ) = @_;

    my $columns_ref;# = $self->{conf}->get_general_conf_search($table);

    #-- Dialog Box

    $self->{topl} = $mw->DialogBox(
        -title   => 'Search dialog',
        -buttons => [ 'Load', 'Cancel' ]
    );

    # Main frame

    my $mf = $self->{topl}->Frame();
    $mf->pack( -side => 'top', -anchor => 'nw', -fill => 'both' );

    # Frame 1

    # Optiuni cautare
    my $frm1 = $mf->Frame( -foreground => 'blue' );
    $frm1->pack( -expand => 1, -fill => 'x', -ipady => 3 );

    my $lblcamp = $frm1->Label();
    $lblcamp->grid( -row => 0, -column => 0, -sticky => 'e', -padx => 5 );

    # Entry sir cautare
    my $esir = $frm1->Entry( -width => 20 );

    my $selected;
    my $searchopt = $frm1->JComboBox(
        -entrywidth   => 10,
        -textvariable => \$selected,
        -choices      => [
            { -name => 'contains',    -value => 'C', -selected => 1 },
            { -name => 'starts with', -value => 'S' },
            { -name => 'end with',    -value => 'E' },
        ]
    );

    $searchopt->grid( -row => 0, -column => 1, -padx => 5, -pady => 6 );

    $esir->grid( -row => 0, -column => 2, -padx => 5, -pady => 5 );

    # Focus on Entry
    $esir->focus;

    # Buton cautare
    my $but1 = $frm1->Button(
        -text    => 'Find',
        -width   => 7,
        -command => [
            sub {
                my ($self) = @_;
                $self->search_command( $esir, $table, $columns_ref, \$selected,
                    $filter );
            },
            $self,
        ],
    );
    $but1->grid( -row => 0, -column => 3, -padx => 5, -pady => 5 );

    # Frame cu lista rezultate

    my $frm2 = $mf->LabFrame(
        -label      => 'Rezult',
        -foreground => 'darkgreen'
    );
    $frm2->pack( -expand => 1, -fill => 'both', -ipadx => 5, -ipady => 3 );

    $box = $frm2->Scrolled(
        'MListbox',
        -scrollbars         => 'ose',
        -background         => 'white',
        -highlightthickness => 2,
        -width              => 0,
        -selectmode         => 'browse',
        -relief             => 'sunken',
    );

    # $box->grid(-row => 0, -column => 0, -sticky => 'nsew');
    $box->pack( -expand => 1, -fill => 'both', -ipadx => 5, -ipady => 3 );

    # Box header

    my $den_label;
    my $colcnt = 0;

    foreach my $col ( @{$columns_ref} ) {

        $den_label = $col->{label} if $col->{key} eq 'scol1'; # label name
        my $label = $col->{label};
        my $name  = $col->{name};
        my $width = $col->{width};
        my $sort  = $col->{sort};

        $box->columnInsert( 'end', -text => $label );
        $box->columnGet($colcnt)->Subwidget("heading")
          ->configure( -background => 'tan' );
        $box->columnGet($colcnt)->Subwidget("heading")
          ->configure( -width => $width );

        if ( defined $sort ) {
            if ( $sort eq 'N' ) {
                $box->columnGet($colcnt)
                  ->configure( -comparecommand => sub { $_[0] <=> $_[1] } );
            }
        }
        else {
            warn "Warning: no sort option for $name\n";
        }

        $colcnt++;
    }

    # Search in field ...
    $den_label = $den_label || q{}; # Empty if not defined
    $lblcamp->configure( -text => "[ $den_label ]", -foreground => 'blue' );

    $esir->bind(
        '<Return>',
        sub {

            # do find
            $but1->focus;
            $but1->invoke;
            $box->focus;
            Tk->break;
        }
    );

    my $frm3 = $mf->Frame()->pack( -fill => 'x' );

    # Label

    my $fltlbl = $frm3->Label(
        -text => 'Filter:',
        -padx => 5,
        -pady => 5,
      )->pack(
        -side   => 'left',
        -anchor => 'w',
      );

    # Filter label

    $self->{filt} = $frm3->Label(
        -relief => 'groove',
        -width  => 50
      )->pack(
        -padx   => 5,
        -side   => 'left',
        -anchor => 'e',
      );

    my $frm4 = $mf->Frame()->pack( -fill => 'x' );

    # Mesage label

    $self->{mesg} = $frm4->Label( -anchor => 's' )->pack(
        -side   => 'left',
        -expand => 1,
        -anchor => 'w',
        -fill   => 'x'
    );

    # Callback for search JCombobox

    $searchopt->configure(
        -browsecmd => sub {
            my ( $self, $esir, $sele ) = @_;

            # Sterg continutul tabelului - init
            $box->delete( 0, 'end' );
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

    my $result = $self->{topl}->Show;
    my $ind_cod;

    if ( $result =~ /Load/ ) {

        # Sunt inreg. in lista?
        eval { $ind_cod = $box->curselection(); };
        if ($@) {
            warn "Error: $@";

            # &status_mesaj_l('selectati o inreg.');
            return;
        }
        else {
            unless ($ind_cod) { $ind_cod = 0; }
        }
        my @valret = $box->getRow($ind_cod);

        # print "valret = @valret\n";
        return ( \@valret, $field_ref );
    }
    else {
        return "";
    }
}

sub search_command {
    my ($self, $esir, $table, $columns, $sele, $filter) = @_;

    my $src_opt = ${$sele};

    # $self->build_str( $esir, $src_opt ); # Not needed ???
    $self->{src_str} = $esir->get;

    # Sterg continutul tabelului - init
    $box->delete( 0, 'end' );

    # Search tabel for code -> name pairs
    my $inreg_ref;
    ( $inreg_ref, $field_ref ) =
      $self->{caut}->{tpda}->{conn}
      ->tbl_dict_search( $table, $columns, $self->{src_str}, $filter, $src_opt,
      );

    # Found records
    my $rowcnt = 0;
    if ($inreg_ref) {
        my $nrinreg = $#{$inreg_ref} + 1;
        my $mesaj = $nrinreg == 1 ? "one record" : "$nrinreg records";
        $self->refresh_mesg( $mesaj, 'darkgreen' );
        foreach my $hashref ( @{$inreg_ref} ) {
            my @row = ();
            foreach my $field_width (@$field_ref) {
                my ( $field, $width ) = split( ':', $field_width );
                push @row, $hashref->{$field};
            }
            $box->insert( 'end', [@row] );

            # $box->see('active');
            # $box->update;
            $rowcnt++;
        }
        $box->selectionClear( 0, 'end' );
        $box->activate(0);
        $box->selectionSet(0);
        $box->see('active');
        $box->focus;
    }

    return $field_ref;
}

sub refresh_mesg {

   # +-------------------------------------------------------------------------+
   # | Descriere: Refresh the Message on the screen                            |
   # | Parametri: obiect                                                       |
   # +-------------------------------------------------------------------------+

    my ( $self, $text, $color ) = @_;

    $self->{mesg}->configure( -textvariable => \$text ) if defined $text;
    $self->{mesg}->configure( -foreground   => $color ) if defined $color;

    return;
}

sub refresh_filt {

 # +---------------------------------------------------------------------------+
 # | Descriere: Refresh the Message on the screen                              |
 # | Parametri: obiect                                                         |
 # +---------------------------------------------------------------------------+

    my ( $self, $text, $color ) = @_;

    $self->{filt}->configure( -textvariable => \$text ) if defined $text;
    $self->{filt}->configure( -foreground   => $color ) if defined $color;

    return;
}

1; # End of Tpda3::Tk::Dialog::Search
