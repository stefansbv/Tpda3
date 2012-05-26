package Tpda3::Codings;

use strict;
use warnings;

=head1 NAME

Tpda3::Codings - The Codings

=head1 VERSION

Version 0.52

=cut

our $VERSION = 0.52;

=head1 SYNOPSIS

   use Tpda3::Codings;

   my $codes = Tpda3::Codings->new();

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ($class, $model) = @_;

    my $self = {
        _code  => {},
        _model => $model,
    };

    bless( $self, $class );

    return $self;
}

=head2 get_coding_init

Return the data structure used to fill the list of choices (options)
of widgets like Tk::JComboBox and experimental for Tk::MatchingBE.

Initialize the datastructure from the database when needed.  The
procedure is: check key, if exists return a hash ref else query the
database.

Add the default value defined in configuration, if not exists in table.

Different labels for different widgets:

 -name and -value for JCombobox
 label and  value for MatchingBE

=cut

sub get_coding_init {
    my ( $self, $field, $para, $widget ) = @_;

    my $label_label
        # widget type       key name
        = $widget eq 'l' ? 'label'
        : $widget eq 'm' ? '-name'
        :                  '-name'
        ;

    my $value_label
        # widget type       key name
        = $widget eq 'l' ? 'value'
        : $widget eq 'm' ? '-value'
        :                  '-value'
        ;

    if ( !exists $self->{_code}{$field} ) {

        # Query database table
        $self->{_code}{$field} = $self->{_model}
            ->tbl_dict_query( $para, $label_label, $value_label );
    }

    if (   $para->{default} =~ m{null}i
        or $para->{default} eq q{} )    # compatible with old configs
    {

        # Add and empty option
        unshift @{ $self->{_code}{$field} },
            {
            $label_label => ' ',
            $value_label => ' ',
            };
    }

    return $self->{_code}{$field};
}

=head2 get_coding

Return codes.

=cut

sub get_coding {
    my ( $self, $field, $val ) = @_;

    return $self->{_code}{$field}{$val};
}

1;
