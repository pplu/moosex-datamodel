#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use Moose::Util::TypeConstraints;

coerce 'NestedObject',
  from 'HashRef',
   via {
     use Carp;
     confess "DIE";
     NestedObject->new(parent => $_[1], a => "coerced " . $_->{ a }) 
   };

coerce 'AnObject',
  from 'HashRef',
   via {
     AnObject->new(parent => $_[1], a => "coerced " . $_->{ a }) 
   };

package NestedObject {
  use MooseX::DataModel;
  key a => (isa => 'Str');
  has parent => (is => 'ro', weak_ref => 1);
}

package AnObject {
  use MooseX::DataModel;
  key a => (isa => 'Str');
  key b => (isa => 'NestedObject');
  has parent => (is => 'ro', weak_ref => 1);
}

package TestModel {
  use MooseX::DataModel;
  key att1 => (isa => 'AnObject');
  array att2 => (isa => 'AnObject');
  object att3 => (isa => 'AnObject');
}

{ 
  my $ds = { att1 => { a => 'val1' }, att2 => [ { a => 'val2' } ], att3 => { 'key1' => { 'a' => 'val3' } } };
  my $model = TestModel->new($ds);

use Data::Dumper;
print Dumper($model);

  cmp_ok($model->att1->a, 'eq', 'coerced val1');
  ok(defined($model->att1->parent));
  cmp_ok($model->att1->parent, 'eq', $model, 'ref for parent of att1 is the model');
  cmp_ok($model->att1->b->parent, 'eq', $model->att1, 'ref for parent of b is att1');

  cmp_ok($model->att2->[0]->a, 'eq', 'coerced val2');
  ok(defined($model->att2->parent));
  cmp_ok($model->att2->parent, 'eq', $model->att2, 'ref for parent of att1 is the model');
  cmp_ok($model->att2->b->parent, 'eq', $model->att2, 'ref for parent of b is att1');
}

done_testing;
