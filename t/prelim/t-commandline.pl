#!perl -w   -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Win32::CommandLine;

print 'command_line = '.Win32::CommandLine::command_line()."\n";

