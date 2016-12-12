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
    as_is => [ 'new_from_data' ],
    also => [ 'Moose', 'Moose::Util::TypeConstraints' ],
  );

  our $internal_types = {
    Int => 1,
    Str => 1,
    Num => 1,
    Bool => 1,
  };

  sub is_internal_type {
    return $internal_types->{ $_[0] } || 0;
  }

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

use Data::Dumper;
print Dumper($type);

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

    my $type = $properties{isa};

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
    require JSON;
    return $class->new(JSON::decode_json($json));
  }

1;
