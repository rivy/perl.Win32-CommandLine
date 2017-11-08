#(emacs/sublime) -*- mode: perl; tab-width: 4; coding: dos; -*-
use strict;
use warnings;

my $output_filename = shift;
use Module::Build;

my $mb = Module::Build->current()->expand_template( $output_filename, [ <DATA> ] );

__END__
# #{{$dist_name}}#-#{{$VERSION}}#

[![[AppVeyor ~ build status]](https://ci.appveyor.com/api/projects/status/#{{$user_ci_appveyor_key}}#/branch/#{{$branch}}#?svg=true)](https://ci.appveyor.com/project/rivy/perl-benchmark-mark)
[![[Travis CI ~ build status]](https://travis-ci.org#{{$repo_URL_path}}#.svg?branch=#{{$branch}}#)](https://travis-ci.org#{{$repo_URL_path}}#)
[![[Codecov ~ status]](https://codecov.io/gh#{{$repo_URL_path}}#/branch/#{{$branch}}#/graph/badge.svg)](https://codecov.io/gh#{{$repo_URL_path}}#)
[![[Coveralls ~ status]](https://coveralls.io/repos/github/#{{$repo_URL_path}}#/badge.svg?branch=#{{$branch}}#)](https://coveralls.io/github/#{{$repo_URL_path}}#?branch=#{{$branch}}#)

