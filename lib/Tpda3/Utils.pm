package Tpda3::Utils;

# ABSTRACT: Various utility functions

use 5.010;
use strict;
use warnings;
use utf8;

use Encode qw(is_utf8 decode);
use Try::Tiny;
use YAML::Tiny;
use Path::Tiny;
use File::HomeDir;
use DateTime;
use DateTime::Locale;

require Tpda3::Exceptions;

my $transformations = {
    datey   => \&year_month,
    dateym  => \&year_month,
    datemy  => \&year_month,
    dateiso => \&date_string,
    dateamb => \&date_string,
    nothing => \&do_error,
    error   => \&do_error,
};

sub trim {
    my ( $self, @text ) = @_;
    for (@text) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @text : "@text";
}

sub dateentry_parse_date {
    my ( $self, $format, $date ) = @_;

    return unless $date;

    my ( $y, $m, $d );

    # Default date style format
    $format = 'iso' unless $format;

  SWITCH: for ($format) {
        /^$/ && warn "Error in 'dateentry_parse_date'\n";
        /german|dmy/i && do {
            ( $d, $m, $y )
                = ( $date =~ m{([0-9]{2})\.([0-9]{2})\.([0-9]{4})} );
            last SWITCH;
        };
        /iso/i && do {
            ( $y, $m, $d )
                = ( $date =~ m{([0-9]{4})\-([0-9]{2})\-([0-9]{2})} );
            last SWITCH;
        };
        /usa/i && do {
            ( $m, $d, $y )
                = ( $date =~ m{([0-9]{2})\/([0-9]{2})\/([0-9]{4})} );
            last SWITCH;
        };

        # DEFAULT
        warn "Wrong date format: $format\n";
    }

    return ( $y, $m, $d );
}

sub dateentry_format_date {
    my ( $self, $format, $y, $m, $d ) = @_;

    return unless $y and $m and $d;

    my $date;

    # Default date style format
    $format = 'iso' unless $format;

  SWITCH: for ($format) {
        /^$/ && warn "Error in 'dateentry_format_date'\n";
        /german|dmy/i && do {
            $date = sprintf( "%02d.%02d.%4d", $d, $m, $y );
            last SWITCH;
        };
        /iso/i && do {
            $date = sprintf( "%4d-%02d-%02d", $y, $m, $d );
            last SWITCH;
        };
        /usa/i && do {
            $date = sprintf( "%02d/%02d/%4d", $m, $d, $y );
            last SWITCH;
        };

        # DEFAULT
        warn "Unknown date format: $format\n";
    }

    return $date;
}

sub sort_hash_by_id {
    my ( $self, $attribs ) = @_;

    foreach my $k ( keys %{$attribs} ) {
        if ( !exists $attribs->{$k}{id} ) {
            warn "sort_hash_by_id: '$k' does not have an 'id' attribute\n";
        }
    }

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return wantarray ? @attribs : \@attribs;
}

sub filter_hash_by_keyvalue {
    my ($self, $attribs, $key, $value) = @_;

    #- Keep only key and id for sorting and filter by key -> value
    my %temp = map {
        $attribs->{$_}{$key} eq $value
            ? ( $_ => $attribs->{$_}{id} )
            : ()
    } keys %{$attribs};

    #- Sort with  ST by id
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return \@attribs;
}

sub quote4like {
    my ( $self, $text, $option ) = @_;

    if ( $text =~ m{%}xm ) {
        return $text;
    }
    else {
        $option ||= q{C};    # default 'C'
        return qq{$text%} if $option eq 'S';    # (S)tart with
        return qq{%$text} if $option eq 'E';    # (E)nd with
        return qq{%$text%};                     # (C)ontains
    }
}

sub special_ops {
    my $self = shift;
    return [
        {   regex   => qr/^extractyear$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('extract (year from')
                    . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },
        {   regex   => qr/^extractmonth$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('extract (month from')
                    . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },

        # special op for PostgreSQL syntax: extract date from timestamp
        {   regex   => qr/^extractdate$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('date(') . $field . ')'
                    . " = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },

        # special op for PostgreSQL syntax: field SIMILAR TO 'regex1'
        {   regex   => qr/^similar_to$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = "$label "
                    . $self->_sqlcase('similar to ')
                    . " $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },
        # special op for PostgreSQL syntax: field ~ 'regex1'
        {   regex   => qr/^match$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = "$label "
                    . $self->_sqlcase('~ ')
                    . " $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },
    ];
}

sub process_date_string {
    my ( $self, $search_input ) = @_;

    my $dtype = $self->identify_date_string($search_input);
    my $where = $self->format_query($dtype);

    return $where;
}

sub identify_date_string {
    my ( $self, $is ) = @_;

    #              When date format is...                  Type is ...
    my $rez =
          $is eq q{}                                    ? "nothing"
        : $is =~ m{^(\d{4})[./-](\d{2})[\.\/-](\d{2})$} ? "dateiso:$is"
        : $is =~ m{^(\d{2})[./-](\d{2})[\.\/-](\d{4})$} ? "dateamb:$is"
        : $is =~ m{^(\d{4})[./-](\d{1,2})$}             ? "dateym:$1:$2"
        : $is =~ m{^(\d{1,2})[./-](\d{4})$}             ? "datemy:$2:$1"
        : $is =~ m{^(\d{4})$}                           ? "datey:$1"
        :                                                 "dataerr:$is";
    $rez =~ s{[./]}{-}g;
    return $rez;
}

sub format_query {
    my ( $self, $type ) = @_;

    my ( $directive, $year, $month ) = split /:/, $type, 3;

    my $where;
    if ( exists $transformations->{$directive} ) {
        $where = $transformations->{$directive}->( $year, $month );
    }
    else {

        # warn "Unrecognized directive '$directive'";
        $where = $directive;
    }

    return $where;
}

sub year_month {
    my ( $year, $month ) = @_;
    my $where = {};
    $where->{-extractyear}  = [$year]  if ($year);
    $where->{-extractmonth} = [$month] if ($month);
    return $where;
}

sub date_string {
    my ($date) = @_;
    my $where = {};
    $where->{-extractdate} = [$date] if ($date);
    return $where;
}

sub do_error {
    my ($date) = @_;
    print "String not identified or empty!\n";
    return;
}

sub ins_underline_mark {
    my ( $self, $label, $position ) = @_;
    die "Wrong parameters for 'ins_underline_mark'"
        unless $label and defined $position;
    substr( $label, $position, 0 ) = '&';
    return $label;
}

sub deaccent {
    my ( $self, $text ) = @_;
    $text =~ tr/ăĂãÃâÂîÎșȘşŞțȚţŢ/aAaAaAiIsSsStTtT/;
    return $text;
}

sub check_path {
    my ($self, $path) = @_;
    die "check_path: A 'path' parameter is required\n" unless $path;
    unless ($path and -d $path) {
        Exception::IO::PathNotFound->throw(
            pathname => $path,
            message  => 'Path not found',
        );
    }
    return;
}

sub check_file {
    my ($self, $file) = @_;
    die "check_file: A 'file' parameter is required\n" unless $file;
    unless ($file and -f $file) {
        Exception::IO::FileNotFound->throw(
            filename => $file,
            message  => 'File not found',
        );
    }
    return;
}

sub decode_unless_utf {
    my ($self, $value) = @_;
    $value = decode( 'utf8', $value ) unless is_utf8($value);
    return $value;
}

# TODO: should be sub categorize_message
sub parse_message {
    my ($self, $text) = @_;
    (my $type, $text) = split /#/, $text, 2;

    # Allow empty type
    unless ($text) {
        $text = $type;
        $type = q{};
    }
    my $color;
  SWITCH: {
        $type eq 'error' && do { $color = 'darkred';   last SWITCH; };
        $type eq 'info'  && do { $color = 'darkgreen'; last SWITCH; };
        $type eq 'warn'  && do { $color = 'orange';    last SWITCH; };
        $color = 'black';                    # default
    }
    # return ($text, $color, $type);
    return ($text, $color);
}

sub read_yaml {
    my ($self, $file) = @_;
    unless ( -f $file ) {
        Exception::IO::FileNotFound->throw(
            message  => 'Configuration file not found.',
            pathname => $file,
        );
    }
    my $yaml = try { YAML::Tiny->read($file) }
    catch {
        Exception::Config::YAML->throw(
            usermsg => 'Failed to load the resource file.',
            logmsg  => $_,
        );
    };
    return $yaml->[0];
}

sub write_yaml {
    my ($self, $file, $data) = @_;
    my $yaml = YAML::Tiny->new($data);
    try   { $yaml->write($file) }
    catch {
        Exception::Config::YAML->throw(
            usermsg => "Failed to write resource file '$file'",
            logmsg  => $_,
        );
    };
    return;
}

sub get_sqlitedb_filename {
    my ($self, $dbname) = @_;
    die "get_testdb_filename: A 'dbname' parameter is required\n" unless $dbname;
    my $dbpath = path $dbname;
    if ( $dbpath->is_absolute ) {
        return $dbpath->stringify;
    }
    $dbname .= '.db' unless $dbname =~ m{\.db$}i;
    return path( File::HomeDir->my_data, $dbname )->stringify;
}

sub dt_today {
    my ( $self, $locale ) = @_;
    $locale //= 'ro';    # the default locale is ro ;)
    return DateTime->now( locale => $locale );
}

sub month_names {
    my ( $self, $format, $locale ) = @_;
    my $today = $self->dt_today($locale);
    my $arr_ref =
        $format eq 'abbrev' ? $today->locale->month_stand_alone_abbreviated
      : $format eq 'narrow' ? $today->locale->month_stand_alone_narrow
      : $format eq 'wide'   ? $today->locale->month_stand_alone_wide
      :                    undef;
    die "'$format' is not a valid format, try: abbrev, narrow or wide\n"
      unless $arr_ref;
    return $arr_ref;
}

sub day_names {
    my ( $self, $format, $locale ) = @_;
    my $today = $self->dt_today($locale);
    my $arr_ref =
        $format eq 'abbrev' ? $today->locale->day_stand_alone_abbreviated
      : $format eq 'narrow' ? $today->locale->day_stand_alone_narrow
      : $format eq 'wide'   ? $today->locale->day_stand_alone_wide
      :                    undef;
    die "'$format' is not a valid format, try: abbrev, narrow or wide\n"
      unless $arr_ref;
    return $arr_ref;
}

sub get_month_name {
    my ( $self, $month, $format, $locale ) = @_;
    die "get_month_name: wrong month parameter: $month"
      if $month <= 0 or $month > 12;
    my $months = $self->month_names( $format, $locale );
    my $i      = $month - 1;
    return $months->[$i];
}

sub get_day_name {
    my ( $self, $day, $format, $locale ) = @_;
    die "get_day_name: wrong day parameter: $day"
      if $day <= 0 or $day > 7;
    my $days = $self->day_names( $format, $locale );
    my $i    = $day - 1;
    return $days->[$i];
}

1;

__END__

=head1 SYNOPSIS

Various utility functions used by all other modules.

    use Tpda3::Utils;

    my $foo = Tpda3::Utils->function_name();

=head2 transformations

Global hash reference.

=head2 trim

Trim strings or arrays.

=head2 dateentry_parse_date

Parse date for Tk::DateEntry.

=head2 dateentry_format_date

Format date for Tk::DateEntry.

=head2 sort_hash_by_id

Use ST to sort hash by value (Id), returns an array or an array
reference of the sorted items.

=head2 filter_hash_by_keyvalue

Use ST to sort hash by value (Id), returns an array ref of the sorted
items, filtered by key => value.

=head2 quote4like

Surround text with '%', by default, for SQL LIKE.  An optional second
parameter can be used for 'start with' or 'end with' sintax.

If option parameter is not 'C', 'S', or 'E', 'C' is assumed.

=head2 special_ops

SQL::Abstract special ops for EXTRACT (YEAR|MONTH FROM field) = word1.

Note: Not compatible with SQLite.

=head2 process_date_string

Try to identify the input string as full date, year or month and year
and return a where clause.

=head2 identify_date_string

Identify format of the I<input> I<string> from a date type field and
return the matched pieces in a string as separate values where the
separator is the colon character.

=head2 format_query

Execute the appropriate sub and return the where attributes Choices
are defined in the I<$transformations> hash.

=head2 year_month

Case of string identified as year and/or month.

=head2 date_string

Case of string identified as full date string, regardless of the format.

=head2 do_error

Case of string not identified or empty.

=head2 ins_underline_mark

Insert ampersand character for underline mark in menu.

=head2 deaccent

Remove Romanian accented characters.

TODO: Add other accented characters, especially for German and Hungarian.

=head2 check_path

Check a path and throw an exception if not valid.

=head2 check_file

Check a file path and throw an exception if not valid.

=head2 decode_unless_utf

Decode a string if is not utf8.

=head2 parse_message

Parse a message text in the following format:

   error#Message text
   info#Message text
   warn#Message text

and return the coresponding mesage text and color.

=head3 read_yaml

=head3 write_yaml

=head2 get_sqlitedb_filename

Returns the absolute path and file name of the SQLite database.
file.

If the configured path is an absolute path and a file name, retur it,
else make a path from the user data path (as returned by
File::HomeDir), and the configured path and file name.

=head2 dt_today

Returns a DateTime object instance for the 'ro' locale, the default or
the locale name provided with the parameter;

=head2 month_names

Returns an ordered array reference with the month names from a locale.
January is at index 0.

The parameters are:

format: (abbrev, narrow or wide), required

locale: all names suported by L<DateTime::Locale> module, the default
        is 'ro'

=head3 day_names

=head3 get_month_name

=head3 get_day_name

=cut
