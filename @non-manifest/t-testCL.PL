#!/usr/bin/perl -w

# URLref: http://win32.perl.org/wiki/index.php?title=Talk:Main_Page#Fun_with_File_Associations [@2011-04-15.1408@ http://www.webcitation.org/5xyBeCjI2]
# URLref: http://stackoverflow.com/questions/444388/how-can-i-pass-command-line-arguments-via-file-association-in-vista-64 [@2011-04-15.1407@ http://www.webcitation.org/5xyBiRb9A]
# URLref: http://filext.com/faq/broken_exe_association.php [@2011-04-15.1407@ http://www.webcitation.org/5xyBPhQ2x]
# URLref: http://support.microsoft.com/kb/257592 [@2011-04-15.1413@ http://www.webcitation.org/5xyByI4jS ]

# Machine settings for file extensions are in [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.EXTENSION] (which seem to be aliases of [HKEY_CLASSES_ROOT\.EXTENSION])
# User settings for file extensions are in [HKEY_CURRENT_USER\Software\Classes\.EXTENSION], overriding the machine level settings in 
# Explorer settings for file extensions are in [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.EXTENSION], and override/trump both above settings/locations
# ... it looks like the explorer settings can be removed and they will be re-created correctly, as needed

# FTYPE and ASSOC seem to change the HKLM/HKCR entries (not the USER level), at least from an ADMIN console (check regarding low privilege consoles with UAC on)

# URLref: http://stackoverflow.com/questions/2681878/associate-file-extension-with-application [@2011-04-15.1445@ http://www.webcitation.org/5xyE4HJec ]
# This SO question/answer has a solution which works for general file extension and can be applied to the .PL extension.

use strict;
my $num_args = $#ARGV + 1;
print "${num_args} arguments read\n";
print "$^X\n" # recommended addition by Alias
