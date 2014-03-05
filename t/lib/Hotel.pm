use 5.006;
use strict;
use warnings;

package Hotel;

use base 'Golf';

use Class::Tiny {
    wibble => 23,
    wobble => sub { {} },
};

1;
