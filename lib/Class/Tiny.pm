use 5.008001;
use strict;
no strict 'refs';
use warnings;

package Class::Tiny;
# ABSTRACT: Minimalist class construction
# VERSION

use Carp ();

# load as .pm to hide from min version scanners
require( $] >= 5.010 ? "mro.pm" : "MRO/Compat.pm" ); ## no critic:

my %CLASS_ATTRIBUTES;

sub import {
    my $class = shift;
    my $pkg   = caller;
    $class->prepare_class($pkg);
    $class->create_attributes( $pkg, @_ ) if @_;
}

sub prepare_class {
    my ( $class, $pkg ) = @_;
    @{"${pkg}::ISA"} = "Class::Tiny::Object" unless @{"${pkg}::ISA"};
}

# adapted from Object::Tiny and Object::Tiny::RW
sub create_attributes {
    my ( $class, $pkg, @spec ) = @_;
    my %defaults = map { ref $_ eq 'HASH' ? %$_ : ( $_ => undef ) } @spec;
    my @attr = grep {
        defined and !ref and /^[^\W\d]\w*$/s
          or Carp::croak "Invalid accessor name '$_'"
    } keys %defaults;
    $CLASS_ATTRIBUTES{$pkg}{$_} = $defaults{$_} for @attr;
    _gen_accessor( $pkg, $_ ) for grep { !*{"$pkg\::$_"}{CODE} } @attr;
    Carp::croak("Failed to generate attributes for $pkg: $@\n") if $@;
}

sub _gen_accessor {
    my ( $pkg, $name ) = @_;
    my $default = $CLASS_ATTRIBUTES{$pkg}{$name};

    my $sub = "sub $name { if (\@_ == 1) {";
    if ( defined $default && ref $default eq 'CODE' ) {
        $sub .= "if ( !exists \$_[0]{$name} ) { \$_[0]{$name} = \$default->(\$_[0]) }";
    }
    elsif ( defined $default ) {
        $sub .= "if ( !exists \$_[0]{$name} ) { \$_[0]{$name} = \$default }";
    }
    $sub .= "return \$_[0]{$name} } else { return \$_[0]{$name}=\$_[1] } }";

    eval "package $pkg; $sub"; ## no critic
    Carp::croak("Failed to generate attributes for $pkg: $@\n") if $@;
}

sub get_all_attributes_for {
    my ( $class, $pkg ) = @_;
    my %attr =
      map { $_ => undef }
      map { keys %{ $CLASS_ATTRIBUTES{$_} || {} } } @{ mro::get_linear_isa($pkg) };
    return keys %attr;
}

sub get_all_attribute_defaults_for {
    my ( $class, $pkg ) = @_;
    my $defaults = {};
    for my $p ( reverse @{ mro::get_linear_isa($pkg) } ) {
        while ( my ( $k, $v ) = each %{ $CLASS_ATTRIBUTES{$p} || {} } ) {
            $defaults->{$k} = $v;
        }
    }
    return $defaults;
}

package Class::Tiny::Object;
# ABSTRACT: Base class for classes built with Class::Tiny
# VERSION

my ( %LINEAR_ISA_CACHE, %BUILD_CACHE, %DEMOLISH_CACHE, %CAN_CACHE );

my $_PRECACHE = sub {
    my ($class) = @_;
    $LINEAR_ISA_CACHE{$class} =
      @{"$class\::ISA"} == 1 && ${"$class\::ISA"}[0] eq "Class::Tiny::Object"
      ? [$class]
      : mro::get_linear_isa($class);
    for my $s ( @{ $LINEAR_ISA_CACHE{$class} } ) {
        $BUILD_CACHE{$s}    = *{"$s\::BUILD"}{CODE};
        $DEMOLISH_CACHE{$s} = *{"$s\::DEMOLISH"}{CODE};
    }
    return $LINEAR_ISA_CACHE{$class};
};

sub new {
    my $class = shift;
    my $linear_isa = $LINEAR_ISA_CACHE{$class} || $_PRECACHE->($class);

    # handle hash ref or key/value arguments
    my $args;
    if ( @_ == 1 && ref $_[0] ) {
        my %copy = eval { %{ $_[0] } }; # try shallow copy
        Carp::croak("Argument to $class->new() could not be dereferenced as a hash") if $@;
        $args = \%copy;
    }
    elsif ( @_ % 2 == 0 ) {
        $args = {@_};
    }
    else {
        Carp::croak("$class->new() got an odd number of elements");
    }

    # create object and invoke BUILD
    my $self = bless {%$args}, $class;
    for my $s ( reverse @$linear_isa ) {
        next unless my $builder = $BUILD_CACHE{$s};
        $builder->( $self, $args );
    }

    # unknown attributes still in $args are fatal
    my @bad;
    for my $k ( keys %$args ) {
        push( @bad, $k )
          unless $CAN_CACHE{$class}{$k} ||= $self->can($k); # a heuristic to catch typos
    }
    Carp::croak("Invalid attributes for $class: @bad") if @bad;

    return $self;
}

# Adapted from Moo and its dependencies
require Devel::GlobalDestruction unless defined ${^GLOBAL_PHASE};

sub DESTROY {
    my $self  = shift;
    my $class = ref $self;
    my $in_global_destruction =
      defined ${^GLOBAL_PHASE}
      ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
      : Devel::GlobalDestruction::in_global_destruction();
    for my $s ( @{ $LINEAR_ISA_CACHE{$class} } ) {
        next unless my $demolisher = $DEMOLISH_CACHE{$s};
        my $e = do {
            local ( $?, $@ );
            eval { $demolisher->( $self, $in_global_destruction ) };
            $@;
        };
        no warnings 'misc'; # avoid (in cleanup) warnings
        die $e if $e;       # rethrow
    }
}

1;

=for Pod::Coverage
new get_all_attributes_for get_all_attribute_defaults_for
prepare_class create_attributes

=head1 SYNOPSIS

In F<Person.pm>:

  package Person;

  use Class::Tiny qw( name );

  1;

In F<Employee.pm>:

  package Employee;
  use parent 'Person';

  use Class::Tiny qw( ssn ), {
    timestamp => sub { time }   # attribute with default
  };

  1;

In F<example.pl>:

  use Employee;

  my $obj = Employee->new( name => "Larry", ssn => "111-22-3333" );

  # unknown attributes are fatal:
  eval { Employee->new( name => "Larry", OS => "Linux" ) };
  die "Error creating Employee: $@" if $@;

=head1 DESCRIPTION

This module offers a minimalist class construction kit in around 120 lines of
code.  Here is a list of features:

=for :list
* defines attributes via import arguments
* generates read-write accessors
* supports lazy attribute defaults
* supports custom accessors
* superclass provides a standard C<new> constructor
* C<new> takes a hash reference or list of key/value pairs
* C<new> has heuristics to catch constructor attribute typos
* C<new> calls C<BUILD> for each class from parent to child
* superclass provides a C<DESTROY> method
* C<DESTROY> calls C<DEMOLISH> for each class from child to parent

It uses no non-core modules for any recent Perl. On Perls older than v5.10 it
requires L<MRO::Compat>. On Perls older than v5.14, it requires
L<Devel::GlobalDestruction>.

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

For each attribute, a read-write accessor is created unless a subroutine of that
name already exists:

    $obj->name;               # getter
    $obj->name( "John Doe" ); # setter

Attribute names must be valid subroutine identifiers or an exception will
be thrown.

You can specify lazy defaults by defining attributes with a hash reference.
Keys define attribute names and values are constants or code references that
will be evaluated when the attribute is first accessed if no value has been
set.  The object is passed as an argument to a code reference.

    package Foo::WithDefaults;

    use Class::Tiny qw/name id/, {
        title     => 'Peon',
        skills    => sub { [] },
        hire_date => sub { $_[0]->_build_hire_date }, 
    };

To make your own custom accessors, just pre-declare the method name before
loading Class::Tiny:

    package Foo::Bar;

    use subs 'id';

    use Class::Tiny qw( name id );

    sub id { ... }

By declaring C<id> also with Class::Tiny, you include it in the list of known
attributes for introspection.  Default values will not be set for custom
accessors unless you handle that yourself.

=head2 Class::Tiny::Object is your base class

If your class B<does not> already inherit from some class, then
Class::Tiny::Object will be added to your C<@ISA> to provide C<new> and
C<DESTROY>.

If your class B<does> inherit from something, then no additional inheritance is
set up.  If the parent subclasses Class::Tiny::Object, then all is well.  If
not, then you'll get accessors set up but no constructor or destructor. Don't
do that unless you really have a special need for it.

Define subclasses as normal.  It's best to define them with L<base>, L<parent>
or L<superclass> before defining attributes with Class::Tiny so the C<@ISA>
array is already populated at compile-time:

    package Foo::Bar::More;

    use parent 'Foo::Bar';

    use Class::Tiny qw( shoe_size );

=head2 Object construction

If your class inherits from Class::Tiny::Object (as it should if you followed
the advice above), it provides the C<new> constructor for you.

Objects can be created with attributes given as a hash reference or as a list
of key/value pairs:

    $obj = Foo::Bar->new( name => "David" );

    $obj = Foo::Bar->new( { name => "David" } );

If a reference is passed as a single argument, it must be able to be
dereferenced as a hash or an exception is thrown.  A shallow copy is made of
the reference provided.

In order to help catch typos in constructor arguments, any argument that it is
not also a valid method (e.g. an accessor or other method) will result in a
fatal exception.  This is not perfect, but should catch typical transposition
typos. Also see L</BUILD> for how to explicitly hide non-attribute, non-method
arguments if desired.

=head2 BUILD

If your class or any superclass defines a C<BUILD> method, it will be called
by the constructor from the furthest parent class down to the child class after
the object has been created.

It is passed the constructor arguments as a hash reference.  The return value
is ignored.  Use C<BUILD> for validation or setting default values.

    sub BUILD {
        my ($self, $args) = @_;
        $self->foo(42) unless defined $self->foo;
        croak "Foo must be non-negative" if $self->foo < 0;
    }

If you want to hide a non-attribute constructor argument from validation,
delete it from the passed-in argument hash reference.

    sub BUILD {
        my ($self, $args) = @_;

        if ( delete $args->{do_something_special} ) {
            ...
        }
    }

The argument reference is a copy, so deleting elements won't affect data in the
object. You have to delete it from both if that's what you want.

    sub BUILD {
        my ($self, $args) = @_;

        if ( delete $args->{do_something_special} ) {
            delete $self->{do_something_special};
            ...
        }
    }

=head2 DEMOLISH

Class::Tiny provides a C<DESTROY> method.  If your class or any superclass
defines a C<DEMOLISH> method, they will be called from the child class to the
furthest parent class during object destruction.  It is provided a single
boolean argument indicating whether Perl is in global destruction.  Return
values and errors are ignored.

    sub DEMOLISH {
        my ($self, $global_destruct) = @_;
        $self->cleanup();
    }

=head2 Introspection and internals

You can retrieve an unsorted list of valid attributes known to Class::Tiny
for a class and its superclasses with the C<get_all_attributes_for> class
method.

    my @attrs = Class::Tiny->get_all_attributes_for("Employee");
    # returns qw/name ssn timestamp/

Likewise, a hash reference of all valid attributes and default values (or code
references) may be retrieved with the C<get_all_attribute_defaults_for> class
method.  Any attributes without a default will be C<undef>.

    my $def = Class::Tiny->get_all_attribute_defaults_for("Employee");
    # returns {
    #   name => undef,
    #   ssn => undef
    #   timestamp => $coderef
    # }

The C<import> method uses two class methods, C<prepare_class> and
C<create_attributes> to set up the C<@ISA> array and attributes.  Anyone
attempting to extend Class::Tiny itself should use these instead of mocking up
a call to C<import>.

When the first object is created, linearized C<@ISA> and various subroutines
references are cached for speed.  Ensure that all inheritance and methods are
in place before creating objects. (You don't want to be changing that once you
create objects anyway, right?)

=head1 RATIONALE

=head2 Why this instead of Object::Tiny or Class::Accessor or something else?

I wanted something so simple that it could potentially be used by core Perl
modules I help maintain (or hope to write), most of which either use
L<Class::Struct> or roll-their-own OO framework each time.

L<Object::Tiny> and L<Object::Tiny::RW> were close to what I wanted, but
lacking some features I deemed necessary, and their maintainers have an even
more strict philosophy against feature creep than I have.

I looked for something like it on CPAN, but after checking a dozen class
creators I realized I could implement it exactly how I wanted faster than I
could search CPAN for something merely sufficient.  Compared to everything
else, this is smaller in implementation and simpler in API.

=head2 Why this instead of Moose or Moo?

L<Moose> and L<Moo> are both excellent OO frameworks.  Moose offers a powerful
meta-object protocol (MOP), but is slow to start up and has about 30 non-core
dependencies including XS modules.  Moo is faster to start up and has about 10
pure Perl dependencies but provides no true MOP, relying instead on its ability
to transparently upgrade Moo to Moose when Moose's full feature set is
required.

By contrast, Class::Tiny has no MOP and has B<zero> non-core dependencies for
Perls in the L<support window|perlpolicy>.  It has far less code, less
complexity and no learning curve. If you don't need or can't afford what Moo or
Moose offer, this is a intended to be a reasonable fallback.

That said, Class::Tiny offers Moose-like conventions for things like C<BUILD>
and C<DEMOLISH> for some minimal interoperability and an easier upgrade path.

=cut

# vim: ts=4 sts=4 sw=4 et:
