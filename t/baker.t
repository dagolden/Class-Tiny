use 5.008001;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Baker");

subtest "attribute list" => sub {
    is_deeply(
        [ sort Class::Tiny->get_all_attributes_for("Baker") ],
        [ sort qw/foo bar baz/ ],
        "attribute list correct",
    );
};

subtest "empty list constructor" => sub {
    my $obj = new_ok("Baker");
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
    is( $obj->baz, undef, "baz is undef" );
};

subtest "empty hash object constructor" => sub {
    my $obj = new_ok( "Baker", [ {} ] );
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
    is( $obj->baz, undef, "baz is undef" );
};

subtest "subclass attribute set as list" => sub {
    my $obj = new_ok( "Baker", [ baz => 23 ] );
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
    is( $obj->baz, 23,    "baz is set " );
};

subtest "superclass attribute set as list" => sub {
    my $obj = new_ok( "Baker", [ bar => 42, baz => 23 ] );
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, 42, "bar is set" );
    is( $obj->baz, 23,    "baz is set " );
};

subtest "all attributes set as list" => sub {
    my $obj = new_ok( "Baker", [ foo => 13, bar => 42, baz => 23 ] );
    is( $obj->foo, 13, "foo is set" );
    is( $obj->bar, 42, "bar is set" );
    is( $obj->baz, 23,    "baz is set " );
};

subtest "attributes are RW" => sub {
    my $obj = new_ok( "Baker", [ { foo => 23, bar => 42 } ] );
    is( $obj->foo(24), 24, "changing foo returns new value" );
    is( $obj->foo, 24, "accessing foo returns changed value" );
    is( $obj->baz(42), 42, "changing baz returns new value" );
    is( $obj->baz, 42, "accessing baz returns changed value" );
};

subtest "exceptions" => sub {
    like(
        exception { Baker->new( foo => 23, bar => 42, baz => 13, wibble => 0 ) },
        qr/Invalid attributes for Baker: wibble/,
        "creating object with 'wibble' dies",
    );

};


done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
