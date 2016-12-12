#!/usr/bin/env perl

use Test::More;
use Test::Exception;

package ResolveArgs {
  use Moose::Role;

  sub BUILDARGS {
    my ($class, $args) = @_;
    return $args->{members}[0];
  }
}

package TestModel {
  use MooseX::DataModel;
  #with 'ResolveArgs';

  sub MANIPARGS {
    my ($class, $ref) = @_;
    return $ref->{members}[0];
  }

  key att1 => (isa => 'Str');
}

{
  my $ds = { members => [ { att1 => 'is there' } ] };

  my $model1;
  lives_ok(sub {
    $model1 = TestModel->new_from_data($ds);
  });
  cmp_ok($model1->att1, 'eq', 'is there');
}

done_testing;
