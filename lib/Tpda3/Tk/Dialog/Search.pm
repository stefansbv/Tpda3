package Tpda3::Tk::Dialog::Search;

use strict;
use warnings;
use utf8;

use Locale::TextDomain 1.20 qw(Tpda3);

use Tk::LabFrame;
use Tk::MListbox;
use Tk::StatusBar;
use Tk::JComboBox;

=head1 NAME

Tpda3::Tk::Dialog::Search - Dialog for dictionary search

=head1 VERSION

Version 0.83

=cut

our $VERSION = '0.83';

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Search;

    my $fd = Tpda3::Tk::Dialog::Search->new;

    $fd->search($self);

=head1 METHODS

=head2 new

Constructor method

=cut

sub new {
    my ($class, $opts) = @_;

    my $self = {};

    bless( $self, $class );

    return $self;
}

=head2 search_dialog

Define and show search dialog.

=cut

sub search_dialog {
    my ( $self, $view, $para, $filter ) = @_;

    #--- Dialog Box

    my $dlg = $view->DialogBox(
        -title   => __ 'Search',
        -buttons => [ __ 'Load', __ 'Clear', __ 'Cancel' ],
    );

    #-- Key bindings

    $dlg->bind( '<Escape>',
        sub { $dlg->Subwidget( 'B_' . __ 'Cancel' )->invoke } );
    $dlg->bind( '<Alt-r>',
        sub { $dlg->Subwidget( 'B_' . __ 'Clear' )->invoke } );

    #-- Main frame

    my $mf = $dlg->Frame()->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'both',
    );

    #--- Frame 1

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
            { -name => __ 'contains', -value => 'C', -selected => 1 },
            { -name => __ 'starts'  , -value => 'S', },
            { -name => __ 'ends'    , -value => 'E', },
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
        -text    => __ 'Find',
        -width   => 4,
        -command => [
            sub {
                my ($self) = @_;
                $self->search_command( $view->model, $search_ctrl->get,
                    $para, $selected, $filter );
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
        -label      => __ 'Result',
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

    #--- List header

    my @columns;
    my $colcnt = 0;
    foreach my $rec ( @{ $para->{columns} } ) {
        foreach my $field ( keys %{$rec} ) {

            # Use maping of name instead of 'field' if exists
            if ( exists $rec->{$field}{name} ) {
                push @columns, $rec->{$field}{name};
            }
            else {
                push @columns, $field;
            }

            my $displ_width = $rec->{$field}{displ_width};
            unless ($displ_width) {
                die "No 'displ_width' for '$field'\n";
            }

            $self->{box}
                ->columnInsert( 'end', -text => $rec->{$field}{label} );
            $self->{box}->columnGet($colcnt)->Subwidget("heading")
                ->configure( -background => 'tan' );
            $self->{box}->columnGet($colcnt)->Subwidget("heading")
                ->configure( -width => $displ_width );

            if ( defined $rec->{$field}{datatype} ) {
                if (   $rec->{$field}{datatype} eq 'integer'
                    or $rec->{$field}{datatype} eq 'numeric' )
                {
                    $self->{box}->columnGet($colcnt)
                        ->configure(
                        -comparecommand => sub { $_[0] <=> $_[1] } );
                }
            }
            else {
                die "No data type for '$field'\n";
            }

            $colcnt++;
        }
    }

    # Search in field ...
    my $den_label = $para->{search} || q{};    # label name or empty string
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

    #- Filter label

    $self->{filt} = $frm3->Label(
        -relief => 'groove',
        -width  => 50,
        )->grid(
        -row    => 0,
        -column => 0,
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

    # Filter?

    if ( ref $filter ) {
        my $message;
        foreach my $key ( keys %{$filter} ) {
            my $value = $filter->{$key};
            unless ($value) {
                $message = "disabled == NO value for $key == disabled";
                $self->refresh_filter_message( $message, 'darkred' );
                $filter = undef;    # disable filter
            }
            else {
                $message .= "filter == $key : $value == filter";
                $self->refresh_filter_message( $message, 'darkgreen' );
            }
        }
    }

    #---

    my $result = $dlg->Show;
    my $ind_cod;

    my @options = (
        N__"Load",
        N__"Clear",
    );
    my $option_load  = __( $options[0] );
    my $option_clear = __( $options[1] );

    if ( $result =~ /$option_load/i ) {
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
        for ( my $i = 0; $i < @columns; $i++ ) {
            $row_data->{ $columns[$i] } = $values[$i];
        }

        return $row_data;
    }
    elsif ( $result =~ /$option_clear/i ) {

        # Prepare empty values
        my $row_data = {};
        for ( my $i = 0; $i < @columns; $i++ ) {
            $row_data->{ $columns[$i] } = undef;
        }

        return $row_data;
    }
    else {
        return;                 # cancel
    }
}

=head2 search_command

Lookup in dictionary and display result in list box.

=cut

sub search_command {
    my ( $self, $model, $srcstr, $para, $options, $filter ) = @_;

    # $self->refresh_filter_message( $filter, 'green' );

    # Construct where, add findtype info
    my $params = {};
    $params->{table} = $para->{table};
    $params->{where}{ $para->{search} } = [ $srcstr, 'contains' ];
    $params->{options} = $options;
    $params->{columns} = [ map { keys %{$_} } @{ $para->{columns} } ];
    $params->{order} = $para->{search};    # order by lookup field

    if ( ref $filter ) {

        # Add the filter to the WHERE (merge hash refs)
        @{ $params->{where} }{ keys %{$filter} }
            = [ values %{$filter}, 'full' ];
    }

    my $records = $model->query_dictionary($params);

    # Sterg continutul tabelului - init
    $self->{box}->delete( 0, 'end' );

    # Found records
    my $rowcnt = 0;
    if ($records) {
        my $nrinreg = scalar @{$records};
        my $mesaj = $nrinreg == 1 ? "one record" : "$nrinreg records";

        $self->refresh_message( $mesaj, 'darkgreen' );
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

=head2 refresh_message

Refresh the message on the screen.

=cut

sub refresh_message {
    my ( $self, $text, $color ) = @_;

    $self->{mesg}->configure( -textvariable => \$text ) if defined $text;
    $self->{mesg}->configure( -foreground   => $color ) if defined $color;

    return;
}

=head2 refresh_filter_message

Refresh the filter message on the screen

=cut

sub refresh_filter_message {
    my ( $self, $text, $color ) = @_;

    $self->{filt}->configure( -textvariable => \$text ) if defined $text;
    $self->{filt}->configure( -foreground   => $color ) if defined $color;

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Tpda3::Tk::Dialog::Search
