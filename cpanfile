requires 'Moose';
requires 'Ref::Util';
requires 'JSON::MaybeXS';

on 'test' => sub {
  requires 'Data::Printer';
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'Types::Standard';
};
