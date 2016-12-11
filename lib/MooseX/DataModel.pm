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

      next if (not exists $params->{ $att });

      my $type = $att_meta->type_constraint;
      if ($type eq 'Bool') {
        $p->{ $att } = ($params->{ $att } == 1)?1:0;
      } elsif ($type eq 'Str' or $type eq 'Num' or $type eq 'Int') {
        $p->{ $att } = $params->{ $att };
      } elsif ($type =~ m/^ArrayRef\[(.*?)\]$/){
        my $subtype = "$1";
        if ($subtype eq 'Str' or $subtype eq 'Num' or $subtype eq 'Int' or $subtype eq 'Bool') {
          $p->{ $att } = $params->{ $att };
        } else {
          $p->{ $att } = [ map { $subtype->new_from_data($_) } @{ $params->{ $att } } ];
        }
      } elsif ($type =~ m/^HashRef\[(.*?)\]$/){
        my $subtype = "$1";
        if ($subtype eq 'Str' or $subtype eq 'Num' or $subtype eq 'Int' or $subtype eq 'Bool') {
          $p->{ $att } = $params->{ $att };
        } else {
          $p->{ $att } = { map { ( $_ => $subtype->new_from_data($params->{ $att }->{ $_ }) ) } keys %{ $params->{ $att } } };
        }
      } elsif ($type->isa('Moose::Meta::TypeConstraint::Enum')){
        $p->{ $att } = $params->{ $att };
      } else {
        $p->{ $att } = $class->new_from_data("$type", $params->{ $att });
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
