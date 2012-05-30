package Test::Parallel;
use strict;
use warnings;
use Test::More ();
use Parallel::ForkManager;
use Sys::Info;

# ABSTRACT: launch your test in parallel

=head1 NAME
Test::Parallel - simple object interface to launch unit test in parallel

=head1 DESCRIPTION

Test::Parallel is a simple object interface used to launch test in parallel.
It uses Parallel::ForkManager to launch tests in parallel and get the results.

Alias for basic methods are available

    ok is isnt like unlike cmp_ok is_deeply
    
It can be used nearly the same way as Test::More

    use Test::More tests => 8;
    use Test::Parallel;
    
    my $p = Test::Parallel->new();
    
    # queue the tests
    $p->ok( sub { 1 }, "can do ok" );
    $p->is( sub { 42 }, 42, "can do is" );
    $p->isnt( sub { 42 }, 51, "can do isnt" );
    $p->like( sub { "abc" }, qr{ab}, "can do like: match ab");
    $p->unlike( sub { "abc" }, qr{xy}, "can do unlike: match ab");
    $p->cmp_ok( sub { 'abc' }, 'eq', 'abc', "can do cmp ok");
    $p->cmp_ok( sub { '1421' }, '==', 1_421, "can do cmp ok");
    $p->is_deeply( sub { [ 1..15 ] }, [ 1..15 ], "can do is_deeply");

    # run the tests in background
    $p->done();

=for Pod::Coverage ok is isnt like unlike cmp_ok is_deeply can_ok isa_ok

=head1 METHODS

=head2 new

Create a new Test::Parallel object

    my $tp = Test::Parallel->new()

=cut

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

=head2 $pm->add($code)

You can manually add some code to be launched in parallel,
but if you uses this method you will need to manipulate yourself the final
result. 

Prefer using one of the following methods :
    
    ok is isnt like unlike cmp_ok is_deeply

=cut

sub add {
    my ( $self, $code, $test ) = @_;

    return unless $code && ref $code eq 'CODE';
    push(
        @{ $self->{jobs} },
        { name => ( scalar( @{ $self->{jobs} } ) + 1 ), code => $code }
    );
    push( @{ $self->{tests} }, $test );
}

=head2 $parallel->run()

will run and wait for all jobs added
you do not need to use this method except if you prefer to add jobs yourself and manipulate the results

=cut

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

=head2 $tp->done

    you need to call this function when you are ready to launch all jobs in bg
    this method will call run and also check results with Test::More

=cut

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

=head2 $tp->results

    get an array of results, in the same order of jobs

=cut

sub results {
    my ($self) = @_;

    my @sorted =
      map  { $self->{result}{$_} }
      sort { int($a) <=> int($b) } keys %{ $self->{result} };
    return \@sorted;
}

=head2 $tp->result

    alias to results

=cut
{
    no warnings;
    *result = \&results;
}


1;

__END__
    
