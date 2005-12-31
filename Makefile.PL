#!/usr/bin/perl

use strict;
use inc::Module::Install;

name            'Parse-SVNDiff';
all_from        'lib/Parse/SVNDiff.pm';
build_requires  'Test::Base';
requires        'Data::Lazy'     => 0.06;
requires        'Class::Tangram' => 1.54,

sign; WriteAll;
