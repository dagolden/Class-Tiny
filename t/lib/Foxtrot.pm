use 5.006;
use strict;
use warnings;

package Foxtrot;

use Class::Tiny 'foo';
use Class::Tiny { bar => 42, baz => sub { time } };

1;
