use 5.008001;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Hotel");

subtest "attribute list" => sub {
    my $attributes = [ sort Class::Tiny->get_all_attributes_for("Hotel") ];
    is_deeply(
        $attributes, 
        [ sort qw/foo bar wibble wobble zig zag/ ],
        "attribute list correct",
    ) or diag explain $attributes;
};

subtest "attribute defaults" => sub {
    my $def = Class::Tiny->get_all_attribute_defaults_for("Hotel");
    is( keys %$def,         6,      "defaults hashref size" );
    is( $def->{foo},        undef,  "foo default is undef" );
    is( $def->{bar},        undef,  "bar default is undef" );
    is( $def->{wibble},     23,     "wibble default overrides" );
};

subtest "attribute set as list" => sub {
    my $obj = new_ok( "Hotel", [ foo => 42, bar => 23 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
    is( $obj->wibble, 23, "wibble is set" );
    is( ref $obj->wobble, 'HASH', "wobble default overrides" );
};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
