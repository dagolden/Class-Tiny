use 5.006;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Golf");

subtest "lazy defaults" => sub {
    my $obj = new_ok("Golf");
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
    ok( !exists( $obj->{wibble} ), "lazy wibble doesn't exist" );
    ok( !exists( $obj->{wobble} ), "lazy wobble doesn't exist" );
    is( $obj->wibble,     42,      "wibble access gives default" );
    is( ref $obj->wobble, 'ARRAY', "wobble access gives default" );
    ok( exists( $obj->{wibble} ), "lazy wibble does exist" );
    ok( exists( $obj->{wobble} ), "lazy wobble does exist" );
    my $obj2 = new_ok("Golf");
    isnt( $obj->wobble, $obj2->wobble, "coderefs run for each object" );
};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
