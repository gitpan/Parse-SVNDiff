#!/usr/bin/perl

use inc::Module::Install;

name		('Parse-SVNDiff');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('Subversion binary diff format parser');
license		('perl');
version_from	('lib/Parse/SVNDiff.pm');
requires        ( perl => '5.8.0' );

WriteAll( sign => 1 );
