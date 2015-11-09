#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use Moose::Util::TypeConstraints;

subtype 'ST1',
     as 'Str';

coerce 'ST1',
  from 'Str',
   via { "ST1: $_" };

package TestModel {
  use MooseX::DataModel;
  key att1 => (isa => 'ST1');
  array att2 => (isa => 'ST1');
  object att3 => (isa => 'ST1');
}

{ 
  my $ds = { att1 => 'val1', att2 => [ 'val2' ], att3 => { 'val3' => 1 } };
  my $model = TestModel->new($ds);

  cmp_ok($model->att1, 'eq', 'ST1: val1');

  use Data::Dumper;
  print Dumper($model);
}

done_testing;
