use strict;
use warnings;

use Test::More tests => 3;


# FIXME add a test
# plug
use Data::Dumper qw/Dumper/;

my $p = Test::Parallel->new();

for my $job (qw/a list of jobs to run/) {
    $p->add( sub { compute_this_job($job); } );
}

my $r = $p->run();

print Dumper( $p->result() );

exit;

