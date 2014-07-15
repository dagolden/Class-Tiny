use 5.006;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Juliett");

subtest "attribute list" => sub {
    is_deeply(
        [ sort Class::Tiny->get_all_attributes_for("Juliett") ],
        [ sort qw/foo bar baz qux kit/ ],
        "attribute list correct",
    );
};

subtest "empty list constructor" => sub {
    my $obj = new_ok("Juliett");
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
    is( $obj->baz, undef, "baz is undef" );
    is( $obj->qux, undef, "qux is undef" );
    is( $obj->kit, undef, "kit is undef" );
};

subtest "empty hash object constructor" => sub {
    my $obj = new_ok( "Juliett", [ {} ] );
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
    is( $obj->baz, undef, "baz is undef" );
    is( $obj->qux, undef, "qux is undef" );
    is( $obj->kit, undef, "kit is undef" );
};

subtest "subclass attribute set as list" => sub {
    my $obj = new_ok( "Juliett", [ kit => 23 ] );
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
    is( $obj->qux, undef, "baz is undef" );
    is( $obj->qux, undef, "qux is undef" );
    is( $obj->kit, 23,    "kit is set" );
};

subtest "superclass attribute set as list" => sub {
    my $obj = new_ok( "Juliett", [ bar => 42, baz => 23, qux => 13, kit => 31 ] );
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, 42,    "bar is set" );
    is( $obj->baz, 23,    "baz is set" );
    is( $obj->qux, 13,    "qux is set" );
    is( $obj->kit, 31,    "kit is set" );
};

subtest "all attributes set as list" => sub {
    my $obj =
      new_ok( "Juliett", [ foo => 13, bar => 42, baz => 23, qux => 11, kit => 31 ] );
    is( $obj->foo, 13, "foo is set" );
    is( $obj->bar, 42, "bar is set" );
    is( $obj->baz, 23, "baz is set" );
    is( $obj->qux, 11, "qux is set" );
    is( $obj->kit, 31, "kit is set" );
};

subtest "attributes are RW" => sub {
    my $obj = new_ok( "Juliett", [ { foo => 23, bar => 42 } ] );
    is( $obj->foo(24), 24, "changing foo returns new value" );
    is( $obj->foo,     24, "accessing foo returns changed value" );
    is( $obj->baz(42), 42, "changing baz returns new value" );
    is( $obj->baz,     42, "accessing baz returns changed value" );
    is( $obj->qux(11), 11, "changing qux returns new value" );
    is( $obj->qux,     11, "accessing qux returns changed value" );
    is( $obj->kit(31), 31, "changing kit returns new value" );
    is( $obj->kit,     31, "accessing kit rerutns changed value" );
};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
