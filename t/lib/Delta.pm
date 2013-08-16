use 5.008001;
use strict;
use warnings;

package Delta;

use Carp ();

use Class::Tiny qw/foo bar/;

sub BUILD {
    my $self = shift;
    Carp::croak("foo must be positive")
      unless defined $self->foo && $self->foo > 0;

    $self->bar(42) unless defined $self->bar;
}

1;
