#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use Moose::Util::TypeConstraints;

package TestModel {
  use MooseX::DataModel;

  object att1 => (isa => 'Str', key_isa => sub { $_[0] =~ m/^key\d+/ });
  object att2 => (isa => 'Str', key_isa => 'Int');
}

{ 
  my $ds = {
    att1 => {
      key1 => 'value1',
      key2 => 'value2',
      key3 => 'value3',
    }
  };

  lives_ok(sub {
    TestModel->new($ds);
  });
}

{ 
  my $ds = {
    att1 => {
      invalid1 => 'value1',
      key2 => 'value2',
      key3 => 'value3',
    }
  };

  dies_ok(sub {
    TestModel->new($ds);
  });
}




done_testing;
