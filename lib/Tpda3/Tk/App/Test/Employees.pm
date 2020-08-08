package Tpda3::Tk::App::Test::Employees;

# ABSTRACT: The Tpda3::App::Test::Employees screen

use strict;
use warnings;
use utf8;

use Tk::widgets qw(DateEntry JComboBox);

use base q{Tpda3::Tk::Screen};

use POSIX qw (strftime);

use Tpda3::Utils;

=head1 NAME

Tpda3::Tk::App::Test::Employees screen.

=cut

=head1 SYNOPSIS

    require Tpda3::App::Test::Employees;

    my $scr = Tpda3::App::Test::Employees->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    my $rec_page  = $nb->page_widget('rec');
    my $det_page  = $nb->page_widget('det');
    $self->{view} = $nb->toplevel;
    $self->{bg}   = $self->{view}->cget('-background');

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    my $date_format = $self->{scrcfg}->app_dateformat();

    #- For DateEntry day names
    my $daynames = [qw(D L Ma Mi J V S)];

    #- Frame - top

    my $frm_top = $rec_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Employee',
        -labelside  => 'acrosstop',
    )->pack(
        -padx  => 5,
        -pady  => 5,
        -ipadx  => 5,
        -ipady  => 5,
    );

    my $f1d = 120;              # distance from left

    #- Employeenumber (employeenumber)

    my $lemployeenumber = $frm_top->Label( -text => 'Number' );
    $lemployeenumber->form(
        -top  => [ %0, 5 ],
        -left => [ %0, 5 ],
    );

    my $eemployeenumber = $frm_top->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eemployeenumber->form(
        -top  => [ '&', $lemployeenumber, 0 ],
        -left => [ %0,  $f1d ],
    );

    # Font
    my $my_font = $eemployeenumber->cget('-font');


    #- Lastname (lastname)

    my $llastname = $frm_top->Label( -text => 'Last name' );
    $llastname->form(
        -top     => [ $lemployeenumber, 8 ],
        -left    => [ %0, 5 ],
    );

    my $elastname = $frm_top->MEntry(
        -width              => 35,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $elastname->form(
        -top  => [ '&', $llastname, 0 ],
        -left => [ %0,  $f1d ],
    );


    #- Firstname (firstname)

    my $lfirstname = $frm_top->Label( -text => 'First name' );
    $lfirstname->form(
        -top     => [ $llastname, 8 ],
        -left    => [ %0, 5 ],
    );

    my $efirstname = $frm_top->MEntry(
        -width              => 35,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $efirstname->form(
        -top  => [ '&', $lfirstname, 0 ],
        -left => [ %0,  $f1d ],
    );


    #- Extension (extension)

    my $lextension = $frm_top->Label( -text => 'Extension' );
    $lextension->form(
        -top     => [ $lfirstname, 8 ],
        -left    => [ %0, 5 ],
    );

    my $eextension = $frm_top->MEntry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eextension->form(
        -top  => [ '&', $lextension, 0 ],
        -left => [ %0,  $f1d ],
    );


    #- Email (email)

    my $lemail = $frm_top->Label( -text => 'E-mail' );
    $lemail->form(
        -top     => [ $lextension, 8 ],
        -left    => [ %0, 5 ],
    );

    my $eemail = $frm_top->MEntry(
        -width              => 35,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eemail->form(
        -top  => [ '&', $lemail, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- office

    my $loffice = $frm_top->Label( -text => 'Office' );
    $loffice->form(
        -top     => [ $lemail, 8 ],
        -left    => [ %0, 5 ],
    );

    my $eoffice = $frm_top->MEntry(
        -width              => 28,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eoffice->form(
        -top  => [ '&', $loffice, 0 ],
        -left => [ %0,  $f1d ],
    );

    #-+ Officecode

    my $eofficecode = $frm_top->MEntry(
        -width              => 5,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eofficecode->form(
        -top   => [ '&', $loffice, 0 ],
        -right => [ '&', $eemail, 0 ],
    );


    #- Reportsto (reportsto)

    my $lreportsto = $frm_top->Label( -text => 'Reports to' );
    $lreportsto->form(
        -top     => [ $loffice, 8 ],
        -left    => [ %0, 5 ],
    );

    my $ereportsto = $frm_top->MEntry(
        -width              => 5,
        -validate => 'key',
        -vcmd     => sub {
            $self->validate_reportsto(@_);
        },
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ereportsto->form(
        -top  => [ '&', $lreportsto, 0 ],
        -left => [ %0,  $f1d ],
    );

    #+- boss

    my $eboss = $frm_top->MEntry(
        -width              => 28,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eboss->form(
        -top   => [ '&', $lreportsto, 0 ],
        -right => [ '&', $eemail, 0 ],
    );


    #- Jobtitle (jobtitle)

    my $ljobtitle = $frm_top->Label( -text => 'Job title' );
    $ljobtitle->form(
        -top     => [ $lreportsto, 8 ],
        -left    => [ %0, 5 ],
    );

    my $ejobtitle = $frm_top->MEntry(
        -width              => 30,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ejobtitle->form(
        -top  => [ '&', $ljobtitle, 0 ],
        -left => [ %0,  $f1d ],
    );



    # Entry objects: var_asoc, var_obiect.
    # The configurations are defined in 'employees.conf'.
    $self->{controls} = {
        employeenumber => [ undef, $eemployeenumber ],
        lastname       => [ undef, $elastname ],
        firstname      => [ undef, $efirstname ],
        extension      => [ undef, $eextension ],
        email          => [ undef, $eemail ],
        office         => [ undef, $eoffice ],
        officecode     => [ undef, $eofficecode ],
        reportsto      => [ undef, $ereportsto ],
        boss           => [ undef, $eboss ],
        jobtitle       => [ undef, $ejobtitle ],
    };

    return;
}

sub view {
    my $self = shift;
    return $self->{view};
}

sub update_lookup_field {
    my ($self, $field, $value) = @_;
    $self->view->control_write_e(
        $field, $self->{controls}{$field}, $value );
    return;
}

=head2 validate_reportsto

Validate reportsto and lookup descriere.

=cut

sub validate_reportsto {
    my ( $self, $myvar ) = @_;
    return 1 if $self->view->model->is_mode('find');
    my $maxlen  = 6;
    my $pattern = qr/^\p{IsDigit}{0,$maxlen}$/;
    if ( $myvar =~ m/$pattern/ ) {
        $self->lookup_reportsto($myvar);
        return 1;
    }
    else {
        return 0;
    }
}

=head2 lookup_reportsto

Lookup descriere in the database and write to the control.

=cut

sub lookup_reportsto {
    my ( $self, $reportsto ) = @_;
    unless ($reportsto) {
        $self->update_lookup_field( 'boss', '' );
        return;
    }

    my $para = {};
    $para->{table} = 'v_employees';
    $para->{field} = 'boss';

    my $prefix;
    if ( length($reportsto) < 4 ) {
        $self->update_lookup_field( 'boss', '?' );
        return;
    }
    elsif ( length($reportsto) == 4 ) {
        $para->{where}{reportsto} = $reportsto;
    }
    elsif ( length($reportsto) > 4 ) {
        $self->update_lookup_field( 'boss', '?' );
        return;
    }
    my $descr_text = $self->view->lookup_description($para);
    if ($descr_text) {
        $self->update_lookup_field( 'boss', $descr_text );
    }
    else {
        $self->update_lookup_field( 'boss', '?' );
    }
    return;
}


=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2020

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::App::Test::Employees
