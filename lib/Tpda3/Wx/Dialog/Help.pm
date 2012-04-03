package Tpda3::Wx::Dialog::Help;

use strict;
use warnings;

use Wx::Html;
use Wx::Help;
use Wx::FS;

use Wx qw(wxHF_FLATTOOLBAR wxHF_DEFAULTSTYLE);
use Wx::Event qw(EVT_BUTTON);

# very important for HTB to work
Wx::FileSystem::AddHandler( new Wx::ZipFSHandler );

sub new {

=head2 new

Constructor method

=cut

    my $class = shift;

    my $self = {};

    return bless( $self, $class );
}

sub show_html_help {
    my ($self) = @_;

    $self->{help} = Wx::HtmlHelpController->new(
        wxHF_FLATTOOLBAR | wxHF_DEFAULTSTYLE );

    my $cfg = Tpda3::Config->instance();

    my $htb_file = $cfg->get_help_file('guide.htb');

    $self->{help}->AddBook( $htb_file, 1 );
    $self->{help}->DisplayContents;
}

1;
