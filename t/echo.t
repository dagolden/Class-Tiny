use 5.006;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Echo");

subtest "attribute set as list" => sub {
    my $obj = new_ok( "Echo", [ foo => 42, bar => 23 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
    is( $obj->baz, 24, "baz is set" );
};

subtest "destructor" => sub {
    no warnings 'once';
    my @objs = map { new_ok( "Echo", [ foo => 42, bar => 23 ] ) } 1 .. 3;
    is( $Delta::counter, 3, "BUILD incremented counter" );
    @objs = ();
    is( $Delta::counter,   0, "DEMOLISH decremented counter" );
    is( $Delta::exception, 0, "cleanup worked in correct order" );
};

subtest "constructor argument heuristic hiding" => sub {
    my $obj = new_ok( "Echo", [ foo => 42, bar => 23, a_method => 1 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
    is( $obj->{a_method}, 1, "hidden constructor argument still in object" );
};

subtest "exceptions" => sub {
    like(
        exception { Echo->new( foo => 0, bar => 23 ) },
        qr/foo must be positive/,
        "BUILD validation throws error",
    );

};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
