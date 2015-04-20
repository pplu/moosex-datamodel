#!/usr/bin/env perl

my $json = q'{ "menu": {
   "id": "file",
   "value": "File",
   "items": [
     {"value": "New", "onclick": "CreateNewDoc()"},
     {"value": "Open", "onclick": "OpenDoc()"},
     {"value": "Close"}
   ]
 }
}';

package Test01 {
  use MooseX::DataModel;

  key menu => ( required => 1, isa => 'MenuSpec');
}

package MenuSpec {
  use MooseX::DataModel;
  key id => ( required => 1, isa => 'Str');
  key value => ( required => 1, isa => 'Str');
  array items => ( isa => 'MenuItem' );
}

package MenuItem {
  use MooseX::DataModel;
  key 'value' => (isa => 'Str', required => 1);
  key 'onclick' => (isa => 'Str');
}

use Data::Printer;

my $model = Test01->new_from_json($json);

p $model;

p $model->menu;
p $model->menu->items;
