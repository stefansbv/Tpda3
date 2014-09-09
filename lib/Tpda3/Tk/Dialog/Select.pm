package Tpda3::Tk::Dialog::Select;

# ABSTRACT: Dialog for dictionary search

use strict;
use warnings;
use utf8;
use Locale::TextDomain 1.20 qw(Tpda3);

use Tk::LabFrame;
use Tk::MListbox;
use Tk::StatusBar;
use Tk::JComboBox;


sub new {
    my ($class, $opts) = @_;

    my $self = {};

    bless( $self, $class );

    return $self;
}


sub select_dialog {
    my ( $self, $view, $para ) = @_;

    #--- Dialog Box

    my $dlg = $view->DialogBox(
        -title   => __ 'Select',
        -buttons => [ __ 'Load', __ 'Cancel' ],
    );

    #-- Key bindings

    $dlg->bind( '<Escape>',
        sub { $dlg->Subwidget( 'B_' . __ 'Cancel' )->invoke } );

    #-- Main frame

    my $mf = $dlg->Frame()->pack(
        -side   => 'top',
        -anchor => 'nw',
        -fill   => 'both',
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
        -selectmode         => 'multiple',
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
            if ( exists $rec->{$field}{name} ) {
                push @columns, $rec->{$field}{name};
            }
            else {
                push @columns, $field;
            }

            $self->{box}
                ->columnInsert( 'end', -text => $rec->{$field}{label} );
            $self->{box}->columnGet($colcnt)->Subwidget("heading")
                ->configure( -background => 'tan' );
            $self->{box}->columnGet($colcnt)->Subwidget("heading")
                ->configure( -width => $rec->{$field}{displ_width} );

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

    #-- Frame

    my $frm3 = $mf->Frame()->pack(
        -expand => 1,
        -fill   => 'x',
        -ipady  => 3,
    );

    #-- Frame

    my $frm4 = $mf->Frame()->pack( -expand => 1, -fill => 'x' );

    # Mesage label

    $self->{mesg} = $frm4->Label( -relief => 'sunken', )->pack(
        -expand => 1,
        -fill   => 'x',
        -padx   => 8,
    );

    #---

    $self->refresh_message( 'Aşteptaţi...', 'darkgreen' );

    $dlg->after( 100, sub { $self->select_command( $view->model, $para ) } );

    my $result = $dlg->Show;

    my @options = ( N__"Load" );
    my $option_load  = __( $options[0] );

    my @indexes;
    if ( $result =~ /$option_load/i ) {
        eval { @indexes = $self->{box}->curselection(); };
        unless ($@) {
            # Something selected
            my @columns;
            foreach my $col_rec ( @{ $para->{columns} } ) {
                foreach my $field ( keys %{$col_rec} ) {
                    push @columns, $field;
                }
            }
            my @records;
            my $doccnt = 1;
            foreach my $idx (@indexes) {
                my @selected_row = $self->{box}->getRow($idx);
                my $rec = {};
                for (my $i = 0; $i <= $#selected_row; $i++) {
                    $rec->{ $columns[$i] } = $selected_row[$i];
                }
                $rec->{id_doc} = $doccnt; # add hardwired field: id_doc
                push @records, $rec;
                $doccnt++;
            }

            return \@records;
        }
    }
    else {
        return;    # cancel
    }
}


sub select_command {
    my ( $self, $model, $para ) = @_;

    # Construct where, add findtype info
    my $params = {};
    $params->{table}   = $para->{table};
    $params->{columns} = [ map { keys %{$_} } @{ $para->{columns} } ];
    $params->{order}   = $para->{search};    # order by lookup field

    my $records = $model->query_dictionary($params);

    # Sterg continutul tabelului - init
    $self->{box}->delete( 0, 'end' );

    # Found records
    my $rowcnt = 0;
    if ($records) {
        my $nrinreg = scalar @{$records};
        my $mesaj = $nrinreg == 1 ? "one record" : "$nrinreg records";

        $self->refresh_message( $mesaj, 'darkgreen' );
        foreach my $rec ( @{$records} ) {
            $self->{box}->insert( 'end', $rec );
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


sub refresh_message {
    my ( $self, $text, $color ) = @_;

    $self->{mesg}->configure( -textvariable => \$text ) if defined $text;
    $self->{mesg}->configure( -foreground   => $color ) if defined $color;

    return;
}

1;

=head1 SYNOPSIS

    use Tpda3::Tk::Dialog::Select;

    my $fd = Tpda3::Tk::Dialog::Select->new;

    $fd->search($self);

=head2 new

Constructor method.

=head2 select_dialog

Define and show search dialog.

=head2 select_command

Lookup in dictionary and display result in list box.

=head2 refresh_message

Refresh the message on the screen.

=cut
