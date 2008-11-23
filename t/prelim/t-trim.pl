#!perl -w
#tab:4

use strict;
use warnings;

use File::Glob;
use File::DosGlob;

use lib qw{ lib blib/arch };
use Win32::CommandLine ();

$| = 1;     # autoflush for warnings to be in sequence with regular output

#@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine; };
#
#foreach (@ARGV)
#    {
#    print "`$_`\n";
#    }
#
#print "==1=\n";
#print join ("\n", grep { /^(?!isa|bootstrap|dl_load_flags|qv)[^_][a-zA-Z_]*[a-z]+[a-zA-Z_]*$/ } keys %Win32::CommandLine::);
#print "\n";
#
#print "==2=\n";
#print join ("\n", keys %Win32::CommandLine::);
#print "\n";
#
#print "==3=\n";
#my @a = keys %Win32::CommandLine::;
#print ":@a:\n";
#
#print "==3=\n";
my @b = ( 'Test', 'TRUE' );
print ":@b:\n";

#sub _lc{
#    # trim balanced outer quotes
#    print '[_lc]wantarray = ' . (defined wantarray ? (wantarray ? "true" : "false") : 'undef') . "\n";
#    print '[_lc]@_ = ' . @_ . "\n";
#    @_ = @_ ? @_ : $_ if defined wantarray;  # if non-void context,
#
#    for (@_ ? @_ : $_)
#        {
#        $_ = lc;
#        }
#
#    return wantarray ? @_ : "@_";
#    }

#sub _t{
#    ## trim balanced outer quotes
#    # lowercase
#    my ($opt_ref);
#    $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  # pop last argument only if it's a HASH reference
#    my %opt = (
#        't_re' => '.',
#        );
#    if ($opt_ref) { for (keys %{$opt_ref}) { if (defined $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown argument '$_' to for function ".(caller(0))[3]; return; } } }
#
#    my $t = $opt{'trim_re'};
#
#    if ( !@_ ) { warn "Useless use of ". (caller(0))[3] . " with no arguments ()\n"; return; }
##    if ( !@_ && !defined(wantarray) ) { Carp::carp "Useless use of ". (caller(0))[3] . " with no arguments in void return context"; return; }
#
#    my $arg_ref;
#    $arg_ref = \@_;
#    $arg_ref = [ @_ ] if defined wantarray;     # break aliasing if non-void return context
#
#    for ( @{$arg_ref} ) { s/(.)/lc($1)/eg; }
#
#    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
#    }


#print "==4=\n";
#my $t = 'TRue';
#_lc $t;
#print $t."\n";
#
#print "==5=\n";
#_lc @b;
#print "@b" . "\n";
##print lc('TEST', 'T', 'dC') ."\n";

use Data::Dump qw( dump );

$_ = '  TeSTing (from $)';
@b = ();
@b = ('TesT', ' anOTHER tesT   ');
print "\n";
print 'main:$_:'.dump($_)."\n";
print 'main:@b:'.dump(@b)."\n";
#for my $b ( @b ? @b : 'NONE')
#    {
#    print 'main:$b:'.dump($b)."\n";
#    }

#print "[\@b = (@b): lc \@b = ".lc(@b)."\n";

print "==6=\n";

#print "_t()\n";
#_t();

my $z;
my @z;

#print 'z = _t($_)'.' ';
#$z = _t($_);
#print "= $z\n";
#
#print 'z = _t()'.' ';
#$z = _t();
#print "= $z\n";
#
print "\n";
print '@z = _ltrim(@b, " a ")'."\n";
@z = Win32::CommandLine::_ltrim(@b, " a ");
print 'main:@z:'.dump(@z)."\n";
print 'main:@b:'.dump(@b)."\n";

print "\n";
print '@z = _ltrim()'."\n";
@z = Win32::CommandLine::_ltrim();
print 'main:@z:'.dump(@z)."\n";
print 'main:$_:'.dump($_)."\n";

#@b = ();
print "\n";
print '$z = _ltrim(@b)'."\n";
$z = Win32::CommandLine::_ltrim(@b);
print 'main:$z:'.dump($z)."\n";

print "\n";
print '$z = _ltrim(@b, {\'trim_re\'=>\'[\stT]+\'})'."\n";
$z = Win32::CommandLine::_ltrim(@b, {'trim_re' => '[\stT]+'});
print 'main:$z:'.dump($z)."\n";

print "\n";
print '$z = _ltrim(@b, {\'trim\'=>\'[\stT]+\'})'."\n";
$z = Win32::CommandLine::_ltrim(@b, {'trim' => '[\stT]+'});
print 'main:$z:'.dump($z)."\n";

#print '_ltrim({\'trim_re\'=>\'[\stT]+\'})'."\n";
#Win32::CommandLine::_ltrim({'trim_re' => '(?i:[\stes]+)'});
#print 'main:$_:'.dump($_)."\n";

print "\n";
print 'main:$_:'.dump($_)."\n";
print '_ltrim()'."\n";
Win32::CommandLine::_ltrim;
print 'main:$_:'.dump($_)."\n";

print "==7=\n";
@b = ();
@b = ('TesT', ' anOTHER tesT   ');

print "\n";
print 'main:@b:'.dump(@b)."\n";
print '_ltrim(@b)'."\n";
Win32::CommandLine::_ltrim(@b);
print 'main:@b:'.dump(@b)."\n";

print "\n";
print 'main:$_:'.dump($_)."\n";
print '&_ltrim'."\n";
&Win32::CommandLine::_ltrim;
print 'main:$_:'.dump($_)."\n";

print "\n";
print 'main:$_:'.dump($_)."\n";
print '_ltrim'."\n";
Win32::CommandLine::_ltrim;
print 'main:$_:'.dump($_)."\n";

@b = ();

print "\n";
print 'main:@b:'.dump(@b)."\n";
print '_ltrim(@b)'."\n";
Win32::CommandLine::_ltrim(@b);
print 'main:@b:'.dump(@b)."\n";

#print '_ltrim(" t")'.' ';
#Win32::CommandLine::_ltrim(" t");
#print "\n";

#print '_ltrim(())'.' ';
#print Win32::CommandLine::_ltrim( () );
#print "\n";

#print Win32::CommandLine::_ltrim(<STDIN>);
