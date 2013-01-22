package Tpda3::Config::Screen;

use strict;
use warnings;

use File::Spec::Functions;
use Config::General;
use Data::Diver qw( Dive );
use Data::Printer;

require Tpda3::Config;

sub new {
    my ( $class, $args ) = @_;

    my $self = {
        _cfg => Tpda3::Config->instance(),
    };

    bless $self, $class;

    $self->{_scr} = $self->load_conf($args);

    return $self;
}

=head2 _cfg

Return config instance variable

=cut

sub cfg {
    my $self = shift;

    return $self->{_cfg};
}

sub load_conf {
    my ($self, $name) = @_;

    my $config_file = $self->cfg->config_scr_file_name($name);
    my $config_href = $self->cfg->config_load_file($config_file);

    return $config_href;
}

sub screen {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'screen', @args );
}

sub defaultreport {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'defaultreport', @args );
}

sub defaultdocument {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'defaultdocument', @args );
}

sub lists_ds {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'lists_ds', @args );
}

sub list_header {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'list_header', @args );
}

sub bindings {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'bindings', @args );
}

sub tablebindings {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'tablebindings', @args );
}

sub deptable {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'deptable', @args );
}

sub scrtoolbar {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'scrtoolbar', @args );
}

sub toolbar {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'toolbar', @args );
}

sub maintable {
    my ($self, @args) = @_;

    return Dive( $self->{_scr}, 'maintable', @args );
}

### other

=head2 has_screen_detail

Return true if the main screen has details screen.

=cut

sub has_screen_detail {
    my $self = shift;

    my $screen = $self->screen('detail');
    if ( ref $screen ) {
        return scalar keys %{$screen};
    }
    else {
        return $screen;
    }
}

=head2 screen_toolbars

Return the C<scrtoolbar> configuration data structure defined for the
curren screen.

If there is only one toolbar button then return it as an array reference.

=cut

sub _screen_toolbars {
    my ( $self, $name ) = @_;

    die "Screen toolbar name is required" unless $name;

    my $scrtb = $self->scrtoolbar($name);
    my @toolbars;
    if (ref($scrtb) eq 'ARRAY') {
        @toolbars = @{$scrtb};
    }
    else {
        @toolbars = ($scrtb);
    }

    return \@toolbars;
}

=head2 scr_toolbar_names

Return the toolbar names and their method names configured for the
current screen.

=cut

sub scr_toolbar_names {
    my ($self, $name) = @_;

    my $attribs = $self->_screen_toolbars($name);
    my @tbnames = map { $_->{name} } @{$attribs};
    my %tbattrs = map { $_->{name} => $_->{method} } @{$attribs};

    return (\@tbnames, \%tbattrs);
}

=head2 scr_toolbar_groups

The scrtoolbar are grouped with a label that used to be the same as
the TM label, because each group was considered to be attached to a TM
widget.  Now screen toolbars can be defined separately.

This method returns the labels.

=cut

sub scr_toolbar_groups {
    my $self = shift;

    my @group_labels = keys %{ $self->scrtoolbar };

    return \@group_labels;
}

=head2 dep_table_header_info

Return the table header configuration data structure bound to the
related Tk::TableMatrix widget.

=cut

sub dep_table_header_info {
    my ( $self, $tm_ds ) = @_;

    die "TM parameter missing!" unless $tm_ds;

    my $href = {};

    $href->{columns}       = $self->deptable( $tm_ds, 'columns' );
    $href->{selectorcol}   = $self->deptable( $tm_ds, 'selectorcol' );
    $href->{colstretch}    = $self->deptable( $tm_ds, 'colstretch' );
    $href->{selectorstyle} = $self->deptable( $tm_ds, 'selectorstyle' );

    return $href;
}

###TODO: refactor?

=head2 get_defaultreport_file

Return default report path and file, used by the print tool button.

=cut

sub get_defaultreport_file {
    my $self = shift;

    return catfile( $self->cfg->configdir, 'rep',
        $self->defaultreport('file') )
        if $self->defaultreport('file');

    return;
}

=head2 get_defaultdocument_file

Return default document description, used by the generate tool button,
as the baloon label.

=cut

sub get_defaultdocument_file {
    my $self = shift;

    return catfile(
        $self->cfg->config_tex_path('model'),
        $self->defaultdocument('file') )
            if $self->defaultdocument('file');

    return;
}

=head2 app_dateformat

Date format configuration.

=cut

sub app_dateformat {
    my $self = shift;

    return $self->cfg->application->{dateformat} || 'iso';
}

=head2 app_toolbar_attribs

Return the toolbar configuration data structure defined for the
current application, in the etc/toolbar.yml file.

=cut

sub app_toolbar_attribs {
    my $self = shift;

    return $self->cfg->toolbar2;
}

=head2 dep_table_has_selectorcol

Return true if the dependent table has I<selector column> attribute
set.

=cut

sub dep_table_has_selectorcol {
    my ( $self, $tm_ds ) = @_;

    die "TM parameter missing!" unless $tm_ds;

    my $sc = $self->deptable($tm_ds, 'selectorcol');

    return if $sc eq 'none';

    return $sc;
}

1;
