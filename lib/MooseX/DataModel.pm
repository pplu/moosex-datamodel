package MooseX::CoercionWithParent::Role::Meta::Attribute {
  use Moose::Role;
  override _coerce_and_verify => sub {
    my $self     = shift;
    my $val      = shift;
    my $instance = shift;

    return $val unless $self->has_type_constraint;

    $val = $self->type_constraint->coerce($val,$instance)
        if $self->should_coerce && $self->type_constraint->has_coercion;

    $self->verify_against_type_constraint($val, instance => $instance);

    return $val;
  }
}
package MooseX::DataModel {
  use Moose;
  use Moose::Exporter;
  use Moose::Util::TypeConstraints qw/find_type_constraint register_type_constraint coerce subtype from via/;

  Moose::Exporter->setup_import_methods(
    with_meta => [ qw/ key array object / ],
    also => [ 'Moose', 'Moose::Util::TypeConstraints' ],
    class_metaroles => {
      attribute => ['MooseX::CoercionWithParent::Role::Meta::Attribute'],
    }
  );

  sub key {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    $properties{ is } = 'ro';

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my $type = $properties{isa};

    if (my $constraint = find_type_constraint($type)) {
      if ($constraint->isa('Moose::Meta::TypeConstraint::Class')) {
        $properties{ coerce } = 1;
        coerce $type, from 'HashRef', via {
          $type->new(%$_, parent => $_[1]) 
        } if (not $constraint->has_coercion);
      }
    } else {
      die "FATAL: Didn't find a type constraint for $key_name";
    }

    $meta->add_attribute($key_name, \%properties);
  }

  sub _alias_for_paramtype {
    my $name = shift;
    $name =~ s/\[(.*)]$/Of$1/;
    return $name;
  }

  sub object {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my ($inner_type, $type, $type_alias);

    if (ref($properties{isa})) {
      $type = find_type_constraint($properties{isa});
      die "FATAL: Didn't find a type constraint for $key_name" if (not defined $type);

      $type_alias = _alias_for_paramtype('HashRef[' . $properties{isa}->name . ']');
      $type = Moose::Meta::TypeConstraint::Parameterized->new(
        name   => $type_alias,
        parent => find_type_constraint('HashRef'),
        type_parameter => $properties{isa}
      );
      register_type_constraint($type);

      $inner_type = $properties{isa}->name;
    } else {
      $inner_type = $properties{isa};
      $type_alias = _alias_for_paramtype("HashRef[$inner_type]");

      $type = find_type_constraint("HashRef[$inner_type]");

      if (not defined $type) {
        subtype $type_alias, { as => "HashRef[$inner_type]" };
      }
    }

    my $key_isa = delete $properties{key_isa};

    my $type_constraint = find_type_constraint($inner_type);
    if (defined $type_constraint and not $type_constraint->has_coercion) {
      coerce $inner_type, from 'HashRef', via {
        return $inner_type->new(%$_, parent => $_[1]);
      }
    }

    if (not find_type_constraint($type_alias)->has_coercion) {
      coerce $type_alias, from 'HashRef', via {
        my $uncoerced = $_;
        my $coerce_routine = $type_constraint;
        return { map { ($_ => $coerce_routine->coerce($uncoerced->{$_}, $_[1])) } keys %$uncoerced }
      };
    }

    $properties{ coerce } = 1;
    $properties{ isa } = $type_alias;
    $properties{ is } = 'ro'; 

    $meta->add_attribute($key_name, \%properties);
  }

  sub array {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an array declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my ($inner_type, $type, $type_alias);

    if (ref($properties{isa})) {
      $type = find_type_constraint($properties{isa});
      die "FATAL: Didn't find a type constraint for $key_name" if (not defined $type);

      $type_alias = _alias_for_paramtype('ArrayRef[' . $properties{isa}->name . ']');
      $type = Moose::Meta::TypeConstraint::Parameterized->new(
        name   => $type_alias,
        parent => find_type_constraint('ArrayRef'),
        type_parameter => $properties{isa}
      );
      register_type_constraint($type);

      $inner_type = $properties{isa}->name;
      $properties{ isa } = $type;
    } else {
      $inner_type = $properties{isa};
      $type_alias = _alias_for_paramtype("ArrayRef[$inner_type]");

      $type = find_type_constraint($type_alias);

      if (not defined $type) {
        subtype $type_alias, { as => "ArrayRef[$inner_type]" };
      }
      $properties{ isa } = $type_alias;
    }

    my $type_constraint = find_type_constraint($inner_type);
    if (defined $type_constraint and not $type_constraint->has_coercion) {
      coerce $inner_type, from 'HashRef', via {
        return $inner_type->new(%$_, parent => $_[1]);
      }
    }

    if (not find_type_constraint($type_alias)->has_coercion) {
      coerce $type_alias, from 'ArrayRef', via {
        my $type_c = find_type_constraint($inner_type);
        my $parent = $_[1];
        if ($type_c->has_coercion) {
          return [ map { $type_c->coerce($_, $parent) } @$_ ]
        } else {
          return [ map { $_ } @$_ ]
        }
      };
    }

    $properties{ coerce } = 1;
    $properties{ is } = 'ro'; 
    $meta->add_attribute($key_name, \%properties);
  }

  sub new_from_json {
    my ($class, $json) = @_;
    require JSON;
    return $class->new(JSON::decode_json($json));
  }

}

1;
