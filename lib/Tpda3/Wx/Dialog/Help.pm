package Tpda3::Wx::Dialog::Help;

# ABSTRACT: Help dialog

use strict;
use warnings;

use Wx qw(wxHF_FLATTOOLBAR wxHF_DEFAULTSTYLE wxOK wxICON_INFORMATION);
use Wx::Event qw(EVT_BUTTON);
use Wx::Html;
use Wx::Help;
use Wx::FS;

# very important for HTB to work
Wx::FileSystem::AddHandler( new Wx::ZipFSHandler );

require Tpda3::Config::Utils;

sub new {

    my ($class, $gui) = @_;

    my $self = {};
    $self->{view} = $gui;

    return bless( $self, $class );
}

sub show_html_help {
    my ($self, $guide_file) = @_;

    $self->{help} = Wx::HtmlHelpController->new(
        wxHF_FLATTOOLBAR | wxHF_DEFAULTSTYLE );

    my $htb_file = Tpda3::Config::Utils->get_doc_file_by_name($guide_file);
    unless ( -f $htb_file ) {
        Wx::MessageBox(
            "Can't locate the help file:\n '$guide_file'",
            'Info', wxOK | wxICON_INFORMATION,
            $self->{view},
        );

        return;
    }

    $self->{help}->AddBook( $htb_file, 1 );
    $self->{help}->DisplayContents;
}

1;

=head2 new

Constructor method.

=head2 show_html_help

Parameter: .htb file.

=cut
