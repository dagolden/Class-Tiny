use 5.008001;
use strict;
use warnings;

package Echo;
use base 'Delta';

use Class::Tiny qw/baz/;

sub BUILD {
    my $self = shift;
    $self->baz( $self->bar + 1 );
}

1;
