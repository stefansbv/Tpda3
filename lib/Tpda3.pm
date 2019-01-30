package Tpda3;

# ABSTRACT: Tiny Perl Database Application 3

use 5.010001;
use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use Locale::TextDomain::UTF8 'Tpda3';
require Tpda3::Config;

sub new {
    my ( $class, $args ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init($args);
    return $self;
}

sub _init {
    my ( $self, $args ) = @_;
    my $cfg = Tpda3::Config->instance($args);
    my $widgetset = $cfg->application->{widgetset};
    unless ($widgetset) {
        die "The required configuration not found: 'widgetset'";
    }
    if ( uc $widgetset eq q{WX} ) {
        require Tpda3::Wx::Controller;
        $self->{gui} = Tpda3::Wx::Controller->new();
    }
    elsif ( uc $widgetset eq q{TK} ) {
        require Tpda3::Tk::Controller;
        $self->{gui} = Tpda3::Tk::Controller->new();
    }
    else {
        die "Unknown widget set!: '$widgetset'";
    }
    $self->{gui}->start();    # stuff to run at start
    return;
}

sub run {
    my $self = shift;
    $self->{gui}{_app}->MainLoop();
    return;
}

1;

=head1 SYNOPSIS

B<Tpda3> is a classic desktop database application framework.

    use Tpda3;

    #-- Minimal options:

    my $opts = {};

    $opts->{user} = $user;
    $opts->{pass} = $pass;
    $opts->{cfname} = $cfname;

    Tpda3->new( $opts )->run;

=head1 DESCRIPTION

Tpda3 is a classic desktop database application framework and
run-time, written in Perl.  The graphical user interface is based on
PerlTk. It supports the CUBRID, Firebird, PostgreSQL and SQLite RDBMS.

There is also an early, experimental, graphical user interface based
on wxPerl.

B<Tpda3> should work on any OS where Perl and the required
dependencies can be installed, but currently it's only tested on
GNU/Linux and Windows (XP and 7).  Feedback and patches for other OSs
is welcome.

Tpda3 is the successor of TPDA and, hopefully, has a much better API
implementation, Tpda3 follows the Model View Controller (MVC)
architecture pattern.  The look and the user interface functionality
of Tpda3 is almost the same as of TPDA, with some minor improvements.

This project has two components, the B<Tpda3> I<runtime> and the
B<Tpda3> I<applications>.

The I<runtime> is responsible for loading the configuration files,
connect and work with the database, create the main application
I<Frame> with a menubar, toolbar and statusbar.

The B<Tpda3> I<application> is a collection of screens.  At run time,
after the main I<Frame> is created, the user can select a I<Screen>
from the menu.  Then the I<runtime> will create a I<NoteBook> with two
pages named I<Record> and I<List>. In the I<Record> page will create
the controls of the selected I<Screen>.  The I<List> page holds a list
control widget used for the search results.  A I<Details> page can
also be used with the proper configuration options.

This application is designed to be flexible, as a consequence the
configurations are quite complex.

Another new feature of Tpda3 is the suuport for I<wxPerl>.  The
application configuration file, located in the F<.tpda3> tree in F<<
apps/<appname>/etc/application.yml >>, has a (new) option named
I<widgetset> with Tk and Wx as valid values (case insensitive).

This is the main module of the application.

=head2 new

Constructor method.

=head2 _init

Initialize the configurations module and create the PerlTk or the
wxPerl application instance.

=head2 run

Execute the application.

=head1 ACKNOWLEDGEMENTS

The implementation of the Wx interface is heavily based on the work
of Mark Dootson.

The implementation of the localization code is based on the work of
David E. Wheeler.

Thank You!

=cut
