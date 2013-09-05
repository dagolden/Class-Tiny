use 5.008001;
use strict;
use warnings;

package Hotel;

use base 'Golf';

use Class::Tiny {
    wibble => 23,
    wobble => sub { {} },
};

1;
