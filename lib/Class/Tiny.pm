use 5.008001;
use strict;
use warnings;

package Class::Tiny;
# ABSTRACT: Minimalist class construction
# VERSION

use Carp ();
if ($] >= 5.010) {
  require "mro.pm"; # hack to hide from perl minimum version & prereq scanners
} else {
  require MRO::Compat;
}

my %CLASS_ATTRIBUTES;

sub import {
    no strict 'refs';
    my $class = shift;
    my $pkg   = caller;
    my @attr  = @_;
    $CLASS_ATTRIBUTES{$pkg} = { map { $_ => 1 } @attr };
    my $child = !!@{"${pkg}::ISA"};
    eval join "\n",
      "package $pkg;", ( $child ? () : "\@${pkg}::ISA = 'Class::Tiny';" ), map {
        defined and !ref and /^[^\W\d]\w*$/s
          or Carp::croak "Invalid accessor name '$_'";
        "sub $_ { if (\@_ > 1) { \$_[0]->{$_} = \$_[1] } ; return \$_[0]->{$_} }\n"
      } @attr;
    die "Failed to generate $pkg" if $@;
    return 1;
}

sub new {
    my $class = shift;
    my $args;
    if ( @_ == 1 && ref $_[0] ) { # hope it's a hash or hash object
        my %copy = eval { %{ $_[0] } };   # shallow copy
        if ( $@ ) {
            Carp::croak("Argument to $class->new() could not be dereferenced as a hash");
        }
        $args = \%copy;
    }
    elsif ( @_ % 2 == 0 ) {
        $args = {@_};
    }
    else {
        Carp::croak("$class->new() got an odd number of elements");
    }
    my @bad;
    for my $k ( keys %$args ) {
        push @bad, $k unless $CLASS_ATTRIBUTES{$class}{$k};
    }
    if (@bad) {
        Carp::croak("Invalid attributes for $class: @bad");
    }
    return bless $args, $class;
}

1;

=for Pod::Coverage method_names_here

=head1 SYNOPSIS

  package MyClass;

  use Class::Tiny qw( name color );

  1;

  package main;

  MyClass->new( name => "Larry", color => "orange" );


=head1 DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

This is inspired by L<Object::Tiny::RW> with just a couple more features
to make it useful for class hierarchies.

=head1 USAGE

Good luck!

=head1 SEE ALSO

Maybe other modules do related things.

=cut

# vim: ts=4 sts=4 sw=4 et:
