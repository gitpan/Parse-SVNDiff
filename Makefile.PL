#!/usr/bin/perl

use inc::Module::Install;

# HACK to workaround bug in Test::Base;
# Use of uninitialized value in string eq at /utsl/perl/lib/site_perl/5.8.6/Test/Base.pm line 125.
# Can't call method "_assert_plan" on an undefined value at /utsl/perl/lib/site_perl/5.8.6/Test/Base.pm line 276.
# END failed--call queue aborted.
#
BEGIN { no strict; local($^W)=0; eval "use base qw(Test::Base)" };

name		('Parse-SVNDiff');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('Subversion binary diff format parser');
license		('perl');
version_from	('lib/Parse/SVNDiff.pm');
build_requires  ( Test::Base => 0,
		);
requires        ( perl => '5.8.0',
		  Class::Tangram => 1.54,
		);

WriteAll( sign => 1 );
