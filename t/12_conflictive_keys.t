#!/usr/bin/env perl

use Test::More;
use Test::Exception;


package TestModel {
  use MooseX::DataModel;

  key key => (isa => 'Str');
  key array => (isa => 'Str');
  key object => (isa => 'Str');
  key has => (isa => 'Str');
  key type => (isa => 'Str');

  no MooseX::DataModel;

  __PACKAGE__->meta->make_immutable;
}

{ 
  my $ds = { key => 'exists',
             array => 'exists',
             object => 'exists',
             has => 'exists',
             type => 'exists',
  };

  my $o;
  lives_ok(sub {
    $o = TestModel->new_from_data($ds);
  });

  cmp_ok($o->key, 'eq', 'exists');
  cmp_ok($o->array, 'eq', 'exists');
  cmp_ok($o->object, 'eq', 'exists');
  cmp_ok($o->has, 'eq', 'exists');
  cmp_ok($o->type, 'eq', 'exists');
}

#TODO: test a key named "meta"

done_testing;
