package Test::Parallel;
use strict;
use warnings;
use Test::More ();

# ABSTRACT: launch your test in parallel

=pod
=head1 VERSION  0.5
=cut

use Parallel::ForkManager;
use Sys::Info;

my @methods = qw{ok is isnt like unlike cmp_ok is_deeply can_ok isa_ok};

sub new {
    my $self = bless {}, __PACKAGE__;

    $self->_init();

    return $self;
}

sub _init {
    my ($self) = @_;

    $self->_add_methods();
    $self->_pfork();
    $self->{result} = {};
    $self->{pfork}->run_on_finish(
        sub {
            my ( $pid, $exit, $id, $exit_signal, $core_dump, $data ) = @_;
            die "Failed to process on one job, stop here !"
              if $exit || $exit_signal;
            $self->{result}->{$id} = $data->{result};
        }
    );
    $self->{jobs}  = [];
    $self->{tests} = [];
}

sub _pfork {
    my ($self) = @_;

    my $cpu = Sys::Info->new()->device('CPU')->count() || 1;

    # we could also set a minimum amount of required memory

    $self->{pfork} = new Parallel::ForkManager($cpu);
}

sub add {
    my ( $self, $code, $test ) = @_;

    return unless $code && ref $code eq 'CODE';
    push(
        @{ $self->{jobs} },
        { name => ( scalar( @{ $self->{jobs} } ) + 1 ), code => $code }
    );
    push( @{ $self->{tests} }, $test );
}

sub run {
    my ($self) = @_;

    return unless scalar @{ $self->{jobs} };
    my $pfm = $self->{pfork};
    for my $job ( @{ $self->{jobs} } ) {
        $pfm->start( $job->{name} ) and next;
        my $job_result = $job->{code}();

        # can be used to stop on first error
        my $job_error = 0;
        $pfm->finish( $job_error, { result => $job_result } );
    }

    # wait for all jobs
    $pfm->wait_all_children;

    return $self->{result};
}

sub _add_methods {

    return unless scalar @methods;

    foreach my $sub (@methods) {
        my $accessor = __PACKAGE__ . "::$sub";
        my $map_to   = "Test::More::$sub";
        next unless defined &{$map_to};

        # allow symbolic refs to typeglob
        no strict 'refs';
        *$accessor = sub {
            my ( $self, $code, @args ) = @_;
            $self->add( $code, { test => $map_to, args => \@args } );
        };
    }

    @methods = ();
}

#
#sub ok {
#    my ( $self, $code, @args ) = @_;
#    $self->add( $code, { test => 'Test::More::ok', args => \@args } );
#}

# run and check results
sub done {
    my ($self) = @_;

    # run tests
    die "Cannot run tests" unless $self->run();

    my $c = 0;

    # check all results with Test::More
    my $results = $self->results();
    map {
        my $test = $_;
        return unless $test && ref $test eq 'HASH';
        return unless defined $test->{test} && defined $test->{args};

        die "cannot find result for test ", join( ' ', $test->{test}, @{ $test->{args} } )
          unless exists $results->[$c];
        my $res  = $results->[ $c++ ];
        my @args = ( $res, @{ $test->{args} } );
        my $t    = $test->{test};
        my $str  = join( ', ', map { "\$args[$_]" } ( 0 .. $#args ) );
        eval "$t(" . $str . ")";

    } @{ $self->{tests} };

}

sub results {
    my ($self) = @_;

    my @sorted =
      map  { $self->{result}{$_} }
      sort { int($a) <=> int($b) } keys %{ $self->{result} };
    return \@sorted;
}
{
    no warnings;
    *result = \&results;
}

# ==== test

#sub p_fork {
#    # FIXME to improve
#    return new Parallel::ForkManager(5);
#}

#sub p_fork {
#    my $MAX_PROCESS = 4;    #number of your CPUs for example
#    my $pfm = Parallel::ForkManager->new($MAX_PROCESS);
#    return $pfm;
#}

#my $pfm    = p_fork;        #return a Parallel::ForkManager instance

=pod
my @jobs = qw/task to do in parallel to speedup/;

for my $job (@jobs) {
    $pfm->start( $job ) and next;
    
    my $job_result = compute_this_job($job);
    my $job_error = ref $job_result eq 'HASH' ? 0 : 1;
    
    $pfm->finish( $job_error, $job_result );
}
$pfm->wait_all_children;


say Dumper($result);

exit;
=cut

1;

__END__
    
    # minimum require memory for your process
    my ($min_mem) = @_; # default 1 Go
    $min_mem ||= 1024 ** 2; #1 GO => expr in Kb
    
    # get number of cpus on the machine
    my $cpu_info = Sys::Info->new;
    my $cpu = $cpu_info->device('CPU');
    my $MAX_PROCESSES_FOR_CPU = $cpu->count || 1;
    # get real free mem in KB
    my $freemem = Sys::Statistics::Linux::MemStats->new->get->{realfree};
    
    # 3GB by fork max
    my $MAX_PROCESSES_FOR_MEM = int($freemem / ($min_mem));
    # get the min between cpu and memory slot, 
    # 0 mean no fork because not enough memory
    my $MAX_PROCESSES = 
          min($MAX_PROCESSES_FOR_CPU, $MAX_PROCESSES_FOR_MEM);
    # return the process, ready to use
    my $pm = new Parallel::ForkManager($MAX_PROCESSES);
    wantarray and return ($pm, $MAX_PROCESSES) or return $pm;
}
