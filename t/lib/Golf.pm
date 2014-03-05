use 5.006;
use strict;
use warnings;

package Golf;

use Class::Tiny qw/foo bar/, {
    wibble => 42,
    wobble => sub { [] },
}, qw/zig zag/;

1;
