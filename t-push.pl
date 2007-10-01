#!perl -w
#tab:4

use strict;
use warnings;

use Data::Dumper::Simple;

my @argv = ();

#push @argv, [ ];
push @{ $argv[ scalar(@argv) ] }, { token => 'tok_2', glob => 1 };
push @{ $argv[ scalar(@argv) ] }, { token => 'tok_1', glob => 1 };
#push @argv, [ { token => "tok_1", glob => 1 } ];
#push @argv, [ { token => "tok_1", glob => 1 } ];
#push @argv, [ "tok_2", 1 ];

warn Dumper(@argv);