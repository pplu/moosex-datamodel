package MooseX::DataModel;
  use Moose;
  use Moose::Exporter;
  use Moose::Util qw//;
  use Moose::Util::TypeConstraints qw/find_type_constraint/;
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

  sub new_from_data {
    my ($class, $params) = @_;

    my $meta = Moose::Util::find_meta($class) or die "Didn't find metaclass for $class";
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
          if (is_internal_type($inner_type)) {
            #TODO: Bools should be processed as in TypeConstraint
            $p->{ $att } = $params->{ $att };
          } else {
            $p->{ $att } = [ map { $inner_type->new_from_data($_) } @{ $params->{ $att } } ];
          }
        } elsif ($parametrized_type eq 'HashRef') {
          if (is_internal_type($inner_type)) {
            #TODO: Bools should be processed as in TypeConstraint
            $p->{ $att } = $params->{ $att };
          } else {
            $p->{ $att } = { map { ( $_ => $inner_type->new_from_data($params->{ $att }->{ $_ }) ) } keys %{ $params->{ $att } } };
          }
        } else {
          die "Don't know how to treat parametrized type $parametrized_type for inner type $inner_type";
        }
      } elsif ($type->isa('Moose::Meta::TypeConstraint')) {
        my $t_name = $type->name;
        if ($t_name eq 'Bool') {
          $p->{ $att } = ($params->{ $att } == 1)?1:0;
        } elsif (is_internal_type($t_name)) {
          $p->{ $att } = $params->{ $att };
        } else {
          die "Don't know how to treat type $t_name";
        }
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

    if (ref($properties{isa})) {
      $type = find_type_constraint($properties{isa});
      die "FATAL: Didn't find a type constraint for $key_name" if (not defined $type);

      $properties{ isa } = 'HashRef[' . $properties{isa}->name . ']';
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

    if (ref($properties{isa})) {
      $type = find_type_constraint($properties{isa});
      die "FATAL: Didn't find a type constraint for $key_name" if (not defined $type);

      $properties{ isa } = 'ArrayRef[' . $properties{isa}->name . ']';
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
