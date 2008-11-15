# $Id: OS2.pm,v 0.3.2.299 ( r72:5578a4d14542 [mercurial] ) 2008/11/14 10:23:03 rivy $

package Devel::AssertOS::OS2;

use Devel::CheckOS;

$VERSION = '1.0';

sub os_is { $^O eq 'os2' ? 1 : 0; }

Devel::CheckOS::die_unsupported() unless(os_is());

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2008 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
