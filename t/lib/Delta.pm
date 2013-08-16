use 5.008001;
use strict;
use warnings;

package Delta;

our $counter = 0;
our $exception = 0;

use Carp ();

use Class::Tiny qw/foo bar/;

sub BUILD {
    my $self = shift;
    Carp::croak("foo must be positive")
      unless defined $self->foo && $self->foo > 0;

    $self->bar(42) unless defined $self->bar;
    $counter++;
}

sub DEMOLISH {
    my $self = shift;
    $counter--;
    $exception++ if keys %$self > 2; # Echo will delete first
}

1;
