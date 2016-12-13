#!/usr/bin/env perl

use Test::More;
use Test::Exception;

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

package ResolveArgs {
  use Moose::Role;

  sub MANIPARGS {
    my ($class, $ref) = @_;
    return $ref->{members}[0];
  }
}

package TestModelWithRole {
  use MooseX::DataModel;
  with 'ResolveArgs';

  key att1 => (isa => 'Str');
}

{
  my $ds = { members => [ { att1 => 'is there' } ] };

  my $model1;
  lives_ok(sub {
    $model1 = TestModelWithRole->new_from_data($ds);
  });
  cmp_ok($model1->att1, 'eq', 'is there');
}

package TestModel2SubObject {
  use MooseX::DataModel;

  sub MANIPARGS {
    my ($class, $ref) = @_;
    $ref->{ inner_att } = delete $ref->{ have_to_change_this };
    return $ref;
  }

  key inner_att => (isa => 'Str'); 
}

package TestModel2 {
  use MooseX::DataModel;

  key att1 => (isa => 'TestModel2SubObject');
}

{
  my $ds = { att1 => { have_to_change_this => 'has this value' } };

  my $model1;
  lives_ok(sub {
    $model1 = TestModel2->new_from_data($ds);
  });
  cmp_ok($model1->att1->inner_att, 'eq', 'has this value');
}


package AnObject {
  use MooseX::DataModel;

  sub MANIPARGS {
    my ($class, $ref) = @_;
    $ref->{ a } = "maniped " . $ref->{ a };
    return $ref;
  }

  key a => (isa => 'Str');
}

package TestModel3 {
  use MooseX::DataModel;
  key att1 => (isa => 'AnObject');
  array att2 => (isa => 'AnObject');
  object att3 => (isa => 'AnObject');
}

{ 
  my $ds = { att1 => { a => 'val1' }, att2 => [ { a => 'val2' } ], att3 => { 'key1' => { 'a' => 'val3' } } };
  my $model = TestModel3->new_from_data($ds);

  cmp_ok($model->att1->a, 'eq', 'maniped val1');
  cmp_ok($model->att2->[0]->a, 'eq', 'maniped val2');
  cmp_ok($model->att3->{key1}->a, 'eq', 'maniped val3');
}

done_testing;
