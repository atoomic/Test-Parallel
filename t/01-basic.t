use strict;
use warnings;

use Test::More tests => 10;

use_ok 'Test::Parallel';

my $p = Test::Parallel->new();

isa_ok $p, 'Test::Parallel';

for my $job (qw/a list of jobs to run/) {
    ok $p->add( sub { compute_this_job($job); } ), "can add job $job";
}

ok $p->run(), "can run test in parallel";

is_deeply $p->result(), [
          {
            'time' => 1,
            'job' => 'a',
            'your data key for a' => 1
          },
          {
            'time' => 1,
            'job' => 'list',
            'your data key for list' => 4
          },
          {
            'time' => 2,
            'your data key for of' => 2,
            'job' => 'of'
          },
          {
            'time' => 1,
            'your data key for jobs' => 4,
            'job' => 'jobs'
          },
          {
            'your data key for to' => 2,
            'time' => 2,
            'job' => 'to'
          },
          {
            'your data key for run' => 3,
            'time' => 0,
            'job' => 'run'
          }
        ], "can get results for all tests";

sub compute_this_job {
    my $job = shift || '';

    my $time = int( length($job) % 3 );
    # start some job
    sleep( $time );
    print '- finish job ' . $job . "\n";

    # will never stop at the same time
    return { job => $job, 'your data key for ' . $job => length($job), 'time' => $time };
}


exit;

