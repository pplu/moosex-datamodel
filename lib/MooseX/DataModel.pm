package MooseX::DataModel {
  use Moose;
  use Moose::Exporter;
  use Moose::Util::TypeConstraints;

  Moose::Exporter->setup_import_methods(
    as_is => [ qw/ new_from_json new_from_data / ],
    with_meta => [ qw/ key array / ],
    also => 'Moose',
  );

  sub key {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an object declaration" if (not defined $properties{isa});

    $properties{ is } = 'ro';

    my $type = $properties{isa};
    #TODO: other "native" types
    if ($type ne 'Str' and $type ne 'Int' and $type ne 'Num') {
      $properties{ coerce } = 1;
      coerce $type, from 'HashRef', via { $type->new(%$_) };
    }

    $meta->add_attribute($key_name, \%properties);
  }

  sub array {
    my ($meta, $key_name, %properties) = @_;

    die "Must specify isa in an array declaration" if (not defined $properties{isa});

    my $inner_type = $properties{isa};
    my $orig_type = "ArrayRef[$properties{isa}]";
    
    my $subtype = "ArrayRefOf$properties{isa}";
    $subtype =~ s/\[//g;
    $subtype =~ s/\]//g;
    subtype $subtype, { as => $orig_type };
    coerce $subtype, from 'ArrayRef', via { [ map { $inner_type->new(%$_) } @$_ ] };

    $properties{ isa } = $subtype;
    $properties{ is } = 'ro'; 
    $properties{ coerce } = 1;

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
