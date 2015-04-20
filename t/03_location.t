#!/usr/bin/env perl

use Test::More;
use Test::Exception;

package TestModel {
  use MooseX::DataModel;
  key att1 => (isa => 'Str', location => 'keyLoc');
  array att2 => (isa => 'Str', location => 'arrayLoc');
}

{ 
  my $ds = { att1 => 'is there' };
  my $model1 = TestModel->new_from_data($ds);

  ok(not(defined($model1->att1)), 'att2 should only be assigned via customLoc, not att2');
}

{ 
  my $ds = { keyLoc => 'is there' };
  my $model1 = TestModel->new_from_data($ds);

  cmp_ok($model1->att1, 'eq', 'is there');
}

{
  my $ds = { arrayLoc => [ 'is there' ] };
  my $model1 = TestModel->new_from_data($ds);

  cmp_ok($model1->att2->[0], 'eq', 'is there');
}

{ 
  my $ds = { att2 => [ 'is there' ] };
  my $model1 = TestModel->new_from_data($ds);

  ok(not(defined($model1->att2)), 'att2 should only be assigned via arrayLoc, not att2');
}

done_testing;
