#############################################################################
## Name: XRCCustom.pm
## Purpose: wxWindows' XML Resources demo
## Author: Mattia Barbon
## Created: 25/08/2003
## RCS-ID: $Id: XRCCustom.pm,v 1.1 2003/07/25 20:36:10 mbarbon Exp $
## Copyright: (c) 2003 Mattia Barbon
## Licence: This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself
#############################################################################

package Tpda3::Wx::Factory;

use base 'Wx::XmlSubclassFactory';

sub DESTROY { }    # work around another bug

sub Create {
    return $_[1]->new;
}

1;
