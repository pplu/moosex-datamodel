package MooseX::DataModel {
  use Moose;
  use Moose::Exporter;
  use Moose::Util::TypeConstraints;

  Moose::Exporter->setup_import_methods(
    as_is => [ qw/ new_from_json new_from_data / ],
    with_meta => [ qw/ key array object / ],
    also => 'Moose',
  );

  #TODO: other "native" types
  sub _is_moose_native_type {
    my $type = shift;
    return ($type eq 'Str' or $type eq 'Int' or $type eq 'Num');
  }

  sub key {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    $properties{ is } = 'ro';

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my $type = $properties{isa};
    if (not _is_moose_native_type($type)) {
      $properties{ coerce } = 1;
      coerce $type, from 'HashRef', via { $type->new(%$_) };
    }

    $meta->add_attribute($key_name, \%properties);
  }

  sub object {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my $inner_type = $properties{isa};
    my $array_type = "HashRef[$properties{isa}]";
    
    if (not _is_moose_native_type($inner_type)) {
      my $subtype = "HashRefOf$properties{isa}";
      $subtype =~ s/\[//g;
      $subtype =~ s/\]//g;
      subtype $subtype, { as => $array_type };

      coerce $subtype, from 'HashRef', via { my $uncoerced = $_; return { map { ($_ => $inner_type->new(%{$uncoerced->{$_}})) } keys %$uncoerced } };
      $properties{ coerce } = 1;
      $properties{ isa } = $subtype;
    } else {
      $properties{ isa } = $array_type;
    }

    $properties{ is } = 'ro'; 

    $meta->add_attribute($key_name, \%properties);
  }

  sub array {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an array declaration" if (not defined $properties{isa});

    my $location = delete $properties{ location };
    $properties{ init_arg } = $location if ($location);

    my $inner_type = $properties{isa};
    my $array_type = "ArrayRef[$properties{isa}]";
    
    if (not _is_moose_native_type($inner_type)) {
      my $subtype = "ArrayRefOf$properties{isa}";
      $subtype =~ s/\[//g;
      $subtype =~ s/\]//g;
      subtype $subtype, { as => $array_type };

      coerce $subtype, from 'ArrayRef', via { [ map { $inner_type->new(%$_) } @$_ ] };
      $properties{ coerce } = 1;
      $properties{ isa } = $subtype;
    } else {
      $properties{ isa } = $array_type;
    }

    $properties{ is } = 'ro'; 

    $meta->add_attribute($key_name, \%properties);
  }

  sub new_from_json {
    my ($class, $json) = @_;
    require JSON;
    return new_from_data($class, JSON::decode_json($json));
  }

  sub new_from_data {
    my ($class, $data) = @_;
    return $class->new(%$data);
  }
}

1;
