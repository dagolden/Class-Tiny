use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;

use lib 't/lib';

require_ok("Delta");

subtest "attribute set as list" => sub {
    my $obj = new_ok( "Delta", [ foo => 42, bar => 23 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
};

subtest "destructor" => sub {
    my @objs = map { new_ok( "Delta", [ foo => 42, bar => 23 ] ) } 1 .. 3;
    is ($Delta::counter, 3, "BUILD incremented counter");
    @objs = ();
    is ($Delta::counter, 0, "DEMOLISH decremented counter");
};

subtest "exceptions" => sub {
    like(
        exception { Delta->new( foo => 0 ) },
        qr/foo must be positive/,
        "BUILD validation throws error",
    );

};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
