#!perl -w -- ## no critic ( RequireEndWithOne RequireExplicitPackage RequireTidyCode RequireVersionVar )
#(emacs/sublime) -*- mode: perl; tab-width: 4; -*-

use strict;
use warnings;
use utf8;

# require SelfLoader if 0; ## no critic (ProhibitPostfixControls) ## purely a signal compelling `perltidy` to reformat code post-"__DATA__"

my $output_filename = shift;

use Module::Build;

binmode DATA, ':raw:utf8'; ## no critic ( RequireEncodingWithUTF8Layer ) ## utf8 + avoid EOL translations

() = Module::Build->current()->expand_template( $output_filename, [<DATA>] );

__DATA__
<!DOCTYPE markdown>
<meta charset="utf-8" content="text/markdown" lang="en">

<!-- ":{{$ME_ID}}:" -->

[![[AppVeyor ~ build status]](https://ci.appveyor.com/api/projects/status/":{{$user_ci_appveyor_key}}:"/branch/":{{$branch}}:"?svg=true)](https://ci.appveyor.com/":{{$user_ci_appveyor_path}}:")
[![[Travis CI ~ build status]](https://travis-ci.org":{{$repo_URL_path}}:".svg?branch=":{{$branch}}:")](https://travis-ci.org":{{$repo_URL_path}}:")
[![[Codecov ~ status]](https://codecov.io/gh":{{$repo_URL_path}}:"/branch/":{{$branch}}:"/graph/badge.svg)](https://codecov.io/gh":{{$repo_URL_path}}:")
[![[Coveralls ~ status]](https://coveralls.io/repos/github/":{{$repo_URL_path}}:"/badge.svg?branch=":{{$branch}}:")](https://coveralls.io/github":{{$repo_URL_path}}:"?branch=":{{$branch}}:")

# ":{{$dist_name}}:"-":{{$VERSION}}:"
