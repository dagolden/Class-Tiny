use 5.008001;
use strict;
use warnings;

package Charlie;

use subs qw/bar/;

use Class::Tiny qw/foo bar/;

sub bar {
    my $self = shift;
    if (@_) {
        $self->{bar} = [@_];
    }
    return $self->{bar};
}

1;
