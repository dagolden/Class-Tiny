use 5.008001;
use strict;
use warnings;

package Class::Tiny;
# ABSTRACT: Minimalist class construction
# VERSION

use Carp ();

if ( $] >= 5.010 ) {
    require "mro.pm"; # hack to hide from perl minimum version & prereq scanners
}
else {
    require MRO::Compat;
}

my %CLASS_ATTRIBUTES;

# adapted from Object::Tiny and Object::Tiny::RW
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
    Carp::croak( "Failed to generate $pkg" ) if $@;
    return 1;
}

sub new {
    my $class = shift;
    my $args;
    if ( @_ == 1 && ref $_[0] ) { # hope it's a hash or hash object
        my %copy = eval { %{ $_[0] } }; # shallow copy
        if ($@) {
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
    my @search = @{ mro::get_linear_isa($class) };
    for my $k ( keys %$args ) {
        push @bad, $k
          unless grep { $CLASS_ATTRIBUTES{$_}{$k} } @search;
    }
    if (@bad) {
        Carp::croak("Invalid attributes for $class: @bad");
    }
    return bless $args, $class;
}

1;

=for Pod::Coverage method_names_here

=head1 SYNOPSIS

In F<Person.pm>:

  package Person;

  use Class::Tiny qw( name );

  1;

In F<Employee.pm>:

  package Employee;
  use parent 'Person';

  use Class::Tiny qw( ssn );

  1;

In F<example.pl>:

  use Employee;

  my $obj = Employee->new( name => "Larry", ssn => "111-22-3333" );

  # unknown attributes are fatal:
  eval { Employee->new( name => "Larry", OS => "Linux" ) };

=head1 DESCRIPTION

This module offers a minimalist class construction kit in under 100 lines of
code.  Here is a list of features:

=for :list
* defines attributes via import arguments
* generates accessors for all attributes
* superclass provides a standard C<new> constructor
* C<new> takes a hash reference or list of key/value pairs
* C<new> throws an error for unknown attributes
* may be subclassed

It uses no non-core modules (except on Perls older than 5.10, where it requires
L<MRO::Compat> from CPAN).

=head2 Why this instead of Object::Tiny or Class::Accessor or something else?

I wanted something so simple that it could be potentially used by core Perl
modules I help maintain, most of which either use L<Class::Struct> or
roll-their-own OO framework for each one.

L<Object::Tiny> and L<Object::Tiny::RW> were close to what I wanted, but
lacking some features I deemed necessary, and their maintainers have an even
more strict philsophy against feature creep that I have.

Compared to everything else, this is smaller in implmentation and simpler in
API.  (The only API is a list of attributes!)

=head1 USAGE

=head2 Defining attributes

Define attributes as a list of import arguments:

    package Foo::Bar;

    use Class::Tiny qw(
        name
        id
        height
        weight
    );

For each item, a read-write accessor is created:

    $obj->name( "John Doe" );

Attribute names must be valid subroutine identifiers or an exception will
be thrown.

=head2 Subclassing

Define subclasses as normal.  It's best to define them with L<base>, L<parent>
or L<superclass> before defining attributes with Class::Tiny so the C<@ISA>
array is populated at compile-time:

    package Foo::Bar::More;

    use parent 'Foo::Bar';

    use Class::Tiny qw( shoe_size );

If your class does not already inherit from some class, then Class::Tiny will
be added to your C<@ISA> to provide C<new>.

If your class B<does> inherit from something, then no additional inheritance is
set up.  If the parent subclasses Class::Tiny, then all is well.  If not, then
you'll get accessors set up but no constructor (or features that come with it
like attribute validation).  Don't do that unless you really have a special
need for it.

=head2 Object construction

If your class inherits from Class::Tiny (which it will by default), it provides
the C<new> constructor for you.

Object can be created with attributes given as a hash reference or as a list
of key/value pairs:

    $obj = Foo::Bar->new( name => "David" );

    $obj = Foo::Bar->new( { name => "David" } );

If a reference is passed as a single argument, it must be dereferenceable as a
hash or an exception is thrown.  A shallow copy is made of the reference provided.

=head2 BUILD

To be implemented...

=head2 DEMOLISH

To be implemented...

=cut

# vim: ts=4 sts=4 sw=4 et:
