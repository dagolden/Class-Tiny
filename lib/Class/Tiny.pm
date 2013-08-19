use 5.008001;
use strict;
use warnings;

package Class::Tiny;
# ABSTRACT: Minimalist class construction
# VERSION

use Carp ();

if ( $] >= 5.010 ) {
    require "mro.pm"; ## no critic: hack to hide from min version & prereq scanners
}
else {
    require MRO::Compat;
}

my %CLASS_ATTRIBUTES;

# adapted from Object::Tiny and Object::Tiny::RW
sub import {
    no strict 'refs';
    my $class = shift;
    return unless $class eq __PACKAGE__; # NOP for subclasses
    my $pkg  = caller;
    my @attr = grep {
        defined and !ref and /^[^\W\d]\w*$/s
          or Carp::croak "Invalid accessor name '$_'"
    } @_;
    $CLASS_ATTRIBUTES{$pkg}{$_} = undef for @attr;
    @{"${pkg}::ISA"} = $class unless @{"${pkg}::ISA"};
    #<<< No perltidy
    eval join "\n", ## no critic: intentionally eval'ing subs here
      "package $pkg;",
      map {
        "sub $_ { return \@_ == 1 ? \$_[0]->{$_} : (\$_[0]->{$_} = \$_[1]) }\n"
      } grep { ! *{"$pkg\::$_"}{CODE} } @attr;
    #>>>
    Carp::croak("Failed to generate $pkg") if $@;
    return 1;
}

sub new {
    my $class = shift;

    # handle hash ref or key/value arguments
    my $args;
    if ( @_ == 1 && ref $_[0] ) {
        my %copy = eval { %{ $_[0] } }; # try shallow copy
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

    # unknown attributes are fatal
    my @bad;
    my @search = @{ mro::get_linear_isa($class) };
    for my $k ( keys %$args ) {
        push @bad, $k
          unless grep { exists $CLASS_ATTRIBUTES{$_}{$k} } @search;
    }
    if (@bad) {
        Carp::croak("Invalid attributes for $class: @bad");
    }

    # create object and invoke BUILD
    my $self = bless $args, $class;
    for my $s ( reverse @search ) {
        no strict 'refs';
        my $builder = *{ $s . "::BUILD" }{CODE};
        $self->$builder if defined $builder;
    }

    return $self;
}

# Adapted from Moo
sub DESTROY {
    my $self = shift;

    for my $s ( @{ mro::get_linear_isa( ref $self ) } ) {
        no strict 'refs';
        my $demolisher = *{ $s . "::DEMOLISH" }{CODE};
        my $e          = do {
            local $?;
            local $@;
            eval { $self->$demolisher if defined $demolisher };
            $@;
        };
        no warnings 'misc'; # avoid (in cleanup) warnings
        die $e if $e;       # rethrow
    }
}

1;

=for Pod::Coverage new

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
  die "Error creating Employee: $@" if $@;

=head1 DESCRIPTION

This module offers a minimalist class construction kit in under 100 lines of
code.  Here is a list of features:

=for :list
* defines attributes via import arguments
* generates read-write accessors
* supports custom accessors
* superclass provides a standard C<new> constructor
* C<new> takes a hash reference or list of key/value pairs
* C<new> throws an error for unknown attributes
* C<new> calls C<BUILD> for each class from parent to child
* superclass provides a C<DESTROY> method
* C<DESTROY> calls C<DEMOLISH> for each class from child to parent

It uses no non-core modules (except on Perls older than 5.10, where it requires
L<MRO::Compat> from CPAN).

=head2 Why this instead of Object::Tiny or Class::Accessor or something else?

I wanted something so simple that it could potentially be used by core Perl
modules I help maintain (or hope to write), most of which either use
L<Class::Struct> or roll-their-own OO framework each time.

L<Object::Tiny> and L<Object::Tiny::RW> were close to what I wanted, but
lacking some features I deemed necessary, and their maintainers have an even
more strict philosophy against feature creep than I have.

Compared to everything else, this is smaller in implementation and simpler in
API.  (The only API is a list of attributes!)

I looked for something like it on CPAN, but after checking a dozen class
creators I realized I could implement it exactly how I wanted faster than I
could search CPAN for something merely sufficient.

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

For each item, a read-write accessor is created unless a subroutine of that
name already exists:

    $obj->name;               # getter
    $obj->name( "John Doe" ); # setter

Attribute names must be valid subroutine identifiers or an exception will
be thrown.

To make your own custom accessors, just pre-declare the method name before
loading Class::Tiny:

    package Foo::Bar;

    use subs 'id';

    use Class::Tiny qw( name id );

    sub id { ... }

By declaring C<id> also with Class::Tiny, you include it in the list
of allowed constructor parameters.

=head2 Class::Tiny is your base class

If your class B<does not> already inherit from some class, then Class::Tiny
will be added to your C<@ISA> to provide C<new> and C<DESTROY>.  (The
superclass C<import> method will silently do nothing for subclasses.)

If your class B<does> inherit from something, then no additional inheritance is
set up.  If the parent subclasses Class::Tiny, then all is well.  If not, then
you'll get accessors set up but no constructor or destructor. Don't do that
unless you really have a special need for it.

Define subclasses as normal.  It's best to define them with L<base>, L<parent>
or L<superclass> before defining attributes with Class::Tiny so the C<@ISA>
array is already populated at compile-time:

    package Foo::Bar::More;

    use parent 'Foo::Bar';

    use Class::Tiny qw( shoe_size );

=head2 Object construction

If your class inherits from Class::Tiny (as it should if you followed the
advice above), it provides the C<new> constructor for you.

Objects can be created with attributes given as a hash reference or as a list
of key/value pairs:

    $obj = Foo::Bar->new( name => "David" );

    $obj = Foo::Bar->new( { name => "David" } );

If a reference is passed as a single argument, it must be able to be
dereferenced as a hash or an exception is thrown.  A shallow copy is made of
the reference provided.

=head2 BUILD

If your class or any superclass defines a C<BUILD> method, they will be called
by the constructor from the furthest parent class down to the child class after
the object has been created.  No arguments are provided and the return value is
ignored.  Use them for validation or setting default values.

    sub BUILD {
        my $self = shift;
        $self->foo(42) unless defined $self->foo;
        croak "Foo must be non-negative" if $self->foo < 0;
    }

=head2 DEMOLISH

Class::Tiny provides a C<DESTROY> method.  If your class or any superclass
defines a C<DEMOLISH> method, they will be called from the child class to the
furthest parent class during object destruction.  No arguments are provided.
Return values and errors are ignored.

    sub DEMOLISH {
        my $self = shift;
        $self->cleanup();
    }

=cut

# vim: ts=4 sts=4 sw=4 et:
