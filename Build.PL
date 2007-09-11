#!perl -w   -*- tab-width: 4; mode: perl -*-
#$Id$

## no critic ( CodeLayout::ProhibitHardTabs CodeLayout::ProhibitParensWithBuiltins )

use strict;
use warnings;
use 5.006;      # v5.5 [for AUTHOR and ABSTRACT in Makefile.PL], v5.6 for 'our'

##- config
my %config;
$config{'module_name'} = undef;
$config{'specific_os'} = undef;	# limit to a single specific OS (eg, 'MSWin32') [default: undef == no OS limitation]
#
$config{'rc_filename'} = '.buildrc';	# configuration file name
##

if (-e $config{'rc_filename'}) { open(FH, $config{'rc_filename'}); while(my $t = <FH>) { eval $t; } }	# include build configuration if it exists

# VERSION: x.y[.z[.date/build]]  { y is odd = beta/experimental; y is even = release }
use version qw(); our $VERSION = version::qv('0.1.0'.'.'.join(q{}, split(/\//xms,qw($Date$)[-3])).q{.}.qw($Rev$)[-2]);		## no critic ( ProhibitCallsToUnexportedSubs )
our $REVISION = qw($Revision$)[-2];

use Module::Build;

if (!$config{'module_name'}) { die '$config{module_name} must be defined'; };		## no critic ( RequireCarping )

my $specific_os_msg = "$config{module_name} is designed to be used for ".($config{'specific_os'} ? $config{'specific_os'} : '<any>')." systems only - installation aborted\n";

if (defined($config{'specific_os'}) && $^O ne $config{'specific_os'}) { die $specific_os_msg; };		## no critic (Variables::ProhibitPunctuationVars ErrorHandling::RequireCarping)

my $lib_directory = 'lib/'.join(q{\\}, split(/::/xms, ($config{'module_name'} =~ m/(.*)::.*?$/xms ? $1 : q{})));

my $class = Module::Build->subclass( class => 'RIVY::Builder', code => rivy_builder_code() );
my $build = $class->new
  (
	module_name         => $config{'module_name'},
	dist_author         => 'Roy Ivy III <rivy[at]cpan.org>',
	license             => 'perl',
	requires => {
			},
	build_requires => {
			'version' => 0,
			'File::Which' => 0,
			},
	sign => 1,
	script_files => [ map {glob} qw{ scripts/* } ],
	xs_files => { map { $_ => $lib_directory.q{\\}.$_ } (map {glob} qw{ *.xs }) },
	recursive_test_files => 1,
	create_readme => 1, # create README from module pod
	create_makefile_pl => 'traditional',
	PL_files => {},
	add_to_cleanup => [
			(map { join(q{-}, split(/::/xms)).q{-*} } $config{'module_name'}),
			(map { join(q{-}, split(/::/xms)).'.ppd' } $config{'module_name'}),
			'MANIFEST.bak',
			'Build.bat',
			'Makefile',
			'Makefile.old',
			'pm_to_blib',
			],
	);

$build->create_build_script;

####

sub rivy_builder_code{
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars ValuesAndExpressions::ProhibitImplicitNewlines)
my $code = q{
	# change PPM name to trailing '-PPM' (instead of the default leading 'PPM-')
	sub ppm_name{
		my $self = shift;
		return $self->dist_dir . '-PPM';
		}
	# correct HTML generation for ActivePerl installations
	sub htmlify_pods{
		my $self = shift;
		my $type = shift;

		if (!(eval { require ActivePerl; })) { return $self->SUPER::htmlify_pods( $type ); }

		# this is an ActivePerl installation

		#print "ActivePerl: PRESENT\n";
		my $installdirs = $self->SUPER::installdirs;
		#print "installdirs = $installdirs\n";
		require ActivePerl::DocTools;
		$self->SUPER::log_info("HTMLifying PODs\n");
		$self->SUPER::log_verbose("ActivePerl::DocTools::UpdateHTML_blib( installdirs => \"$installdirs\" )\n");
		ActivePerl::DocTools::UpdateHTML_blib( installdirs => "$installdirs" );
		}
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
	sub ACTION_install {
		my ($self) = @_;

		if (!(eval { require ActivePerl; })) { return $self->SUPER::ACTION_install; }

		# this is an ActivePerl installation (with ppm available)

		# build ppd and ppm
		$self->depends_on('build');
		$self->depends_on('ppd');
		$self->depends_on('ppmdist');

		my $ppd_name = join('-', split(/::/, $self->dist_name)).'.ppd';

		$self->SUPER::log_info("Installing using ppm (using $ppd_name)\n");
		`ppm install $ppd_name`;
	  }
	sub ACTION_fakeinstall {
		my ($self) = @_;

		if (!(eval { require ActivePerl; })) { return $self->SUPER::ACTION_fakeinstall; }

		# this is an ActivePerl installation (with ppm available)

		# build ppd and ppm
		$self->depends_on('build');
		$self->depends_on('ppd');
		$self->depends_on('ppmdist');

		my $ppd_name = join('-', split(/::/, $self->dist_name)).'.ppd';

		$self->SUPER::log_info("Installing using ppm (using $ppd_name)\n");
		#`ppm $ppd_name`;
	  }
	sub _has_ppm {
		use File::Which;
		return File::Which::which('ppm');
	  }
    sub ACTION_testall {
        my ($self) = @_;

        #[ADD] build dependency (to make sure we're testing the most recent incarnation of the package)
        $self->depends_on('build');

        return $self->SUPER::ACTION_testall;
      }
    sub ACTION_test {
        my ($self) = @_;

        #[ADD] build dependency (to make sure we're testing the most recent incarnation of the package)
        $self->depends_on('build');

        return $self->SUPER::ACTION_test;
      }
	};
	$code .= q{
		sub do_create_makefile_pl \{
			my $self = shift;

			$self->SUPER::do_create_makefile_pl;

			my $fh;
			$fh = IO::File->new(">> Makefile.PL") or die "Can't append Makefile.PL: $!";
		};
	if (defined($config{'specific_os'})) { $code .= qq{
			print \$fh q(BEGIN {if (\$^O ne '$config{q{specific_os}}') { die "$specific_os_msg"; }});
		};
		}
	$code .= q{
			$fh->close();
			\}
		};
	return $code;
}
