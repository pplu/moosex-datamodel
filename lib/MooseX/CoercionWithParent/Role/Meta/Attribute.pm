package MooseX::CoercionWithParent::Role::Meta::Attribute {
  use Moose::Role;

  *{ Moose::Meta::TypeCoercion::coerce } = sub { $_[0]->_compiled_type_coercion->($_[1], $_[2]) };

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
1;
