requires 'perl', '5.14.0';
requires 'Moose';
requires 'JSON::MaybeXS';

on 'test' => sub {
  requires 'Data::Printer';
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'Types::Standard';
};
