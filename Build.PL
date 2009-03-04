#!perl -w   -- -*- tab-width: 4; mode: perl -*-
#$Id: Build.PL,v 0.1.3.13338 ( r48:8b89ede3eda6 [mercurial] ) 2009/03/04 05:11:38 rivy $

## no critic ( CodeLayout::RequireTidyCode CodeLayout::ProhibitHardTabs CodeLayout::ProhibitParensWithBuiltins RequireExtendedFormatting RequireLineBoundaryMatching )

## TODO?: remove the '_' from the version for output dist files (>> will this cause a problem for PPM or CPAN with some sort of version mismatch between filename and META.yml
## TODO?: .. or just remove VERSION code generating the alpha '_' within the version? does it matter? does the '_' interfere with version comparisons on CPAN?

## TODO: check on the broken install for ppm for perl 5.10 => <ARCHITECTURE NAME="MSWin32-x86-multi-thread-118.53" /> instead of the correct <ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.10" />

## TODO: flesh out stub documentation for additional custom actions

use strict;
use warnings;
use 5.006; ##	# v5.5: for AUTHOR and ABSTRACT in Makefile.PL; v5.6: for 'our', three-argument open, and indirect filehandles

use English qw( -no_match_vars ); ##	# long Perl built-on variable names ['-no_match_vars' avoids regex performance penalty]

# VERSION: major.minor.release[.build]]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# generate VERSION from $Version: 0.1.3.13338 $ SCS tag
# $defaultVERSION 	:: used to make the VERSION code resilient vs missing keyword expansion
# $generate_alphas	:: 0 => generate normal versions; true/non-0 => generate alpha version strings for ODD numbered minor versions
use version qw(); our $VERSION; { my $defaultVERSION = '0.1.3'; my $generate_alphas = 0; $VERSION = ( $defaultVERSION, qw( $Version: 0.1.3.13338 $ ))[-2]; if ($generate_alphas) { $VERSION =~ /(\d+)\.(\d+)\.(\d+)(?:\.)?(.*)/; $VERSION = $1.'.'.$2.((!$4&&($2%2))?'_':'.').$3.($4?((($2%2)?'_':'.').$4):q{}); $VERSION = version::qv( $VERSION ); }; } ## no critic ( ProhibitCallsToUnexportedSubs ProhibitCaptureWithoutTest ProhibitNoisyQuotes ProhibitMixedCaseVars ProhibitMagicNumbers)

##- config
my %config;

# config may be done via a local config file [OPTIONAL] 	## allows Build.PL to be maintained seperately and used without changes between modules)
$config{'rc_filename'} = 'Build.PL.config'; ##	# configuration file name (in .NET style)

# Module::Build DEFAULTS [ ** DO NOT CHANGE, use the Build.PL.config to set the values ]
$config{'module_name'} = undef;
$config{'dist_author'} = undef;
$config{'license'} = undef;							# must be chosen by the author of the module/distribution
$config{'requires_href'} = {};						# module requirements (no obvious default)
$config{'recommends'} = {};							# module recommendations (no obvious default)
$config{'build_requires_href'} = { 'perl' => 5.006, 'version' => 0, 'File::Which' => 0, 'File::Spec::Functions' => 0, 'File::Spec' => 0, 'File::Basename' => 0 };	# basic module requirements for Build.PL
$config{'sign'} = 'true';							# always sign the module, if possible
$config{'create_readme'} = 'true';					# create README from module pod
$config{'create_makefile_pl'} = 'passthrough';		# passthrough Makefile.PL (will download/install Module::Build from CPAN if missing)
$config{'recursive_test_files'} = undef;			# scan the ./t directory recursively for *.t perl files to execute during testing (no obvious default)
$config{'script_files_aref'} = [];					# alternate script/executable file locations
$config{'pm_files_href'} = {};						# alternate PM file locations [to help with MakeMaker transitions]
$config{'pod_files_href'} = {};						# alternate POD file locations [to help with MakeMaker transitions]
$config{'xs_files_href'} = {};						# alternate XS file locations [to help with MakeMaker transitions]
$config{'PL_files_href'} = {};						# perl files to execute during processing (usually to generated .PL files from templates)
$config{'c_source'} = undef;						# c source files to compile
$config{'config_href'} = {};						# modify Config.pm values for the build
$config{'add_to_cleanup_aref'} = [ 'MANIFEST.bak', 'Makefile', 'Makefile.old', 'pm_to_blib' ];		# extra files to clean up during "build clean"
$config{'add_to_realcleanup_aref'} = [];			# extra files to clean up during "build realclean"
$config{'assert_os_aref'} = [];						# limit build to specific OS types (default = [] => any OS)
$config{'custom_code_href'} = {};					# custom code overrides from config
$config{'custom_ENV_href'} = { '_module_name' => '' };	# custom environment overrides (set before each dispatch) [default $ENV{_module_name} == $config{'module_name'} [SET after Build.PL.config is read, unless set within config]]

# helper variables
$config{'lib_path'} = undef;						# generated during .config file parsing

##

use Module::Build;

use File::Spec::Functions qw( rel2abs );
use File::Basename qw( dirname );

# include configuration options, if the file exists
# config file format:
# <var_name1> => <value>...
# ...
# <var_nameN> => <value>...
#
# where each "<varName> => <value>" follows perl hash entry definition semantics (including embedded comments)
# NOTYET: <value> can be multiline, terminated by EOF or next '<var_nameM> => ...' line

my $config_filename = rel2abs($config{'rc_filename'}, dirname(rel2abs($0)));
#print "config => ".$config_filename;
if ( -e $config_filename )
{
	my $comment_chars = q{#};
	my $fh            = undef;
	open( $fh, '<', $config_filename ) or die "Can't open '$config{'rc_filename'}': $OS_ERROR"; ## no critic ( RequireCarping )
	my $line = 0;
	while ( my $s = <$fh> )
	{
		$line++;
		#eval $s;
		my ( $key, $value );
		if ( $s =~ m/^\s*$/ )                            { next; }    # skip any blank line
		if ( $s =~ m/^\s*(?:[$comment_chars]|\/\/).*$/ ) { next; }    # skip any line starting with '#', ';', q{'}, or '//' as a comment line
		if ( $s =~ m/^\s*(.*?)\s*=>\s*(.*)$/ )
		{ ## quoted values are allowed with perl quoting semantics
			$key   = $1;
			$value = $2;
			if ( exists $config{$key} )
			{ ## eval $value into $config{}
				{
				my $ev = '$config'."{$key} = $value";
				my $e = 0; my $w = 0;
				$SIG{'__WARN__'} = sub { if (!$w) {chomp($w = $_[0]);} };
				$e = !eval "$ev; 1";
				#print "w = $w\n";
				$SIG{'__WARN__'} = undef;
				if ($w || $e) {warn "build: warning, malformed configuration entry: $config{'rc_filename'}, line $line\n";}
				}
			}
			else { die "Unknown configuration key '$key' @ ($config{'rc_filename'}, line $line)\n"; }
		}
		else { die "Malformed configuration line @ ($config{'rc_filename'}, line $line)\n"; }
	}
	close $fh or die "Can't close '$config{'rc_filename'}' after reading: $OS_ERROR"; ## no critic ( RequireCarping )
}

#use Data::Dumper;
#print Dumper( %config );
#print Dumper( $config{'module_name'} );
#print Dumper( $config{'os_req'} );

##
##

if ( !$config{'module_name'} ) { die '$config{module_name} must be defined' . "\n"; } ## no critic ( RequireCarping RequireInterpolation )
if ( !$config{'dist_author'} ) { die '$config{dist_author} must be defined' . "\n"; } ## no critic ( RequireCarping RequireInterpolation )
if ( !$config{'license'} ) 	   { die '$config{license} must be defined' . "\n"; } ## no critic ( RequireCarping RequireInterpolation )

if (!$config{'custom_ENV_href'}->{'_module_name'}) { $config{'custom_ENV_href'}->{'_module_name'} = $config{'module_name'}; }

#use lib 'inc';
#require Devel::AssertOS; import Devel::AssertOS ( @{$config{'assert_os_aref'}} );

if (defined($config{'assert_os_aref'}) && @{$config{'assert_os_aref'}}) { my $found = 0; for my $os (@{$config{'assert_os_aref'}}) { $found = 1 if $^O eq $os; }; if (!$found) { die "OS unsupported : $config{module_name} is designed to be used for ( @{$config{assert_os_aref}} ) systems only - installation aborted\n"; }; }; ## no critic (Variables::ProhibitPunctuationVars ErrorHandling::RequireCarping)

my $class = Module::Build->subclass( class => 'RIVY::Builder', code => rivy_builder_code() );
my %optional_args = ();		# Module::Build::new() optional args (only included if they are non-empty; otherwise, if included as empty list(s)/hash(es) in new(), Module::Build carps that the specified [and needed] files are missing)
if ( @{$config{'script_files_aref'}} )   { %optional_args = ( %optional_args, script_files => [ @{$config{'script_files_aref'}} ]); }
if ( keys %{$config{'pm_files_href'}} )  { %optional_args = ( %optional_args, pm_files =>  { %{$config{'pm_files_href'}} }); }
if ( keys %{$config{'pod_files_href'}} ) { %optional_args = ( %optional_args, pod_files => { %{$config{'pod_files_href'}} }); }
if ( keys %{$config{'xs_files_href'}} )  { %optional_args = ( %optional_args, xs_files =>  { %{$config{'xs_files_href'}} }); }
my $build = $class->new(
	module_name    => $config{'module_name'},
	dist_author    => $config{'dist_author'},
	license        => $config{'license'},

	requires       => { %{$config{'requires_href'}} },
	recommends     => { %{$config{'recommends'}} },

	build_requires => { %{$config{'build_requires_href'}} },

	sign                 => $config{'sign'},
	recursive_test_files => $config{'recursive_test_files'},
	create_readme        => $config{'create_readme'},
	create_makefile_pl   => $config{'create_makefile_pl'},

	%optional_args,

	config        		 => { %{$config{'config_href'}} },

	PL_files             => { %{$config{'PL_files_href'}} },

	add_to_cleanup       => [ @{$config{'add_to_cleanup_aref'}}, ( map { join( q{-}, split(/::/xms) ) . q{-*} } $config{'module_name'} ), ( map { join( q{-}, split(/::/xms) ) . '.ppd' } $config{'module_name'} ) ],

	add_to_realcleanup   => [ @{$config{'add_to_realcleanup_aref'}} ],
);

$build->create_build_script;

####
sub _is_const { return !eval { ($_[0]) = $_[0]; 1; }; }
sub _encodeQQ
{
	my $arg_ref;
	$arg_ref = \@_;
	$arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

	for my $arg ( @{$arg_ref} ) {
		if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
		$arg =~ s/([^[:word:].,;:])/'\x{'.sprintf("%x", ord($1)).'}'/esg;
	}
	return wantarray ? @{$arg_ref} : "@{$arg_ref}";
}
sub _encodeQ
{
	my $arg_ref;
	$arg_ref = \@_;
	$arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

	for my $arg ( @{$arg_ref} ) {
		if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
		$arg =~ s/([\\{}])/\\$1/sg;
	}
	return wantarray ? @{$arg_ref} : "@{$arg_ref}";
}
####

sub rivy_builder_code
{ ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars ValuesAndExpressions::ProhibitImplicitNewlines)
my $code = q{};
my %code;
$code{'#pod'} = q{
=head1 ACTIONS (CUSTOM)

Additional custom actions.

=over 4

=item distall

Build all distributions.

=item distppm

Build the PPM distribution.

=item distpar

Build the PAR distribution.

=item sign

Sign the current module content in the base directory (for local testing).

=back

=cut
};
$code{'@'} = q{
	use File::Basename;
	use File::Spec;
	use File::Spec::Functions;
	use IO::File;
};
$code{'@new'} = q{
	sub new{
		#my $self = shift()->_construct(@_);
		#
		#$self->{invoked_action} = $self->{action} ||= 'Build_PL';
		#$self->cull_args(@ARGV);
		#
		#die "Too early to specify a build action '$self->{action}'.  Do 'perl Build.PL' instead.\n"
		#if $self->{action} && $self->{action} ne 'Build_PL';
		#
		#$self->check_manifest;
		#$self->check_prereq;
		#$self->check_autofeatures;
		#
		#$self->dist_name;
		#$self->dist_version;
		#
		#$self->_set_install_paths;
		#$self->_find_nested_builds;
		#
		#return $self;
		my $self = shift;
		my ($args, $action) = $self->read_args(@ARGV);
		if ($action) { die "Too early to specify a build action '$action'.  Do 'perl Build.PL' instead.\n"; }

		return $self->SUPER::new(@_);
		}
};
$code{'dispatch'} = q{
	sub dispatch \{
		#my $self = shift;
		#local $self->{_completed_actions} = {};
		#
		#if (@_) {
		#	my ($action, %p) = @_;
		#	my $args = $p{args} ? delete($p{args}) : {};
		#
		#	local $self->{invoked_action} = $action;
		#	local $self->{args} = {%{$self->{args}}, %$args};
		#	local $self->{properties} = {%{$self->{properties}}, %p};
		#	return $self->_call_action($action);
		#	}
		#
		#die "No build action specified" unless $self->{action};
		#local $self->{invoked_action} = $self->{action};
		#$self->_call_action($self->{action});
		my $self = shift;
};
foreach (keys %{$config{'custom_ENV_href'}}) { $code{'dispatch'} .= qq{\t\t}.'$ENV{'.$_.'} = q{'._encodeQ($config{'custom_ENV_href'}->{$_}).'};'.qq{\n}; }
$code{'dispatch'} .= q{
		return $self->SUPER::dispatch(@_);
	\}
};
$code{'ACTION_testaction'} = q{
	#[ADD] NEW action = testaction - a TEST action
	sub ACTION_testaction {
		my ($self) = @_;

		print "self->dist_name = `".$self->dist_name."`\n";
		print "self->dist_name = `".$self->dist_version."`\n";
		for (sort keys %{$self}) { print "self->{$_} = `$self->{$_}`\n"; }
		my $n;
		my $dist_name = $self->dist_name;
		my $dist_version = $self->dist_version;
		$n = "xx".$self->dist_name."xx";
		print "n = $n\n";
		$n =~ s/$dist_name/YY/g;
		print "n = $n\n";
		print "ENVIRONMENT:\n";
		for (keys %ENV) { print "$_ = $ENV{$_}\n"; }
	  }
};
$code{'ACTION_sign@_sign_dir'} = q{
	sub _sign_dir {
		my ($self, $dir) = @_;

		unless (eval { require Module::Signature; 1 }) {
		$self->log_warn("Couldn't load Module::Signature for signing action:\n $@\n");
		return;
		}

		# Add SIGNATURE to the MANIFEST
		{
		my $manifest = File::Spec->catfile($dir, 'MANIFEST');
		die "Signing a distribution requires a MANIFEST file" unless -e $manifest;
		#$self->_add_to_manifest($manifest, "SIGNATURE    Added here by Module::Build");
		#[CHANGED] == removed comment to prevent altering MANIFEST, when possible (to preserve correct signatures as long as possible)
		$self->_add_to_manifest($manifest, 'SIGNATURE');	# SKIP any comment, it can alter the MANIFEST when/if it is auto-regenerated
		}

		#[ADD] create the dist_meta prior to signature
		$self->ACTION_distmeta;

		# Would be nice if Module::Signature took a directory argument.
		$self->_do_in_dir($dir, sub {local $Module::Signature::Quiet = 1; Module::Signature::sign()});
	}
};
$code{'ACTION_sign'} = q{
	#[ADD] NEW action = sign - sign current module content
	sub ACTION_sign {
		my ($self) = @_;
		# from: ACTION_distsign
		#{
		#local $self->{properties}{sign} = 0;  # We'll sign it ourselves
		#$self->depends_on('distdir') unless -d $self->dist_dir;
		#}
		#$self->_sign_dir($self->dist_dir);
		$self->depends_on('distmeta');

		use File::Spec::Functions qw( rel2abs );
		use File::Basename qw( dirname );

		my $dist_path = '.';
		$dist_path = dirname(rel2abs($0));
		$dist_path =~ s:\\\\:\/:g;
		$self->_sign_dir($dist_path);
	}
};
$code{'ACTION_dist'} = q{
	#[ADD] dist - make ACTION_dist dependant on distmeta
	sub ACTION_dist {
		my ($self) = @_;

		$self->depends_on('distmeta');

		$self->SUPER::ACTION_dist();
	  }
};
$code{'ACTION_distall'} = q{
	#[ADD] NEW action = distall - makes all distributions
	sub ACTION_distall {
		my ($self) = @_;

		$self->depends_on('distmeta');

		$self->depends_on('pardist');
		$self->depends_on('ppmdist');
		$self->depends_on('dist');
	  }
};
$code{'ACTION_distppm'} = q{
	#[ADD] NEW action = distppm - makes ppm distribution (ALIAS to ppmdist)
	sub ACTION_distppm {
		my ($self) = @_;

		$self->depends_on('ppmdist');
	  }
};
$code{'ACTION_distpar'} = q{
	#[ADD] NEW action = distpar - makes par distribution (ALIAS to pardist)
	sub ACTION_distpar {
		my ($self) = @_;

		$self->depends_on('pardist');
	  }
};
$code{'ACTION_realclean'} = q{
	sub ACTION_realclean {
		## BUG in Module::Build v0.30 : Win32 is case-insensitive => so comparisons should be case insensitive => '$basename eq $self->build_script' should be 'lc($basename) eq lc($self->build_script)'
		## and 'Vodoo' is misspelled
		#my ($self) = @_;
		#
		#$self->SUPER::ACTION_realclean();
		#
		#my $basename = basename($0);
		#$basename =~ s/(?:\.bat)?$//i;
		#
		#if ( $basename eq $self->build_script ) {
		#	if ( $self->build_bat ) {
		#		my $full_progname = $0;
		#		$full_progname =~ s/(?:\.bat)?$/.bat/i;
		#
		#		# Vodoo required to have a batch file delete itself without error;
		#		# Syntax differs between 9x & NT: the later requires a null arg (???)
		#		require Win32;
		#		my $null_arg = (Win32::IsWinNT()) ? '""' : '';
		#		my $cmd = qq(start $null_arg /min "\%comspec\%" /c del "$full_progname");
		#
		#		my $fh = IO::File->new(">> $basename.bat")
		#		or die "Can't create $basename.bat: $!";
		#		print $fh $cmd;
		#		close $fh ;
		#	} else {
		#		$self->delete_filetree($self->build_script . '.bat');
		#	}
		#	}
		my ($self) = @_;

		#print @{$self->{properties}{add_to_realcleanup}}."\n";
		#print 'realcleanup_aref = {'.join(':', @{$self->{properties}{add_to_realcleanup}})."}\n";
		$self->add_to_cleanup(@{$self->{properties}{add_to_realcleanup}});

		$self->SUPER::ACTION_realclean();

		my $basename = basename($0);
		$basename =~ s/(?:\.bat)?$//i;

		if ( lc($basename) eq lc($self->build_script) ) {
			if ( $self->build_bat ) {
				my $full_progname = $0;
				$full_progname =~ s/(?:\.bat)?$/.bat/i;
				$full_progname = File::Spec::Functions::rel2abs($full_progname);

				# Voodoo required to have a batch file delete itself without error;
				# Syntax differs between 9x & NT: the later requires a null arg (???)
				## TODO: discuss race condition that occurs here: if other process completes 1st (which should almost never occur) the deletion will still be successful just a possible error message might occur = "The batch file cannot be found." & user may notice that the .bat file is still existant for a couple of seconds until the other process starts/inits/completes the deletion
				## use /d to avoid AutoRUN as well (we only need a basic shell, no addons)
				require Win32;
				my $null_arg = (Win32::IsWinNT()) ? '""' : '';
				my $cmd = qq(start $null_arg /min "%comspec%" /d /c del "$full_progname");

				my $fh = IO::File->new(">> $basename.bat")
				or die "Can't create $basename.bat: $!";
				print $fh "\n".$cmd."\n";						## TODO: calling SUPER::ACTION_realclean() caused a bug repeating the command twice on the same line causing it to fail for PowerShell => add a new line first
				close $fh ;
				}
			else {
				$self->delete_filetree($self->build_script . '.bat');
				}
			}
		}
};
$code{'ACTION_ppmdist@ppm_name'} = q{
	# change PPM name to trailing '-PPM' (instead of the default leading 'PPM-')
	sub ppm_name{
		my $self = shift;
		return $self->dist_dir . '-PPM';
		}
};
$code{'ACTION_ppmdist@htmlify_pods'} = q{
	# correct HTML generation for ActivePerl installations
	sub htmlify_pods{
		my $self = shift;
		my $type = shift;

		if (!(eval { require ActivePerl; })) { return $self->SUPER::htmlify_pods( $type ); }

		# this is an ActivePerl installation

		#print "ActivePerl: PRESENT\n";

		# [code modified from Module::Build::Base.pm]
		#print "type = $type\n";
		#my $htmldir = shift || File::Spec->catdir($self->blib, "${type}html");
		my $htmldir = shift || File::Spec->catdir($self->blib, "html/site/lib");

		require Module::Build::PodParser;
		require Pod::Html;

		$self->add_to_cleanup('pod2htm*');

		my $pods = $self->_find_pods( $self->{properties}{"${type}doc_dirs"}, exclude => [ qr/\.(?:bat|com|html)$/ ] );
		return unless %$pods;  # nothing to do

		my $up_to_date = 1;
		foreach my $pod ( keys %$pods ) {

		  my ($name, $path) = File::Basename::fileparse($pods->{$pod}, qr{\.(?:pm|plx?|pod)$});
		  my @dirs = File::Spec->splitdir( File::Spec->canonpath( $path ) );
		  pop( @dirs ) if $dirs[-1] eq File::Spec->curdir;

		  my $fulldir = File::Spec->catfile($htmldir, @rootdirs, @dirs);
		  my $outfile = File::Spec->catfile($fulldir, "${name}.html");
		  my $infile  = File::Spec->abs2rel($pod);

		  #print "infile = $infile\n";
		  #print "outfile = $outfile\n";

		  next if $self->up_to_date($infile, $outfile);

		  $up_to_date = 0;
		  last;
		  }

		if (!$up_to_date) {
			my $installdirs = $self->SUPER::installdirs;
			#print "installdirs = $installdirs\n";
			require ActivePerl::DocTools;
			$self->SUPER::log_info("HTMLifying PODs\n");
			$self->SUPER::log_verbose("ActivePerl::DocTools::UpdateHTML_blib( installdirs => \"$installdirs\" )\n");
			ActivePerl::DocTools::UpdateHTML_blib( installdirs => "$installdirs" );
			}
		}
};
$code{'ACTION_ppmdist'} = q{
	# correct PPM generation for ActivePerl installations (modified from Module::Build::Base.pm v0.2808)
	sub ACTION_ppmdist {
		my ($self) = @_;

		if (!(eval { require ActivePerl; })) { return $self->SUPER::ACTION_ppmdist; }

		# this is an ActivePerl installation
		#print "my PPMDIST\n";

		$self->SUPER::depends_on( 'build' );

		my $ppm = $self->ppm_name;
		$self->SUPER::delete_filetree( $ppm );
		$self->SUPER::log_info( "Creating $ppm\n" );
		$self->SUPER::add_to_cleanup( $ppm, "$ppm.tar.gz" );

		my %types = ( # translate types/dirs to those expected by ppm
			lib     => 'lib',
			arch    => 'arch',
			bin     => 'bin',
			script  => 'script',
			bindoc  => 'man1',
			libdoc  => 'man3',
			binhtml => undef,
			libhtml => undef,
			html => 'html',
		);

	  foreach my $type ( $self->SUPER::install_types, 'html') {
		next if exists( $types{$type} ) && !defined( $types{$type} );

		my $dir = File::Spec->catdir( $self->blib, $type );
		next unless -e $dir;

		my $files = $self->SUPER::rscan_dir( $dir );
		foreach my $file ( @$files ) {
		  next unless -f $file;
		  my $rel_file =
			File::Spec->abs2rel( File::Spec->rel2abs( $file ),
								 File::Spec->rel2abs( $dir  ) );
		  my $to_file  =
			File::Spec->catdir( $ppm, 'blib',
								exists( $types{$type} ) ? $types{$type} : $type,
								$rel_file );
		  $self->SUPER::copy_if_modified( from => $file, to => $to_file );
		}
	  }

	  foreach my $type ( qw(bin lib) ) {
		local $self->{properties}{html_css} = 'Active.css';
		$self->htmlify_pods( $type, File::Spec->catdir($ppm, 'blib', 'html') );
	  }

	  # create a tarball;
	  # the directory tar'ed must be blib so we need to do a chdir first
	  my $start_wd = $self->cwd;
	  chdir( $ppm ) or die "Can't chdir to $ppm";
	  $self->SUPER::make_tarball( 'blib', File::Spec->catfile( $start_wd, $ppm ) );
	  chdir( $start_wd ) or die "Can't chdir to $start_wd";

	  $self->SUPER::depends_on( 'ppd' );

	  $self->SUPER::delete_filetree( $ppm );
	  }
};
$code{'ACTION_install'} = q{
	sub ACTION_install {
		my ($self) = @_;

        #[ADD] update all distmeta info when installing
        $self->depends_on('distmeta');

		if (!(eval { require ActivePerl; }) || !_has_ppm()) { return $self->SUPER::ACTION_install; }

		# this is an ActivePerl installation (and ppm is available)

		# build ppd and ppm
		$self->depends_on('build');
		$self->depends_on('ppd');
		$self->depends_on('ppmdist');

		my $ppd_name = join('-', split(/::/, $self->dist_name)).'.ppd';

		$self->SUPER::log_info("Installing via ppm (using $ppd_name)\n");
		# TODO: move this note to the appropriate place :: ?Win32-CommandLine... :: note: installation failures involving inability to rename may be either permission problems or, more likely, trying to rename a file which is in use (locking it with a file handle)
		my $output = `ppm install $ppd_name`;
		print $output;
	  }
};
$code{'ACTION_fakeinstall'} = q{
	sub ACTION_fakeinstall {
		my ($self) = @_;

		if (!(eval { require ActivePerl; }) || !_has_ppm()) { return $self->SUPER::ACTION_fakeinstall; }

		# this is an ActivePerl installation (and ppm is available)

		# build ppd and ppm
		$self->depends_on('build');
		$self->depends_on('ppd');
		$self->depends_on('ppmdist');

		my $ppd_name = join('-', split(/::/, $self->dist_name)).'.ppd';

		$self->SUPER::log_info("Installing via ppm (using $ppd_name)\n");
		#`ppm install $ppd_name`;
	  }
};
$code{'ACTION_fakeinstall@_has_ppm'} = q{
	sub _has_ppm {
		use File::Which;
		return File::Which::which('ppm');
	  }
};
$code{'ACTION_distmeta'} = q{
    sub ACTION_distmeta {
        my ($self) = @_;

        #[ADD] update the MANIFEST when building 'distmeta'
        #$self->depends_on('manifest');
		$self->ACTION_manifest;

		#[ADD]
		#$self->do_create_makefile_pl if $self->create_makefile_pl;
		#$self->do_create_readme if $self->create_readme;
		#$self->do_create_license if $self->create_license;
		#$self->do_create_metafile;
        #return $self->SUPER::ACTION_distmeta;
        $self->SUPER::ACTION_distmeta;

        #[ADD] re-update the MANIFEST with any new files
        #$self->depends_on('manifest');
		$self->ACTION_manifest;
      }
};
$code{'ACTION_testall'} = q{
    sub ACTION_testall {
        my ($self) = @_;

        #[ADD] build dependency (to make sure we're testing the most recent incarnation of the package)
        $self->depends_on('build');

        return $self->SUPER::ACTION_testall;
      }
};
$code{'ACTION_manifest'} = q{
  {
  my $dist_name = q{};
  my $dist_version = q{};
  my $dist_path = q{};
    ## FROM: ExtUtils::Manifest (v1.54)
	sub my_maniskip {
		#print "HERE in my_maniskip()\n";
		my @skip ;
		my $mfile = shift || "$ExtUtils::Manifest::MANIFEST.SKIP";
		ExtUtils::Manifest::_check_mskip_directives($mfile) if -f $mfile;
		local(*M, $_);
		open M, "< $mfile" or open M, "< $ExtUtils::Manifest::DEFAULT_MSKIP" or return sub {0};
		while (<M>){
		chomp;
		s/\r//;
		next if /^#/;
		next if /^\s*$/;
		s/\s+(#.*)?$//;	# remove trailing whitespace and comments (any whitespace followed by '#') ## BUGFIX: trailing comments were being interpreted into the regexp ## TODO: ExtUtils::Manifest docs say whitespace may be included in regexp if single quoted o/w whitespace and anything following are discarded as comments (see perldoc ExtUtils::Manifest, MANIFEST section)
		#TODO: leave whitespace within single quotes alone (need a balanced single quote regexp here)
			s/^'//;
			s/'$//;
		#print "skip: regexp = '$_'\n";
		#TODO: check for bad regexps
		push @skip, ExtUtils::Manifest::_macify($_);
		}
		close M;
		# bring $dist_name, $dist_version, $dist_path into current scope
		my @x = ($dist_name, $dist_version, $dist_path);
		#print "dist_path = $dist_path\n";
		#print "dist_name = $dist_name\n";
		#print "dist_version = $dist_version\n";
		#print 'skip['.scalar(@skip)."] = {". join(':', @skip) ."}]\n\n";
		# insert vars into regexps
		for (@skip) { s:\$\{(\w+)\}:eval '${'.$1.'}':eg}

		return sub {0} unless (scalar @skip > 0);

		# extinguish only used once warnings
		my $dummy; $dummy = $ExtUtils::Manifest::Is_VMS; $dummy = $ExtUtils::Manifest::MANIFEST; $dummy = $ExtUtils::Manifest::DEFAULT_MSKIP;

		my $opts = $ExtUtils::Manifest::Is_VMS ? '(?i)' : '';

		# Make sure each entry is isolated in its own parentheses, in case
		# any of them contain alternations
		my $regex = join '|', map "(?:$_)", @skip;

#		return sub {
#			my $f = File::Spec->rel2abs($_[0]);
#			if ($^O eq 'MSWin32') {$f =~ s:\\\\:/:g;};
#			#print "[$_[0]=>$f]\n";
#			return ($f =~ qr{$opts$regex});
#			};
		return sub {
			# check each regex against the full filename
			# this is not noticibly slower than the single regex against the relative/shortened filename
			my $f = File::Spec->rel2abs($_[0]);
			if ($^O eq 'MSWin32') {$f =~ s:\\\\:/:g;};		# unixify path for Win32
			my $found = 0;
			#print "[$_[0]=>$f]:";
			#print 'skip['.scalar(@skip)."] = {". join(':', @skip) ."}]\n\n";
			for my $re (@skip) { if ($f =~ qr{$opts$re}) { $found = 1; last; } };
			#print "[skip = ".($found ? "true" : "false")."]\n";
			return $found;
			};
	  }
	sub ACTION_manifest {
		my ($self) = @_;

		use Sub::Override;
		require ExtUtils::Manifest; #ExtUtils::Manifest->import();
		my $codeRef = \&my_maniskip;
		my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => $codeRef );
		#local *ExtUtils::Manifest::_maniskip = &my_maniskip;
		*ExtUtils::Manifest::_maniskip = $codeRef;

		use File::Spec::Functions qw( rel2abs );
		use File::Basename qw( dirname );

		## ADDED: dist_name and dist_version for use within MANIFEST.SKIP
		$dist_name = quotemeta( $self->dist_name );
		$dist_version = quotemeta( $self->dist_version );
		$dist_path = dirname(rel2abs($0)); $dist_path =~ s:\\\\:\/:g; $dist_path = quotemeta( $dist_path );
		#print "dist_path = $dist_path\n";

        $self->SUPER::ACTION_manifest;

		# ???: SIGN?
		#my $dist_path = '.';
		#$dist_path = dirname(rel2abs($0));
		#$dist_path =~ s:\\\\:\/:g;
		#$self->_sign_dir($dist_path);

        ##my $manifest = File::Spec->catfile($dist_path, $ExtUtils::Manifest::MANIFEST);
        ##$self->_sort_manifest( $manifest );
	  }
	##?? add Sub::Override for maniskip here?? for all subs in the new Build
	#require ExtUtils::Manifest;
	#use Sub::Override;
	#my $codeRef = \&my_maniskip;
	#my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => $codeRef );
	#my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => \&my_maniskip );
	#override->restore;
	#*ExtUtils::Manifest::_maniskip = \&my_maniskip;

	# ... might be brittle:: Module::Signature overrides it as well ( but only for ExtUtils::Manifest->VERSION < 1.41 ), probably ok
	# ... petition ExtUtils::Manifest maintainers for a hook? changing the original code might break some folks MANIFEST.SKIPs
  }
};
$code{'ACTION_ppd@my_varchname'} = q{
	##BUGBYPASS: [for Module::Build v0.3 and perl v5.10+ $^V version string change] repairs incorrect version interpretation for perl v5.10+ (still works for 5.8 and earlier, as well)
	sub my_varchname {  # Copied from PPMMaker.pm
	  	my ($self, $config) = @_;
	  	my $varchname = $config->{archname};
	  	# Append "-5.8" to architecture name for Perl 5.8 and later
	  	#if (defined($^V) && ord(substr($^V,1)) >= 8) {
	  	  #$varchname .= sprintf("-%d.%d", ord($^V), ord(substr($^V,1)));
	  	#}
	  	## BUGFIX: send to Module::Build::PPMMaker and PPM
	  	if (defined($^V)) {
			my @v = split(/\./, sprintf(qq{%vd},$^V));
			if ($v[1] >= 8) {
	  		  	$varchname .= '-'.$v[0].'.'.$v[1];
	  		  	}
      	}
	  	return $varchname;
	  }
};
$code{'ACTION_ppd'} = q{
	# copied from Mobule::Build - Base.pm (v0.3)
	sub ACTION_ppd {
	  	my ($self) = @_;
	  	require Module::Build::PPMMaker;
	  	my $ppd = Module::Build::PPMMaker->new();
		use Sub::Override;
		my $codeRef = \&my_varchname;
		my $override = Sub::Override->new( 'Module::Build::PPMMaker::_varchname' => $codeRef );
	  	my $file = $ppd->make_ppd(%{$self->{args}}, build => $self);
	  	$self->add_to_cleanup($file);
	  }

};
$code{'ACTION_test'} = q{
    sub ACTION_test {
        my ($self) = @_;

        #[ADD] build dependency (to make sure we're testing the most recent incarnation of the package)
        $self->depends_on('build');

        return $self->SUPER::ACTION_test;
      }
};

##	$code .= q[
##		sub do_create_makefile_pl{
##			my $self = shift;
##
##			$self->SUPER::do_create_makefile_pl;
##		];
###	if ( defined( $config{'specific_os'} ) )
###		{
###		$code .= qq{
###			my $fh;
###			$fh = IO::File->new(">> Makefile.PL") or die "Can't append Makefile.PL: $!";
###			print \$fh q(BEGIN {if (\$^O ne '$config{q{specific_os}}') { die "$specific_os_msg"; }});
###			$fh->close();
###			};
##	$code .= q[
##			}
##		];

	for (keys %{$config{custom_code_href}}) { $code{$_} = $config{custom_code_href}->{$_}; }

	for (sort keys %code) { $code .= $code{$_}; }

	return $code;
}


## FROM: Module::Build::Base
#sub ACTION_manifest {
#  my ($self) = @_;
#
#  my $maniskip = 'MANIFEST.SKIP';
#  unless ( -e 'MANIFEST' || -e $maniskip ) {
#    $self->log_warn("File '$maniskip' does not exist: Creating a default '$maniskip'\n");
#    $self->_write_default_maniskip($maniskip);
#  }
#
#  require ExtUtils::Manifest;  # ExtUtils::Manifest is not warnings clean.
#  local ($^W, $ExtUtils::Manifest::Quiet) = (0,1);
#  use Sub::Override;
#  my $override = Sub::Override->new( 'ExtUtils::Manifest::maniskip' => &my_maniskip );
#  ExtUtils::Manifest::mkmanifest('ExtUtils::Manifest::maniskip');
#  override->restore;
#}

# FROM: Module::Build::Base
#sub ACTION_manifest {
#  my ($self) = @_;
#
#  my $maniskip = 'MANIFEST.SKIP';
#  unless ( -e 'MANIFEST' || -e $maniskip ) {
#    $self->log_warn("File '$maniskip' does not exist: Creating a default '$maniskip'\n");
#    $self->_write_default_maniskip($maniskip);
#  }
#
#  require ExtUtils::Manifest;  # ExtUtils::Manifest is not warnings clean.
#  local ($^W, $ExtUtils::Manifest::Quiet) = (0,1);
#  ExtUtils::Manifest::mkmanifest();
#}


# FROM: Module::Build::Base
#sub ACTION_manifest {
#  my ($self) = @_;
#
#  my $maniskip = 'MANIFEST.SKIP';
#  unless ( -e 'MANIFEST' || -e $maniskip ) {
#    $self->log_warn("File '$maniskip' does not exist: Creating a default '$maniskip'\n");
#    $self->_write_default_maniskip($maniskip);
#  }
#
#  require ExtUtils::Manifest;  # ExtUtils::Manifest is not warnings clean.
#  local ($^W, $ExtUtils::Manifest::Quiet) = (0,1);
#  ExtUtils::Manifest::mkmanifest();
#}

# FROM: ExtUtils::Manifest
## returns an anonymous sub that decides if an argument matches
#sub maniskip {
#    my @skip ;
#    my $mfile = shift || "$MANIFEST.SKIP";
#    _check_mskip_directives($mfile) if -f $mfile;
#    local(*M, $_);
#    open M, "< $mfile" or open M, "< $DEFAULT_MSKIP" or return sub {0};
#    while (<M>){
#	chomp;
#	s/\r//;
#	next if /^#/;
#	next if /^\s*$/;
#        s/^'//;
#        s/'$//;
#	push @skip, _macify($_);
#    }
#    close M;
#    return sub {0} unless (scalar @skip > 0);
#
#    my $opts = $Is_VMS ? '(?i)' : '';
#
#    # Make sure each entry is isolated in its own parentheses, in case
#    # any of them contain alternations
#    my $regex = join '|', map "(?:$_)", @skip;
#
#    return sub { $_[0] =~ qr{$opts$regex} };
#}
