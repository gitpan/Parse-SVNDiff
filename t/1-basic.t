use strict;
use Test::More tests => 5;

use_ok('Parse::SVNDiff');

my $raw = join '', map pack('B*', $_), map /([01]{8})/g, <DATA>;

my $diff = Parse::SVNDiff->new;

isa_ok($diff, 'Parse::SVNDiff');

is(
    $diff->parse($raw),
    $diff,
    '->parse returns self',
);

is(
    $diff->apply('aaaabbbbcccc'),
    'aaaaccccdddddddd',
    '->apply works',
);

is(
    unpack('B*', $diff->dump),
    unpack('B*', $raw),
    '->dump roundtrips',
);


1;

__DATA__
01010011 01010110 01001110 00000000	Header ("SVN\0")

00000000				Source view offset 0
00001100				Source view length 12
00010000				Target view length 16
00000111				Instruction length 7
00000001				New data length 1

00000100 00000000			Source, len 4, offset 0
00000100 00001000			Source, len 4, offset 8
10000001				New, len 1
01000111 00001000			Target, len 7, offset 8

01100100				The new data: 'd'
