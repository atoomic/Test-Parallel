#
#===============================================================================
#
#         FILE:  01-usage.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Nicolas Rochelemagne (NR), nicolas.rochelemagne@cpanel.net
#      COMPANY:  cPanel, Inc
#      VERSION:  1.0
#      CREATED:  05/30/2012 08:26:50
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use v5.10;

use Test::More tests => 3;                      # last test to print
#use Test::Output;

my $class = 'MyApplication'; # EDIT_ME
use_ok($class, "can load module $class");

=pod
SKIP: {
          skip $why, $how_many unless $have_some_feature;

          ok( foo(),       'test name' );
          is( foo(42), 23, 'test name' );

};
=cut

subtest 'module checking' => sub {
    can_ok($class, 'run', 'method run is available');
    isa_ok($class->new(), $class, "can create object from $class");
};

subtest 'dummy memo' => sub {
    like  ('sample expected sentence', qr/expected/, 'regexp match');
    unlike('everything is fine', qr/error/, 'regexp does not match');
    cmp_ok(42, '==', 42, '42 is still the same');
    is_deeply({}, {}, "deeply check");
};

done_testing();


