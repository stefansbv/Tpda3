package Tpda3::Wx::View;

use strict;
use warnings;

use Data::Dumper;

use File::Spec::Functions qw(abs2rel);
use Wx qw[:everything];
use Wx::Perl::ListCtrl;
use Wx::STC;

use Tpda3::Config;
use Tpda3::Wx::Notebook;
use Tpda3::Wx::ToolBar;

use base 'Wx::Frame';

=head1 NAME

Tpda3::Wx::App - Wx Perl application class

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Tpda3::Wx::Notebook;

    $self->{_nb} = Tpda3::Wx::Notebook->new( $gui );

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my $class = shift;
    my $model = shift;

    #- The Frame

    my $self = __PACKAGE__->SUPER::new( @_ );

    Wx::InitAllImageHandlers();

    $self->{_model} = $model;

    $self->SetMinSize( Wx::Size->new( 425, 597 ) );
    $self->SetIcon( Wx::GetWxPerlIcon() );

    #-- Menu
    $self->create_menu();

    #-- ToolBar
    # $self->SetToolBar( Tpda3::Wx::ToolBar->new( $self, wxADJUST_MINSIZE ) );
    # $self->{_tb} = $self->GetToolBar;
    # $self->{_tb}->Realize;

    #-- Statusbar
    $self->create_statusbar();

    #-- Notebook
    # $self->{_nb} = Tpda3::Wx::Notebook->new( $self );

    #--- Parameters Tab (page) Panel
    # $self->create_para_page();

    # #--- SQL Tab (page)
    # $self->create_sql_page();

    # #--- Configs Tab (page)
    # $self->create_config_page();

    # #--- Front Tab (page)
    # $self->create_report_page();

    # $self->_set_model_callbacks();

    $self->Fit;

    return $self;
}

=head2 _model

Return model instance

=cut

sub _model {
    my $self = shift;

    $self->{_model};
}

=head2 _set_model_callbacks

Define the model callbacks

=cut

sub _set_model_callbacks {
    my $self = shift;

    my $tb = $self->get_toolbar();
    #-
    my $co = $self->_model->get_connection_observable;
    $co->add_callback(
        sub { $tb->ToggleTool( $self->get_toolbar_btn_id('tb_cn'), $_[0] ) } );
    #--
    my $em = $self->_model->get_editmode_observable;
    $em->add_callback(
        sub {
            $tb->ToggleTool( $self->get_toolbar_btn_id('tb_ed'), $_[0] );
            $self->toggle_sql_replace();
        }
    );
    #--
    my $upd = $self->_model->get_itemchanged_observable;
    $upd->add_callback(
        sub { $self->controls_populate(); } );
    #--
    my $so = $self->_model->get_stdout_observable;
    #$so->add_callback( sub{ $self->log_msg( $_[0] ) } );
    $so->add_callback( sub{ $self->status_msg( @_ ) } );

    my $xo = $self->_model->get_exception_observable;
    # $xo->add_callback( sub{ $self->dialog_msg( @_ ) } );
    $xo->add_callback( sub{ $self->log_msg( @_ ) } );
}

=head2 create_menu

Create the menu

=cut

sub create_menu {
    my $self = shift;

    my $menu = Wx::MenuBar->new;

    $self->{_menu} = $menu;

    my $menu_app = Wx::Menu->new;
    $menu_app->Append( wxID_EXIT, "E&xit\tAlt+X" );
    $menu->Append( $menu_app, "&App" );

    my $menu_help = Wx::Menu->new();
    $menu_help->AppendString( wxID_HELP, "&Contents...", q{} );
    $menu_help->AppendString( wxID_ABOUT, "&About", q{} );
    $menu->Append( $menu_help, "&Help" );

    $self->SetMenuBar($menu);
}

=head2 get_menubar

Return the menu bar handler

=cut

sub get_menubar {
    my $self = shift;
    return $self->{_menu};
}

=head2 create_statusbar

Create the status bar

=cut

sub create_statusbar {
    my $self = shift;

    my $sb = $self->CreateStatusBar( 3 );
    $self->{_sb} = $sb;

    $self->SetStatusWidths( 260, -1, -2 );
}

=head2 get_statusbar

Return the status bar handler

=cut

sub get_statusbar {
    my $self = shift;

    return $self->{_sb};
}

=head2 get_notebook

Return the notebook handler

=cut

sub get_notebook {
    my $self = shift;

    return $self->{_nb};
}

=head2 create_report_page

Create the report page (tab) on the notebook

=cut

sub create_report_page {
    my $self = shift;

    $self->{_list} = Wx::Perl::ListCtrl->new(
        $self->{_nb}{p1}, -1,
        [ -1, -1 ],
        [ -1, -1 ],
        Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
    );

    $self->{_list}->InsertColumn( 0, '#',           wxLIST_FORMAT_LEFT, 50  );
    $self->{_list}->InsertColumn( 1, 'Query name', wxLIST_FORMAT_LEFT, 337 );

    #-- Controls

    my $repo_lbl1 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Title', );
    $self->{title} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl2 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Query file', );
    $self->{filename} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl3 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Output file', );
    $self->{output} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $repo_lbl4 = Wx::StaticText->new( $self->{_nb}{p1}, -1, 'Sheet name', );
    $self->{sheet} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    $self->{description} =
        Wx::TextCtrl->new( $self->{_nb}{p1}, -1, q{}, [ -1, -1 ], [ -1, 40 ],
                           wxTE_MULTILINE, );

    #--- Layout

    my $repo_main_sz = Wx::FlexGridSizer->new( 4, 1, 5, 5 );

    #-- Top

    my $repo_top_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Query list ', ),
        wxVERTICAL, );

    $repo_top_sz->Add( $self->{_list}, 1, wxEXPAND, 3 );

    #-- Middle

    my $repo_mid_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Header ', ), wxVERTICAL, );

    my $repo_mid_fgs = Wx::FlexGridSizer->new( 4, 2, 5, 10 );

    $repo_mid_fgs->Add( $repo_lbl1, 0, wxTOP | wxLEFT,  5 );
    $repo_mid_fgs->Add( $self->{title},    0, wxEXPAND | wxTOP, 5 );

    $repo_mid_fgs->Add( $repo_lbl2, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{filename}, 0, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl3, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{output},   0, wxEXPAND, 0 );

    $repo_mid_fgs->Add( $repo_lbl4, 0, wxLEFT,   5 );
    $repo_mid_fgs->Add( $self->{sheet},    0, wxEXPAND, 0 );

    # $repo_mid_fgs->AddGrowableRow( 1, 1 );
    $repo_mid_fgs->AddGrowableCol( 1, 1 );

    $repo_mid_sz->Add( $repo_mid_fgs, 0, wxALL | wxGROW, 0 );

    #-- Bottom

    my $repo_bot_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p1}, -1, ' Description ', ),
        wxVERTICAL, );

    $repo_bot_sz->Add( $self->{description}, 1, wxEXPAND );

    #--

    $repo_main_sz->Add( $repo_top_sz, 0, wxALL | wxGROW, 5 );
    $repo_main_sz->Add( $repo_mid_sz, 0, wxALL | wxGROW, 5 );
    $repo_main_sz->Add( $repo_bot_sz, 0, wxALL | wxGROW, 5 );

    $repo_main_sz->AddGrowableRow(0);
    $repo_main_sz->AddGrowableCol(0);

    $self->{_nb}{p1}->SetSizer($repo_main_sz);
}

=head2 create_para_page

Create the parameters page (tab) on the notebook

=cut

sub create_para_page {

    my $self = shift;

    #-- Controls

    my $para_tit_lbl1 =
      Wx::StaticText->new( $self->{_nb}{p2}, -1, 'Label', );
    my $para_tit_lbl2 =
      Wx::StaticText->new( $self->{_nb}{p2}, -1, 'Description', );
    my $para_tit_lbl3 =
      Wx::StaticText->new( $self->{_nb}{p2}, -1, 'Value', );

    my $para_lbl1 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value1', );
    $self->{descr1} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value1} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl2 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value2', );
    $self->{descr2} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value2} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl3 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value3', );
    $self->{descr3} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value3} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl4 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value4', );
    $self->{descr4} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value4} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    my $para_lbl5 = Wx::StaticText->new( $self->{_nb}{p2}, -1, 'value5', );
    $self->{descr5} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ 170, -1 ], );
    $self->{value5} =
      Wx::TextCtrl->new( $self->{_nb}{p2}, -1, q{}, [ -1, -1 ], [ -1, -1 ], );

    #-- Layout

    my $para_fgs = Wx::FlexGridSizer->new( 6, 3, 5, 10 );

    $para_fgs->Add( $para_tit_lbl1, 0, wxTOP | wxLEFT, 10 );
    $para_fgs->Add( $para_tit_lbl2, 0, wxTOP | wxLEFT, 10 );
    $para_fgs->Add( $para_tit_lbl3, 0, wxTOP | wxLEFT, 10 );

    $para_fgs->Add( $para_lbl1, 0, wxTOP | wxLEFT,   5 );
    $para_fgs->Add( $self->{descr1},   0, wxEXPAND | wxTOP, 5 );
    $para_fgs->Add( $self->{value1},   1, wxEXPAND | wxTOP, 5 );

    $para_fgs->Add( $para_lbl2, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr2},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value2},   1, wxEXPAND, 0 );

    $para_fgs->Add( $para_lbl3, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr3},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value3},   1, wxEXPAND, 0 );

    $para_fgs->Add( $para_lbl4, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr4},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value4},   1, wxEXPAND, 0 );

    $para_fgs->Add( $para_lbl5, 0, wxLEFT,   5 );
    $para_fgs->Add( $self->{descr5},   1, wxEXPAND, 0 );
    $para_fgs->Add( $self->{value5},   1, wxEXPAND, 0 );

    $para_fgs->AddGrowableCol(2);

    my $para_main_sz = Wx::BoxSizer->new(wxHORIZONTAL);

    my $para_sbs =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p2}, -1, ' Parameters ', ), wxVERTICAL,
      );

    $para_sbs->Add( $para_fgs, 0, wxEXPAND, 3 );
    $para_main_sz->Add( $para_sbs, 1, wxALL | wxGROW, 5 );

    $self->{_nb}{p2}->SetSizer( $para_main_sz );
}

=head2 create_sql_page

Create the SQL page (tab) on the notebook

=cut

sub create_sql_page {
    my $self = shift;

    #--- SQL Tab (page)

    #-- Controls

    my $sql_sb = Wx::StaticBox->new( $self->{_nb}{p3}, -1, ' SQL ', );

    $self->{sql} = Wx::StyledTextCtrl->new(
        $self->{_nb}{p3},
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
    );

    $self->{sql}->SetMarginType( 1, wxSTC_MARGIN_SYMBOL );
    $self->{sql}->SetMarginWidth( 1, 10 );
    $self->{sql}->StyleSetFont( wxSTC_STYLE_DEFAULT,
        Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxNORMAL, 0, 'Courier New' ) );
    # $self->{sql}->SetLexer( wxSTC_LEX_SQL );
    $self->{sql}->SetLexer( wxSTC_LEX_MSSQL );
    # List0
    $self->{sql}->SetKeyWords(0,
    q{all and any ascending between by cast collate containing day
descending distinct escape exists from full group having in
index inner into is join left like merge month natural not
null on order outer plan right select singular some sort starting
transaction union upper user where with year} );
    # List1
    $self->{sql}->SetKeyWords(1,
    q{blob char decimal integer number varchar} );
    # List2 Only for MSSQL?
    $self->{sql}->SetKeyWords(2,
    q{avg count gen_id max min sum} );
    $self->{sql}->SetTabWidth(4);
    $self->{sql}->SetIndent(4);
    $self->{sql}->SetHighlightGuide(4);

    $self->{sql}->StyleClearAll();

    # Global default styles for all languages
    $self->{sql}->StyleSetSpec( wxSTC_STYLE_BRACELIGHT,
                                "fore:#FFFFFF,back:#0000FF,bold" );
    $self->{sql}->StyleSetSpec( wxSTC_STYLE_BRACEBAD,
                                "fore:#000000,back:#FF0000,bold" );

    # MSSQL - works with wxSTC_LEX_MSSQL
    $self->{sql}->StyleSetSpec(0, "fore:#000000");            #*Default
    $self->{sql}->StyleSetSpec(1, "fore:#ff7373,italic");     #*Comment
    $self->{sql}->StyleSetSpec(2, "fore:#007f7f,italic");     #*Commentline
    $self->{sql}->StyleSetSpec(3, "fore:#0000ff");            #*Number
    $self->{sql}->StyleSetSpec(4, "fore:#dca3a3");            #*Singlequoted
    $self->{sql}->StyleSetSpec(5, "fore:#3f3f3f");            #*Operation
    $self->{sql}->StyleSetSpec(6, "fore:#000000");            #*Identifier
    $self->{sql}->StyleSetSpec(7, "fore:#8cd1d3");            #*@-Variable
    $self->{sql}->StyleSetSpec(8, "fore:#705050");            #*Doublequoted
    $self->{sql}->StyleSetSpec(9, "fore:#dfaf8f");            #*List0
    $self->{sql}->StyleSetSpec(10,"fore:#94c0f3");            #*List1
    $self->{sql}->StyleSetSpec(11,"fore:#705030");            #*List2

    #-- Layout

    my $sql_main_sz = Wx::BoxSizer->new(wxVERTICAL);
    my $sql_sbs = Wx::StaticBoxSizer->new( $sql_sb, wxHORIZONTAL, );

    $sql_sbs->Add( $self->{sql}, 1, wxEXPAND, 0 );
    $sql_main_sz->Add( $sql_sbs, 1, wxALL | wxEXPAND, 5 );

    $self->{_nb}{p3}->SetSizer( $sql_main_sz );
}

=head2 create_config_page

Create the configuration info page (tab) on the notebook.

Using the MySQL lexer for very basic syntax highlighting. This was
chosen because permits the definition of 3 custom lists. For this
purpose three key word lists are defined with a keyword in each. B<EE>
is for error, B<II> for information and B<WW> for warning. Words in
the lists must be lower case.

=cut

sub create_config_page {
    my $self = shift;

    #-- Controls

    #- Log text control

    $self->{log} = Wx::StyledTextCtrl->new(
        $self->{_nb}{p4},
        -1,
        [ -1, -1 ],
        [ -1, -1 ],
    );

    # $self->{log}->SetUseHorizontalScrollBar(0); # turn off scrollbars
    # $self->{log}->SetUseVerticalScrollBar(0);
    $self->{log}->SetMarginType( 1, wxSTC_MARGIN_SYMBOL );
    $self->{log}->SetMarginWidth( 1, 10 );
    $self->{log}->StyleSetFont( wxSTC_STYLE_DEFAULT,
        Wx::Font->new( 10, wxDEFAULT, wxNORMAL, wxNORMAL, 0, 'Courier New' ) );
    $self->{log}->SetLexer( wxSTC_LEX_MSSQL );
    $self->{log}->SetWrapMode(wxSTC_WRAP_NONE); # wxSTC_WRAP_WORD

    # List0
    $self->{log}->SetKeyWords(0, q{ii} );
    # List1
    $self->{log}->SetKeyWords(1, q{ee} );
    # List2

    $self->{log}->SetKeyWords(2, q{ww} );
    $self->{log}->SetTabWidth(4);
    $self->{log}->SetIndent(4);
    $self->{log}->SetHighlightGuide(4);
    $self->{log}->StyleClearAll();

    # MSSQL - works with wxSTC_LEX_MSSQL
    $self->{log}->StyleSetSpec(4, "fore:#dca3a3");            #*Singlequoted
    $self->{log}->StyleSetSpec(8, "fore:#705050");            #*Doublequoted
    $self->{log}->StyleSetSpec(9, "fore:#00ff00");            #*List0
    $self->{log}->StyleSetSpec(10,"fore:#ff0000");            #*List1
    $self->{log}->StyleSetSpec(11,"fore:#0000ff");            #*List2

    #--- Layout

    my $conf_main_sz = Wx::FlexGridSizer->new( 2, 1, 5, 5 );

    #-- Top - removed :)

    #-- Bottom

    my $conf_bot_sz =
      Wx::StaticBoxSizer->new(
        Wx::StaticBox->new( $self->{_nb}{p4}, -1, ' Log ', ),
        wxVERTICAL, );

    $conf_bot_sz->Add( $self->{log}, 1, wxEXPAND );

    #--

    # $conf_main_sz->Add( $conf_top_sz, 0, wxALL | wxGROW, 5 );
    $conf_main_sz->Add( $conf_bot_sz, 0, wxALL | wxGROW, 5 );

    $conf_main_sz->AddGrowableRow(0);
    $conf_main_sz->AddGrowableCol(0);

    $self->{_nb}{p4}->SetSizer($conf_main_sz);
}

=head2 dialog_popup

Define a dialog popup.

=cut

sub dialog_popup {
    my ( $self, $msgtype, $msg ) = @_;
    if ( $msgtype eq 'Error' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_ERROR, $self )
    }
    elsif ( $msgtype eq 'Warning' ) {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_WARNING, $self )
    }
    else {
        Wx::MessageBox( $msg, $msgtype, wxOK|wxICON_INFORMATION, $self )
    }
}

=head2 action_confirmed

Yes - No message dialog.

=cut

sub action_confirmed {
    my ( $self, $msg ) = @_;

    my( $answer ) =  Wx::MessageBox(
        $msg,
        'Confirm',
        Wx::wxYES_NO(),  # if you use Wx ':everything', it's wxYES_NO
        undef,           # you needn't pass anything, much less $frame
     );

     if( $answer == Wx::wxYES() ) {
         return 1;
     }
}

=head2 get_toolbar_btn_id

Return a toolbar button ID when we know the its name.

=cut

sub get_toolbar_btn_id {
    my ($self, $name) = @_;

    return $self->{_tb}{_tb_btn}{$name};
}

=head2 get_toolbar

Return the toolbar handler.

=cut

sub get_toolbar {
    my $self = shift;

    return $self->{_tb};
}

=head2 get_choice_default

Return the choice default option, the first element in the array.

=cut

sub get_choice_default {
    my $self = shift;

    return $self->{_tb}->get_choice_options(0);
}

=head2 get_listcontrol

Return the list control handler.

=cut

sub get_listcontrol {
    my $self = shift;

    return $self->{_list};
}

=head2 get_controls_list

Return a AoH with information regarding the controls from the list page.

=cut

sub get_controls_list {
    my $self = shift;

    return [
        { title       => [ $self->{title}      , 'normal'  , 'white'     ] },
        { filename    => [ $self->{filename}   , 'disabled', 'lightgrey' ] },
        { output      => [ $self->{output}     , 'normal'  , 'white'     ] },
        { sheet       => [ $self->{sheet}      , 'normal'  , 'white'     ] },
        { description => [ $self->{description}, 'normal'  , 'white'     ] },
    ];
}

=head2 get_controls_para

Return a AoH with information regarding the controls from the parameters page.

=cut

sub get_controls_para {
    my $self = shift;

    return [
        { descr1 => [ $self->{descr1}, 'normal'  , 'white' ] },
        { value1 => [ $self->{value1}, 'normal'  , 'white' ] },
        { descr2 => [ $self->{descr2}, 'normal'  , 'white' ] },
        { value2 => [ $self->{value2}, 'normal'  , 'white' ] },
        { descr3 => [ $self->{descr3}, 'normal'  , 'white' ] },
        { value3 => [ $self->{value3}, 'normal'  , 'white' ] },
        { descr4 => [ $self->{descr4}, 'normal'  , 'white' ] },
        { value4 => [ $self->{value4}, 'normal'  , 'white' ] },
        { descr5 => [ $self->{descr5}, 'normal'  , 'white' ] },
        { value5 => [ $self->{value5}, 'normal'  , 'white' ] },
    ];
}

=head2 get_controls_sql

Return a AoH with information regarding the controls from the SQL page.

=cut

sub get_controls_sql {
    my $self = shift;

    return [
        { sql => [ $self->{sql}, 'normal'  , 'white' ] },
    ];
}

=head2 get_controls_conf

Return a AoH with information regarding the controls from the
configurations page.

None at this time.

=cut

sub get_controls_conf {
    my $self = shift;

    return [];
}

=head2 get_control_by_name

Return the control instance by name.

=cut

sub get_control_by_name {
    my ($self, $name) = @_;

    return $self->{$name},
}

=head2 get_list_text

Return text item from list control row and col

=cut

sub get_list_text {
    my ($self, $row, $col) = @_;

    return $self->get_listcontrol->GetItemText( $row, $col );
}

=head2 set_list_text

Set text item from list control row and col

=cut

sub set_list_text {
    my ($self, $row, $col, $text) = @_;
    $self->get_listcontrol->SetItemText( $row, $col, $text );
}

=head2 set_list_data

Set item data from list control

=cut

sub set_list_data {
    my ($self, $item, $data_href) = @_;
    $self->get_listcontrol->SetItemData( $item, $data_href );
}

=head2 get_list_data

Return item data from list control

=cut

sub get_list_data {
    my ($self, $item) = @_;
    return $self->get_listcontrol->GetItemData( $item );
}

=head2 list_item_select_first

Select the first item in list

=cut

sub list_item_select_first {
    my ($self) = @_;

    my $items_no = $self->get_list_max_index();

    if ( $items_no > 0 ) {
        $self->get_listcontrol->Select(0, 1);
    }
}

=head2 list_item_select_last

Select the last item in list

=cut

sub list_item_select_last {
    my ($self) = @_;

    my $items_no = $self->get_list_max_index();
    my $idx = $items_no - 1;
    $self->get_listcontrol->Select( $idx, 1 );
    $self->get_listcontrol->EnsureVisible($idx);
}

=head2 get_list_max_index

Return the max index from the list control

=cut

sub get_list_max_index {
    my ($self) = @_;

    return $self->get_listcontrol->GetItemCount();
}

=head2 get_list_selected_index

Return the selected index from the list control

=cut

sub get_list_selected_index {
    my ($self) = @_;

    return $self->get_listcontrol->GetSelection();
}

=head2 list_item_insert

Insert item in list control

=cut

sub list_item_insert {
    my ( $self, $indice, $nrcrt, $title, $file ) = @_;

    # Remember, always sort by index before insert!
    $self->list_string_item_insert($indice);
    $self->set_list_text($indice, 0, $nrcrt);
    $self->set_list_text($indice, 1, $title);
    # Set data
    $self->set_list_data($indice, $file );
}

=head2 list_string_item_insert

Insert string item in list control

=cut

sub list_string_item_insert {
    my ($self, $indice) = @_;
    $self->get_listcontrol->InsertStringItem( $indice, 'dummy' );
}

=head2 list_item_clear

Delete list control item

=cut

sub list_item_clear {
    my ($self, $item) = @_;
    $self->get_listcontrol->DeleteItem($item);
}

=head2 list_item_clear_all

Delete all list control items

=cut

sub list_item_clear_all {
    my ($self) = @_;
    $self->get_listcontrol->DeleteAllItems;
}

=head2 log_config_options

Log configuration options with data from the Config module

=cut

sub log_config_options {
    my $self = shift;

    my $cfg  = Tpda3::Config->instance();
    my $path = $cfg->output;

    while ( my ( $key, $value ) = each( %{$path} ) ) {
        $self->log_msg("II Config: '$key' set to '$value'");
    }
}

=head2 list_populate_all

Populate all other pages except the configuration page

=cut

sub list_populate_all {

    my ($self) = @_;

    my $titles = $self->_model->get_list_data();

    # Clear list
    $self->list_item_clear_all();

    # Populate list in sorted order
    my @titles = sort { $a <=> $b } keys %{$titles};
    foreach my $indice ( @titles ) {
        my $nrcrt = $titles->{$indice}[0];
        my $title = $titles->{$indice}[1];
        my $file  = $titles->{$indice}[2];
        # print "$nrcrt -> $title\n";
        $self->list_item_insert($indice, $nrcrt, $title, $file);
    }

    # Set item 0 selected on start
    $self->list_item_select_first();
}

=head2 list_populate_item

Add new item in list control and select the last item

=cut

sub list_populate_item {
    my ( $self, $rec ) = @_;

    my $idx = $self->get_list_max_index();
    $self->list_item_insert( $idx, $idx + 1, $rec->{title}, $rec->{file} );
    $self->list_item_select_last();
}

=head2 list_remove_item

Remove item from list control and select the first item

=cut

sub list_remove_item {
    my $self = shift;

    my $sel_item = $self->get_list_selected_index();
    my $file_fqn = $self->get_list_data($sel_item);

    # Remove from list
    $self->list_item_clear($sel_item);

    # Set item 0 selected
    $self->list_item_select_first();

    return $file_fqn;
}

=head2 get_detail_data

Return detail data from the selected list control item

=cut

sub get_detail_data {
    my $self = shift;

    my $sel_item  = $self->get_list_selected_index();
    my $file_fqn  = $self->get_list_data($sel_item);
    my $ddata_ref = $self->_model->get_detail_data($file_fqn);

    return ( $ddata_ref, $file_fqn, $sel_item );
}

=head2 controls_populate

Populate controls with data from XML

=cut

sub controls_populate {
    my $self = shift;

    my ($ddata_ref, $file_fqn) = $self->get_detail_data();

    my $cfg  = Tpda3::Config->instance();
    my $qdfpath =$cfg->cfgpath;

    #-- Header
    # Write in the control the filename, remove path config path
    my $file_rel = File::Spec->abs2rel( $file_fqn, $qdfpath ) ;

    # Add real path to control
    $ddata_ref->{header}{filename} = $file_rel;
    $self->controls_write_page('list', $ddata_ref->{header} );

    #-- Parameters
    my $params = $self->params_data_to_hash( $ddata_ref->{parameters} );
    $self->controls_write_page('para', $params );

    #-- SQL
    $self->control_set_value( 'sql', $ddata_ref->{body}{sql} );

    #--- Highlight SQL parameters
    $self->toggle_sql_replace();
}

=head2 toggle_sql_replace

Toggle sql replace

=cut

sub toggle_sql_replace {
    my $self = shift;

    #- Detail data
    my ( $ddata, $file_fqn ) = $self->get_detail_data();

    #-- Parameters
    my $params = $self->params_data_to_hash( $ddata->{parameters} );

    if ( $self->_model->is_editmode ) {
        $self->control_set_value( 'sql', $ddata->{body}{sql} );
    }
    else {
        $self->control_replace_sql_text( $ddata->{body}{sql}, $params );
    }
}

=head2 control_replace_sql_text

Replace sql text control

=cut

sub control_replace_sql_text {
    my ($self, $sqltext, $params) = @_;

    my ($newtext, $positions) = $self->string_replace_pos($sqltext, $params);

    # Write new text to control
    $self->control_set_value('sql', $newtext);
}

=head2 status_msg

Set status message

=cut

sub status_msg {
    my ( $self, $msg ) = @_;

    my ( $text, $sb_id ) = split ':', $msg; # Work around until I learn how
                                            # to pass other parameters ;)

    $sb_id = 0 if $sb_id !~ m{[0-9]}; # Fix for when file name contains ':'
    $self->get_statusbar()->SetStatusText( $text, $sb_id );
}

=head2 dialog_msg

Set dialog message

=cut

sub dialog_msg {
    my ( $self, $message ) = @_;

    $self->dialog_popup( 'Error', $message );
}

=head2 log_msg

Set log message

=cut

sub log_msg {
    my ( $self, $message ) = @_;

    $self->control_append_value( 'log', $message );
}

=head2 process_sql

Get the sql text string from the QDF file, prepare it for execution.

=cut

sub process_sql {
    my $self = shift;

    my ($data, $file_fqn, $item) = $self->get_detail_data();

    my ($bind, $sqltext) = $self->string_replace_for_run(
        $data->{body}{sql},
        $data->{parameters},
    );

    if ($bind and $sqltext) {
        $self->_model->run_export(
            $data->{header}{output}, $bind, $sqltext);
    }
}

=head2 params_data_to_hash

Transform data in simple hash reference format

TODO: Move this to model?

=cut

sub params_data_to_hash {
    my ($self, $params) = @_;

    my $parameters;
    foreach my $parameter ( @{ $params->{parameter} } ) {
        my $id = $parameter->{id};
        if ($id) {
            $parameters->{"value$id"} = $parameter->{value};
            $parameters->{"descr$id"} = $parameter->{descr};
        }
    }

    return $parameters;
}

=head2 string_replace_pos

Replace string pos

=cut

sub string_replace_pos {

    my ($self, $text, $params) = @_;

    my @strpos;

    while (my ($key, $value) = each ( %{$params} ) ) {
        next unless $key =~ m{value[0-9]}; # Skip 'descr'

        # Replace  text and return the strpos
        $text =~ s/($key)/$value/pm;
        my $pos = $-[0];
        push(@strpos, [ $pos, $key, $value ]);
    }

    # Sorted by $pos
    my @sortedpos = sort { $a->[0] <=> $b->[0] } @strpos;

    return ($text, \@sortedpos);
}

=head2 string_replace_for_run

Prepare sql text string for execution.  Replace the 'valueN' string
with with '?'.  Create an array of parameter values, used for binding.

Need to check if number of parameters match number of 'valueN' strings
in SQL statement text and print an error if not.

=cut

sub string_replace_for_run {
    my ( $self, $sqltext, $params ) = @_;

    my @bind;
    foreach my $rec ( @{ $params->{parameter} } ) {
        my $value = $rec->{value};
        my $p_num = $rec->{id};         # Parameter number for bind_param
        my $var   = 'value' . $p_num;
        unless ( $sqltext =~ s/($var)/\?/pm ) {
            $self->log_msg("EE Parameter mismatch, to few parameters in SQL");
            return;
        }

        push( @bind, [ $p_num, $value ] );
    }

    # Check for remaining not substituted 'value[0-9]' in SQL
    if ( $sqltext =~ m{(value[0-9])}pm ) {
        $self->log_msg("EE Parameter mismatch, to many parameters in SQL");
        return;
    }

    return ( \@bind, $sqltext );
}

=head2 control_set_value

Set new value for a controll

=cut

sub control_set_value {
    my ($self, $name, $value) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->ClearAll;
    $ctrl->AppendText($value);
    $ctrl->AppendText( "\n" );
    $ctrl->Colourise( 0, $ctrl->GetTextLength );

}

=head2 control_set_value

Set new value for a controll

=cut

sub control_append_value {
    my ($self, $name, $value) = @_;

    return unless defined $value;

    my $ctrl = $self->get_control_by_name($name);

    $ctrl->AppendText($value);
    $ctrl->AppendText( "\n" );
    $ctrl->Colourise( 0, $ctrl->GetTextLength );
}

=head2 controls_write_page

Write all controls on page with data

=cut

sub controls_write_page {
    my ($self, $page, $data) = @_;

    # Get controls name and object from $page
    my $get = 'get_controls_'.$page;
    my $controls = $self->$get();

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {

            my $value = $data->{$name};

            # Cleanup value
            if ( defined $value ) {
                $value =~ s/\n$//mg;    # Multiline
            }
            else {
                $value = q{};           # Empty
            }

            $control->{$name}[0]->SetValue($value);
        }
    }
}

=head2 controls_read_page

Read all controls from page and return an array reference

=cut

sub controls_read_page {
    my ( $self, $page ) = @_;

    # Get controls name and object from $page
    my $get      = 'get_controls_' . $page;
    my $controls = $self->$get();
    my @records;

    foreach my $control ( @{$controls} ) {
        foreach my $name ( keys %{$control} ) {
            my $value;
            if ($page ne 'sql') {
                $value = $control->{$name}[0]->GetValue();
            }
            else {
                $value = $control->{$name}[0]->GetText();
            }

            push(@records, { $name => $value } ) if ($name and $value);
        }
    }

    return \@records;
}

=head2 save_query_def

Save query definition file

=cut

sub save_query_def {
    my $self = shift;

    my (undef, $file_fqn, $item) = $self->get_detail_data();

    my $head = $self->controls_read_page('list');
    my $para = $self->controls_read_page('para');
    my $body = $self->controls_read_page('sql');

    my $new_title =
      $self->_model->save_query_def( $file_fqn, $head, $para, $body );

    # Update title in list
    $self->set_list_text( $item, 1, $new_title );
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 - 2011 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation.

=cut

1; # End of Tpda3::Wx::View
