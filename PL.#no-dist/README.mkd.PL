#!perl -w -- ## no critic ( RequireEndWithOne RequireExplicitPackage RequireVersionVar )
#(emacs/sublime) -*- mode: perl; tab-width: 4; -*-

use strict;
use warnings;
use utf8;

# require SelfLoader if 0; ## no critic (ProhibitPostfixControls) ## purely a signal compelling `perltidy` to reformat code post-"__DATA__"

my $output_filename = shift;

use Module::Build;

binmode DATA, ':raw:encoding(UTF-8)';   # binmode (no EOL translations) + utf8

() = Module::Build->current()->expand_template( $output_filename, [<DATA>] );

__DATA__
<!DOCTYPE markdown>
<meta charset="utf-8" content="text/markdown" lang="en">

<!-- ":{{$ME_ID}}:" -->

[![[AppVeyor ~ build status]](https://ci.appveyor.com/api/projects/status/":{{$user_ci_appveyor_key}}:"/branch/":{{$repo_branch}}:"?svg=true)](https://ci.appveyor.com":{{$user_ci_appveyor_path}}:")
[![[Travis CI ~ build status]](https://travis-ci.org":{{$dist_repo_web_path}}:".svg?branch=":{{$repo_branch}}:")](https://travis-ci.org":{{$dist_repo_web_path}}:")
[![[Codecov ~ status]](https://codecov.io/gh":{{$dist_repo_web_path}}:"/branch/":{{$repo_branch}}:"/graph/badge.svg)](https://codecov.io/gh":{{$dist_repo_web_path}}:")
[![[Coveralls ~ status]](https://coveralls.io/repos/github":{{$dist_repo_web_path}}:"/badge.svg?branch=":{{$repo_branch}}:")](https://coveralls.io/github":{{$dist_repo_web_path}}:"?branch=":{{$repo_branch}}:")

# [":{{$dist_name}}:"](":{{$dist_metacpan}}:")-":{{$VERSION}}:"
