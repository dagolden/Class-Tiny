use 5.008001;
use strict;
use warnings;

package Foxtrot;

use Class::Tiny 'foo';
use Class::Tiny { bar => 42, baz => sub { time } };

1;
