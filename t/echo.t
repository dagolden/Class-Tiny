use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;

use lib 't/lib';

require_ok("Echo");

subtest "attribute set as list" => sub {
    my $obj = new_ok( "Echo", [ foo => 42, bar => 23 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
    is( $obj->baz, 24, "baz is set" );
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
