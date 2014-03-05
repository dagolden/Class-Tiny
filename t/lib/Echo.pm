use 5.006;
use strict;
use warnings;

package Echo;
use base 'Delta';

use Class::Tiny qw/baz/;

sub BUILD {
    my $self = shift;
    $self->baz( $self->bar + 1 );
}

sub DEMOLISH {
    my $self = shift;
    delete $self->{baz}; # or else Delta::DEMOLISH dies
}

sub a_method { 1 }

1;
