use strict;
use warnings;

use Test::More tests => 10;

use_ok 'Test::Parallel';

my $p = Test::Parallel->new();

$p->ok( sub { 1 }, "test is ok" );
$p->ok( sub { 42 }, "test is ok" );

$p->done();