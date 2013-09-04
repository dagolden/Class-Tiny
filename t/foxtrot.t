use 5.008001;
use strict;
use warnings;
use lib 't/lib';

use Test::More 0.96;
use TestUtils;

require_ok("Foxtrot");

subtest "attribute list" => sub {
    is_deeply(
        [ sort Class::Tiny->get_all_attributes_for("Foxtrot") ],
        [ sort qw/foo bar baz/ ],
        "attribute list correct",
    );
};

subtest "attribute defaults" => sub {
    my $def = Class::Tiny->get_all_attribute_defaults_for("Foxtrot");
    is( keys %$def,      3,      "defaults hashref size" );
    is( $def->{foo},     undef,  "foo default is undef" );
    is( $def->{bar},     42,     "bar default is 42" );
    is( ref $def->{baz}, 'CODE', "baz default is a coderef" );
};

subtest "attribute set as list" => sub {
    my $obj = new_ok( "Foxtrot", [ foo => 42, bar => 23 ] );
    is( $obj->foo, 42, "foo is set" );
    is( $obj->bar, 23, "bar is set" );
    ok( $obj->baz, "baz is set" );
};

done_testing;
# COPYRIGHT
# vim: ts=4 sts=4 sw=4 et:
