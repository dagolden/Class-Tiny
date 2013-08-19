use 5.008001;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Foxtrot");

subtest "attribute set as list" => sub {
    my $obj = new_ok( "Foxtrot", [ foo => 42, bar => 23 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
