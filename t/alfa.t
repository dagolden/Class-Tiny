use 5.006;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Alfa");

subtest "empty list constructor" => sub {
    my $obj = new_ok("Alfa");
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
};

subtest "empty hash object constructor" => sub {
    my $obj = new_ok( "Alfa", [ {} ] );
    is( $obj->foo, undef, "foo is undef" );
    is( $obj->bar, undef, "bar is undef" );
};

subtest "one attribute set as list" => sub {
    my $obj = new_ok( "Alfa", [ foo => 23 ] );
    is( $obj->foo, 23,    "foo is set" );
    is( $obj->bar, undef, "bar is undef" );
};

subtest "one attribute set as hash ref" => sub {
    my $obj = new_ok( "Alfa", [ { foo => 23 } ] );
    is( $obj->foo, 23,    "foo is set" );
    is( $obj->bar, undef, "bar is undef" );
};

subtest "both attributes set as list" => sub {
    my $obj = new_ok( "Alfa", [ foo => 23, bar => 42 ] );
    is( $obj->foo, 23, "foo is set" );
    is( $obj->bar, 42, "bar is set" );
};

subtest "both attributes set as hash ref" => sub {
    my $obj = new_ok( "Alfa", [ { foo => 23, bar => 42 } ] );
    is( $obj->foo, 23, "foo is set" );
    is( $obj->bar, 42, "bar is set" );
};

subtest "constructor makes shallow copy" => sub {
    my $fake = bless { foo => 23, bar => 42 }, "Fake";
    my $obj = new_ok( "Alfa", [$fake] );
    is( ref $fake, "Fake", "object passed to constructor is original class" );
    is( $obj->foo, 23,     "foo is set" );
    is( $obj->bar, 42,     "bar is set" );
};

subtest "attributes are RW" => sub {
    my $obj = new_ok( "Alfa", [ { foo => 23, bar => 42 } ] );
    is( $obj->foo(24), 24, "changing foo returns new value" );
    is( $obj->foo,     24, "accessing foo returns changed value" );
};

subtest "unknown attributes stripped" => sub {
    my $obj = new_ok( "Alfa", [ { wibble => 1 } ], "new( wibble => 1 )" );
    ok( !exists $obj->{wibble}, "unknown attribute 'wibble' not in object" );
};

subtest "exceptions" => sub {
    like(
        exception { Alfa->new(qw/ foo bar baz/) },
        qr/Alfa->new\(\) got an odd number of elements/,
        "creating object with odd elements dies",
    );

    like(
        exception { Alfa->new( [] ) },
        qr/Argument to Alfa->new\(\) could not be dereferenced as a hash/,
        "creating object with array ref dies",
    );
};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
