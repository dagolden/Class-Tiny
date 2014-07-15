use 5.006;
use strict;
use warnings;

package Charlie;

use subs qw/bar baz/;

use Class::Tiny qw/foo bar/, { baz => 23 };

sub bar {
    my $self = shift;
    if (@_) {
        $self->{bar} = [@_];
    }
    return $self->{bar};
}

sub baz {
    my $self = shift;
    if (@_) {
        $self->{baz} = shift;
    }
    return $self->{baz} ||=
      Class::Tiny->get_all_attribute_defaults_for( ref $self )->{baz};
}

1;
