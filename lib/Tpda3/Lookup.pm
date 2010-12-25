package Tpda3::Lookup;

use strict;
use warnings;

use Tpda3::Tk::Dialog::Search;

sub new {
    my $type = shift;

    my $self = {};

    # $self->{tpda} = shift;    # Tpda object

    bless( $self, $type );

    $self->{dlgc} = Tpda3::Tk::Dialog::Search->new(
        # $self,
        # $self->{tpda}->{conf},
    );

    return $self;
}

sub lookup {
    my ($self, $gui, $table, $filter, $wid_group) = @_;

    my ( $record_ref, $field_ref )
        = $self->{dlgc}->run_dialog( $gui, $table, $filter );

    # Just get rid of :[0-9]+ (field width) from the field array
    s{:[0-9]+}{} foreach @{$field_ref};

    return unless ref $record_ref;     # No results?

    my $nr_col = scalar @{$field_ref}; # print "nr_col $nr_col\n";

    for ( my $i = 0; $i < $nr_col; $i++ ) {

        # Entry objects hash
        my $eobjc = $self->{tpda}->get_eobj('rec');

        # Table field name
        my $tbl_fld_name  = $field_ref->[$i];    # print "F: $field\n";
        my $tbl_fld_value = $record_ref->[$i];   # print "V: $value\n";
        # Screen field name
        my $scr_fld_name;

        # If empty %{$wid_group}, it means that field names on the
        # search table match the field names on screen and they apears
        # only once, do use $field_ref as is
        # Else
        # use the field names from the parameter, make new $field_ref
        if ( defined $wid_group ) {

            # Skip fields not used in screen
            next if ! exists $wid_group->{$tbl_fld_name};

            $scr_fld_name = $wid_group->{$tbl_fld_name};
        }
        else {

            # Skip fields not used in screen
            next unless ref( $eobjc->{$tbl_fld_name} ) =~ /ARRAY/i;

            $scr_fld_name = $tbl_fld_name;
        }

        # print "\ntbl_fld_name: $tbl_fld_name\n";
        # print "scr_fld_name: $scr_fld_name\n\n";

        # Trim spaces ### make a sub in Utils for this ???
        if ( defined $tbl_fld_value ) {
            $tbl_fld_value =~ s/^\s+//;
            $tbl_fld_value =~ s/\s+$//;
        }

        # Write results to screen widgets
        $self->{tpda}->screen_write_field( $scr_fld_name, $tbl_fld_value );

        $eobjc->{$scr_fld_name}[3]->focusNext;
    }

    return;
}

1;
