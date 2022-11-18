package Tpda3::Types;

# ABSTRACT: Tpda3 custom types

use 5.010;
use strict;
use warnings;
use utf8;
use Type::Library 0.040 -base, -declare => qw(
    DateRange
    DateSimple
    ExcelWriterXLSX
    ListCompare
    MailOutlook
    MailOutlookMessage
    MustacheSimple
    Path
    TimeMoment
    Tpda3Compare
    Tpda3Contr
    Tpda3Screen
    Tpda3Config
    Tpda3Hollyday
    Tpda3Record
    Tpda3View
    TkToplevel
    URIdb
    XLSXWorksheet
);
use Type::Utils -all;
use Types::Standard -types;

# Inherit standard types.
BEGIN { extends "Types::Standard" };

# Other
class_type DateSimple,         { class => 'Date::Simple' };
class_type DateRange,          { class => 'Date::Range' };
class_type Path,               { class => 'Path::Tiny' };
class_type MailOutlook,        { class => 'Mail::Outlook' };
class_type MailOutlookMessage, { class => 'Mail::Outlook::Message' };
class_type MustacheSimple,     { class => 'Mustache::Simple' };
class_type TimeMoment,         { class => 'Time::Moment' };
class_type ListCompare,        { class => 'List::Compare' };
class_type URIdb,              { class => 'URI::db' };
class_type ExcelWriterXLSX,    { class => 'Excel::Writer::XLSX' };
class_type TkToplevel,    { class => 'Tk::Toplevel' };
class_type Tpda3Config,   { class => 'Tpda3::Config' };
class_type Tpda3Hollyday, { class => 'Tpda3::Hollyday' };
class_type Tpda3Compare,  { class => 'Tpda3::Model::Update::Compare' };
class_type Tpda3Record ,  { class => 'Tpda3::Model::Table::Record' };
class_type Tpda3View ,    { class => 'Tpda3::Tk::View' };
class_type Tpda3Contr,    { class => 'Tpda3::Tk::Controller' };
class_type Tpda3Screen,   { class => 'Tpda3::Tk::Screen' };
class_type XLSXWorksheet, { class => 'Excel::Writer::XLSX::Worksheet' };

1;
