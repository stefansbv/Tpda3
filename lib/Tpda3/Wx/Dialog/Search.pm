package Tpda3::Wx::Dialog::Search;

use strict;
use warnings;

use Wx qw{:everything};
use Wx::Event qw(EVT_BUTTON EVT_TEXT_ENTER
    EVT_CHOICE EVT_LIST_ITEM_ACTIVATED);
use Wx::Perl::ListCtrl;

use base qw{Wx::Dialog};

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;

    my $self = {};

    $self->{choices} = {
        'contains'    => 'C',
        'starts with' => 'S',
        'ends with'   => 'E',
    };

    bless $self, $class;

    return $self;
}

=head2 search_dialog

Search dialog GUI

=cut

sub search_dialog {
    my ( $self, $view, $para, $filter ) = @_;

    my $field_name = $para->{lookup} || q{};

    my $dlg = $self->SUPER::new(
        $view, -1, $field_name,
        [ -1, -1 ],
        [ -1, -1 ],
        wxDEFAULT_DIALOG_STYLE | wxCAPTION,
    );

    # A top-level sizer
    my $top_sz = Wx::BoxSizer->new(wxVERTICAL);

    # A second box sizer to give more space around the controls
    my $box_sz = Wx::BoxSizer->new(wxVERTICAL);
    $top_sz->Add( $box_sz, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5 );

    #-- Search controls

    my $search_sz = Wx::BoxSizer->new(wxHORIZONTAL);
    $box_sz->Add( $search_sz, 0, wxGROW | wxALL, 5 );

    # Options for search
    my $option = Wx::Choice->new(
        $dlg, -1,
        [ -1,  -1 ],
        [ 135, -1 ],
        [ 'contains', 'starts with', 'ends with' ],
    );
    $option->SetStringSelection('contains');
    $search_sz->Add( $option, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5 );
    my $selected = 'contains';    # default

    EVT_CHOICE $dlg, $option, sub {
        my $choice = $_[1]->GetSelection;
        my $text   = $_[1]->GetString;
        $selected = $self->choices($text);
    };

    my $search_ctrl = Wx::SearchCtrl->new(
        $dlg, -1, q{},
        [ -1,  -1 ],
        [ 200, -1 ],
        wxTE_PROCESS_ENTER,
    );
    $search_sz->Add( $search_ctrl, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5 );
    $search_ctrl->SetFocus();

    EVT_TEXT_ENTER $dlg, $search_ctrl, sub {
        $self->search_command( $view->_model, $search_ctrl->GetValue, $para,
            $selected, $filter );
        $self->{_list}->SetFocus();
        $self->{_list}->Select( 0, 1 );
    };

    # The Find button
    my $find_btn
        = Wx::Button->new( $dlg, -1, "&Find", [ -1, -1 ], [ 50, -1 ], 0, );
    $search_sz->Add( $find_btn, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5 );

    # Enter in search control and Find button both call the
    # search_command sub, is there something like 'Tk invoke'?

    EVT_BUTTON $dlg, $find_btn, sub {
        $self->search_command( $view->_model, $search_ctrl->GetValue, $para,
            $selected, $filter );
        $self->{_list}->SetFocus();
        $self->{_list}->Select( 0, 1 );
    };

    #-- List control

    my $list_sz = Wx::BoxSizer->new(wxVERTICAL);
    $box_sz->Add( $list_sz, 0, wxGROW | wxALL, 5 );

    my $list_sb = Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $dlg, -1, ' Search result ', ), wxHORIZONTAL, );

    $self->{_list} = Wx::Perl::ListCtrl->new(
        $dlg, -1,
        [ -1, -1 ],
        [ -1, 200 ],
        Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
    );

    #--- List header

    my @header_cols = @{ $para->{columns} };
    my $header_attr = {};
    my @columns;
    foreach my $col (@header_cols) {
        foreach my $field ( keys %{$col} ) {

            push @columns, $field;

            # Width config is in chars.  Using chars_number x char_width
            # to compute the with in pixels
            my $label_len = length $col->{$field}{label};
            my $width     = $col->{$field}{width};
            $width = $label_len >= $width ? $label_len + 2 : $width;
            $width = 30 if $width >= 30;
            my $char_width = $view->GetCharWidth();
            $header_attr->{$col} = {
                label => $col->{$field}{label},
                width => $width * $char_width,
                order => $col->{$field}{order},
            };
        }
    }
    $self->make_list_header( \@header_cols, $header_attr );

    $self->{_cols} = \@columns;    # store column names

    $list_sb->Add( $self->{_list}, 1, wxEXPAND,         0 );
    $list_sz->Add( $list_sb,       1, wxALL | wxEXPAND, 5 );

    #-- Status

    my $lable_sz = Wx::BoxSizer->new(wxVERTICAL);
    $box_sz->Add( $lable_sz, 0, wxEXPAND | wxALL, 5 );

    $self->{_flt}
        = Wx::StaticText->new( $dlg, -1, q{}, [ -1, -1 ], [ -1, -1 ], );
    $lable_sz->Add( $self->{_flt}, 0, wxALIGN_RIGHT | wxRIGHT, 10 );
    $self->refresh_filter( 'filter is off', 'orange' ) if !defined $filter;

    $self->{_msg}
        = Wx::StaticText->new( $dlg, -1, q{}, [ -1, -1 ], [ -1, -1 ], );
    $lable_sz->Add( $self->{_msg}, 0, wxALIGN_LEFT | wxLEFT, 10 );

    # A dividing line before the OK and Cancel buttons
    my $line = Wx::StaticLine->new(
        $dlg, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        wxLI_HORIZONTAL,
    );
    $box_sz->Add( $line, 0, wxGROW | wxALL, 5 );

    #-- Buttons

    my $button_sz = Wx::BoxSizer->new(wxHORIZONTAL);
    $box_sz->Add( $button_sz, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5 );

    # The OK button
    my $ok_btn
        = Wx::Button->new( $dlg, wxID_OK, "&OK", [ -1, -1 ], [ -1, -1 ], 0, );
    $button_sz->Add( $ok_btn, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5 );

    # The Cancel button
    my $cancel_btn = Wx::Button->new(
        $dlg, wxID_CANCEL, "&Cancel",
        [ -1, -1 ],
        [ -1, -1 ], 0,
    );
    $button_sz->Add( $cancel_btn, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5 );

    $dlg->SetSizer($top_sz);
    $dlg->Fit;

    EVT_LIST_ITEM_ACTIVATED $dlg, $self->{_list}, sub {

        # $ok_btn->SetFocus();
        # Invoking the button, but no visual feedback ...
        my $event = Wx::CommandEvent->new( &Wx::wxEVT_COMMAND_BUTTON_CLICKED,
            $ok_btn->GetId(), );
        $ok_btn->GetEventHandler->ProcessEvent($event);
    };

    # $ok_btn->SetDefault();                  # does not work
    # $find_btn->SetDefault();                # does not work

    return $dlg;
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
    $params->{order} = $para->{lookup};    # order by lookup field

    my $records = $model->query_dictionary($params);

    $self->{_list}->DeleteAllItems;

    #-- Insert records in list

    my $rowcnt = 0;
    if ($records) {
        my $record_cnt = scalar @{$records};
        my $msg = $record_cnt == 1 ? q{one record} : qq{$record_cnt records};
        $msg = q{limited to } . $msg if $record_cnt >= 50;

        $self->refresh_message( $msg, 'darkgreen' );
        foreach my $record ( @{$records} ) {
            my $colmax = scalar @{ $para->{columns} };

            $self->{_list}->InsertStringItem( $rowcnt, 'dummy' );
            for ( my $col = 0; $col < $colmax; $col++ ) {
                $self->{_list}->SetItemText( $rowcnt, $col, $record->[$col] );
            }

            $rowcnt++;
        }
    }

    return;
}

=head2 get_selected_item

Return the selected record to caller.

Record is a hashref:

  {
   fieldname1 => value1,
   fieldname2 => value2,
  }

If Cancel is pressed than the hash values are undef.

=cut

sub get_selected_item {
    my $self = shift;

    my $empty;
    my $sel_no = $self->{_list}->GetSelectedItemCount();
    $empty = 1 if ( $sel_no <= 0 );

    my $row = $self->{_list}->GetSelection();

    my $row_data = {};
    for ( my $j = 0; $j < @{ $self->{_cols} }; $j++ ) {
        my $item_text
            = $empty
            ? undef
            : $self->{_list}->GetItemText( $row, $j );
        $row_data->{ $self->{_cols}->[$j] } = $item_text;
    }

    return $row_data;
}

=head2 refresh_mesg

Refresh the message on the screen.

=cut

sub refresh_message {
    my ( $self, $text, $color ) = @_;

    $self->{_msg}->SetLabel($text) if defined $text;
    $self->{_msg}->SetForegroundColour( Wx::Colour->new($color) ) if $color;

    return;
}

=head2 refresh_filter

Refresh the filter message on the screen.

=cut

sub refresh_filter {
    my ( $self, $text, $color ) = @_;

    $self->{_flt}->SetLabel($text) if defined $text;
    $self->{_flt}->SetForegroundColour( Wx::Colour->new($color) ) if $color;

    return;
}

=head2 make_list_header

Make the header for the list control.

=cut

sub make_list_header {
    my ( $self, $header_cols, $header_attr ) = @_;

    # Delete all items and all columns
    $self->{_list}->ClearAll();

    # Header
    my $colcnt = 0;
    foreach my $col ( @{$header_cols} ) {
        my $attr = $header_attr->{$col};

        $self->{_list}
            ->InsertColumn( $colcnt, $attr->{label}, wxLIST_FORMAT_LEFT,
            $attr->{width}, );

        $colcnt++;
    }

    return;
}

=head2 choices

Return codified choice.

=cut

sub choices {
    my ( $self, $choice ) = @_;

    return $self->{choices}{$choice};
}

1;    # End of Tpda3::Wx::Dialog::Search
