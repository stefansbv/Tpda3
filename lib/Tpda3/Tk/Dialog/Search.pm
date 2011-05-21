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

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my $class = shift;

    return bless( {}, $class );
}

=head2 search

Show dialog

=cut

sub search {
    my ( $self, $view, $para, $filter ) = @_;

    #--- Dialog Box

    my $dlg = $view->DialogBox(
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

    my $search_ctrl = $frm1->Entry( -width => 20, );
    $search_ctrl->grid(
        -row    => 0,
        -column => 2,
        -padx   => 5,
        -pady   => 5,
    );

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

    # Focus on Entry
    $search_ctrl->focus;

    # Buton cautare
    my $find_button = $frm1->Button(
        -text    => 'Find',
        -width   => 4,
        -command => [
            sub {
                my ($self) = @_;
                $self->search_command(
                    $view->_model, $search_ctrl->get, $para,
                    $selected,     $filter
                );
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

    my @columns;
    my $colcnt = 0;
    foreach my $rec ( @{ $para->{columns} } ) {
        foreach my $field ( keys %{$rec} ) {

            # Use maping of name instead of 'field' if exists
            if (exists $rec->{$field}{name}) {
                push @columns, $rec->{$field}{name};
            }
            else {
                push @columns, $field;
            }

            $self->{box}->columnInsert( 'end', -text => $rec->{$field}{label} );
            $self->{box}->columnGet($colcnt)->Subwidget("heading")
              ->configure( -background => 'tan' );
            $self->{box}->columnGet($colcnt)->Subwidget("heading")
              ->configure( -width => $rec->{$field}{width} );

            if ( defined $rec->{$field}{order} ) {
                if ( $rec->{$field}{order} eq 'N' ) {
                    $self->{box}->columnGet($colcnt)
                      ->configure( -comparecommand => sub { $_[0] <=> $_[1] } );
                }
            }
            else {
                warn "Warning: no sort option for $field\n";
            }

            $colcnt++;
        }
    }

    # Search in field ...
    my $den_label = $para->{lookup} || q{}; # label name or empty string
    $lblcamp->configure( -text => "[ $den_label ]", -foreground => 'blue' );

    $search_ctrl->bind(
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

    # $searchopt->configure(
    #     -browsecmd => sub {
    #         my ( $self, $search_ctrl, $sele ) = @_;

    #         # Initialy empty
    #         # $self->{box}->delete( 0, 'end' );
    #     },
    # );

    # Filter?

    # if ($filter) {
    #     my $mesg = '';
    #     my ( $fltcmp, $fltval );
    #     my @filtre = split( /:/, $filter );
    #     foreach (@filtre) {
    #         ( $fltcmp, $fltval ) = split( /=/, $_ );
    #         $mesg .= "$fltcmp=$fltval ";
    #     }
    #     if ($fltval) {
    #         $self->refresh_filt( $mesg, 'red' );
    #     }
    # }

    #---

    my $result = $dlg->Show;
    my $ind_cod;

    if ( $result =~ /Load/ ) {

        # Sunt inreg. in lista?
        eval { $ind_cod = $self->{box}->curselection(); };
        if ($@) {
            warn "Error: $@";

            return;
        }
        else {
            unless ($ind_cod) { $ind_cod = 0; }
        }
        my @values = $self->{box}->getRow($ind_cod);

        #- Prepare data and return as hash reference

        my $row_data = {};
        for (my $i = 0; $i < @columns; $i++) {
            $row_data->{ $columns[$i] } = $values[$i];
        }

        return $row_data;
    }
    else {
        return;
    }
}

=head2 search_command

Lookup in dictionary and display result in list box

=cut

sub search_command {
    my ( $self, $model, $srcstr, $para, $options, $filter ) = @_;

    # Construct where, add findtype info
    my $params = {};
    $params->{table} = $para->{table};
    $params->{where}{ $para->{lookup} } = [ $srcstr, 'contains' ];
    $params->{options} = $options;
    $params->{columns} = [ map { keys %{$_} } @{ $para->{columns} } ];
    $params->{order} = $para->{lookup};      # order by lookup field

    my $records = $model->query_dictionary($params);

    # Sterg continutul tabelului - init
    $self->{box}->delete( 0, 'end' );

    # Found records
    my $rowcnt = 0;
    if ($records) {
        my $nrinreg = scalar @{$records};
        my $mesaj = $nrinreg == 1 ? "one record" : "$nrinreg records";

        $self->refresh_mesg( $mesaj, 'darkgreen' );
        foreach my $array_ref ( @{$records} ) {
            $self->{box}->insert( 'end', $array_ref );
            $rowcnt++;
        }
        $self->{box}->selectionClear( 0, 'end' );
        $self->{box}->activate(0);
        $self->{box}->selectionSet(0);
        $self->{box}->see('active');
        $self->{box}->focus;
    }

    return;
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
