package MooseX::DataModel;
  use Moose;
  use Moose::Exporter;
  use Moose::Util qw//;
  use Moose::Util::TypeConstraints qw/find_type_constraint/;
  use Moose::Meta::TypeConstraint::Parameterized;
  use Ref::Util qw/is_blessed_ref/;
  use Carp;

  Moose::Exporter->setup_import_methods(
    with_meta => [ qw/ key array object / ],
    as_is => [ 'new_from_data', 'new_from_json' ],
    also => [ 'Moose', 'Moose::Util::TypeConstraints' ],
  );

  sub inflate_scalar {
    my ($t_name, $value) = @_;
    if ($t_name->isa('Moose::Object')) {
      return new_from_data($t_name, $value);
    } elsif ($t_name eq 'Bool') {
      return ($value == 1)?1:0;
    } else { 
      return $value;
    }
  }

  sub new_from_data {
    my ($class, $params) = @_;

    my $meta = Moose::Util::find_meta($class) or die "Didn't find metaclass for '$class'";

    $params = $class->MANIPARGS($params) if ($class->can('MANIPARGS'));

    my $p = {};
    foreach my $att_meta ($meta->get_all_attributes) {
      my $att;
      if ($att_meta->has_init_arg) {
        $att = $att_meta->init_arg;
      } else {
        $att = $att_meta->name;
      }

      # the user might want to initialize the attribute to undef, so we use exists
      next if (not exists $params->{ $att });

      my $type = $att_meta->type_constraint;

      # Enum and Parametrized have to be tested before a plain TypeConstraint, since they are subclasses
      # of TypeConstraint, so they would 
      if ($type->isa('Moose::Meta::TypeConstraint::Enum')) {
        $p->{ $att } = $params->{ $att };
      } elsif ($type->isa('Moose::Meta::TypeConstraint::Parameterized')) {
        my $parametrized_type = $type->parent->name;
        my $inner_type = $type->type_parameter->name;
        if ($parametrized_type eq 'ArrayRef') {
          $p->{ $att } = [ map { inflate_scalar($inner_type, $_) } @{ $params->{ $att } } ];
        } elsif ($parametrized_type eq 'HashRef') {
          $p->{ $att } = { map { ( $_ => inflate_scalar($inner_type, $params->{ $att }->{ $_ }) ) } keys %{ $params->{ $att } } };
        } else {
          die "Don't know how to treat parametrized type $parametrized_type for inner type $inner_type";
        }
      } elsif ($type->isa('Moose::Meta::TypeConstraint')) {
        $p->{ $att } = inflate_scalar($type->name, $params->{ $att });
      } else {
        die "Don't know what to do with a type of $type";
      }
    }
    return $class->new($p);
  }


  sub key {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    $properties{ is } = 'ro';

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    $meta->add_attribute($key_name, \%properties);
  }

  sub object {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my ($inner_type, $type);

    if (is_blessed_ref($properties{isa})) {
      my $constraint = Moose::Meta::TypeConstraint::Parameterized->new(
        parent => find_type_constraint('HashRef'),
        type_parameter => $properties{isa},
      );
      $properties{ isa } = $constraint;
    } else {
      $inner_type = $properties{isa};
      $properties{ isa } = "HashRef[$inner_type]";
    }

    my $key_isa = delete $properties{key_isa};

    $properties{ is } = 'ro'; 

    $meta->add_attribute($key_name, \%properties);
  }

  sub array {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an array declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my ($inner_type, $type);

    if (is_blessed_ref($properties{isa})) {
      my $constraint = Moose::Meta::TypeConstraint::Parameterized->new(
        parent => find_type_constraint('ArrayRef'),
        type_parameter => $properties{isa},
      );
      $properties{ isa } = $constraint;
    } else {
      $inner_type = $properties{isa};
      $properties{ isa } = "ArrayRef[$inner_type]";
    }

    $properties{ is } = 'ro'; 
    $meta->add_attribute($key_name, \%properties);
  }

  sub new_from_json {
    my ($class, $json) = @_;
    require JSON::MaybeXS;
    return $class->new_from_data(JSON::MaybeXS::decode_json($json));
  }

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

MooseX::DataModel - Create object models from datastructures

=head1 SYNOPSIS

  package MyModel {
    use MooseX::DataModel;

    version => (isa => 'Int');
    description => (isa => 'Str', required => 1);

    sub do_something {
      my $self = shift;
      if(shift->version == 3) ... 
    }
    # Moose is imported for your convenience 
    has foo => (...);
  }

  my $obj = MyModel->MooseX::DataModel::new_from_json('{"version":3,"description":"a json document"}');
  # $obj is just a plain old Moose object
  print $obj->version;

  my $obj = MyModel->new({ version => 6, description => 'A description' });
  $obj->do_something;

=head1 DESCRIPTION

Working with "plain datastructures" (nested hashrefs, arrayrefs and scalars) that come from other 
systems can be a pain.

Normally those datastructures are not arbitrary: they have some structure to them: most of them 
come to express "object like" things. MooseX::DataModel tries to make converting these datastructures
into objects in an easy, declarative fashion.

Lots of times

MooseX::DataModel also helps you validate the datastructures. If you get an object back, it conforms
to your object model. So if you declare a required key, and the passed datastructure doesn't contain 
it: you will get an exception. If the type of the key passed is different from the one declared: you
get an exception. The advantage over using a JSON validator, is that after validation you still have
your original datastructure. With MooseX::DataModel you get full-blown objects, to which you can
attach logic.

=head1 USAGE

Just use MooseX::DataModel in a class. It will import three keywords C<key>, C<array>, C<object>.
With these keywords we can specify attributes in our class

=head2 key attribute => (isa => $type, [required => 1, location => $location])

Declares an attribute named "attribute" that is of type $type. $type can be a string with a
Moose type constraint (Str, Int), or any user defined subtype (MyPositiveInt). Also it can 
be the name of a class. If it's a class, MooseX::DataModel will coerce a HashRef to the 
specified class (using the HashRef as the objects' constructor parameters).

  package VersionObject {
    use MooseX::DataModel;
    key major => (isa => 'Int');
    key minor => (isa => 'Int');
  }
  package MyObject {
    use MooseX::DataModel;
    key version => (isa => 'VersionObject');
  }

  my $o = MyObject->MooseX::DataModel::new_from_json('{"version":{"major":3,"minor":5}}');
  # $o->version->isa('VersionObject') == true
  print $o->version->major;
  # prints 3
  print $o->version->minor;
  # prints 5

required => 1: declare that this attribute is obliged to be set in the passed datastructure

  package MyObject {
    use MooseX::DataModel;
    key version => (isa => 'Int', required => 1);
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"document_version":3}');
  # exception, since "version" doesn't exist
  
  my $o = MyObject->MooseX::DataModel::new_from_json('{"version":3}');
  print $o->version;
  # prints 3

location => $location: $location is a string that specifies in what key of the datastructure to 
find the attributes' value:

  package MyObject {
    use MooseX::DataModel;
    key Version => (isa => 'Int', location => 'document_version');
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"document_version":3}');
  print $o->Version;
  # prints 3

=head2 array attribute => (isa => $type, [required => 1, location => $location])

Declares an attribute that holds an array whose elements are of a certain type.

$type, required and location work as in "key"

  package MyObject {
    use MooseX::DataModel;
    key name => (isa => 'Str', required => 1);
    array likes => (isa => 'Str', required => 1, location => 'his_tastes');
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"name":"pplu":"his_tastes":["cars","ice cream"]}");
  print $o->likes->[0];
  # prints 'cars'

=head2 object attribute => (isa => $type, [required => 1, location => $location])

Declares an attribute that holds an hash ("JS object") whose elements are of a certain type. This
is useful when in the datastructure you have a hash with arbitrary keys (for known keys you would
describe an object with the "key" keyword.

$type, required and location work as in "key"

  package MyObject {
    use MooseX::DataModel;
    key name => (isa => 'Str', required => 1);
    object likes => (isa => 'Int', required => 1, location => 'his_tastes');
  }
  my $o = MyObject->MooseX::DataModel::new_from_json('{"name":"pplu":"his_tastes":{"cars":9,"ice cream":6}}");
  print $o->likes->{ cars };
  # prints 9

=head1 METHODS

=head2 new

Your class gets the default Moose constructor. You can pass it a hashref with the datastructure

  my $o = MyObject->new({ name => 'pplu', his_tastes => { cars => 9, 'ice cream' => 6 }});

=head2 MooseX::DataModel::from_json

There is a convenience constructor for parsing a JSON (so you don't have to do it from the outside)

  my $o = MyObject->MooseX::DataModel::from_json("JSON STRING");

=head1 INNER WORKINGS

All this can be done with plain Moose, using subtypes, coercions and declaring the 
appropiate attributes (that's what really happens on the inside, although it's not guaranteed
to stay that way forever). MooseX::DataModel just wants to help you write less code :)

=head1 BUGS and SOURCE

The source code is located here: https://github.com/pplu/moosex-datamodel

Please report bugs to:

=head1 COPYRIGHT and LICENSE

    Copyright (c) 2015 by CAPSiDE

    This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
