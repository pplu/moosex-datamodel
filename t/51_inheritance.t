#!/usr/bin/env perl

my $json = q'{ "menu": {
   "id": "file",
   "value": "File",
   "items": [
     {"value": "New", "onclick": "CreateNewDoc()"},
     {"value": "Open", "onclick": "OpenDoc()"},
     {"value": "Close"}
   ],
   "menus": {
     "menu1": { "value": "New" },
     "menu2": { "value": "Open" }
   },
   "long_menus": true,
   "aliases":{
     "alias1": { "value": "val1", "extravalue": "val1.1" }
   }
 }
}';

package Test01 {
  use MooseX::DataModel;

  key title => ( required => 1, isa => 'Str');
  key menu => ( required => 1, isa => 'MenuSpec');
}
package AliasObject {
  use MooseX::DataModel;

  key value => (isa => 'Str');
}
package ExtendedTest01 {
  use MooseX::DataModel;
  extends 'Test01';

  # This attribute gets overwritten (so it gets un-required)
  key title => (isa => 'Str');
  key menu => (isa => 'ExtendedMenuSpec');
}

package MenuSpec {
  use MooseX::DataModel;
  key id => ( required => 1, isa => 'Str');
  key value => ( required => 1, isa => 'Str');
  array items => ( isa => 'MenuItem' );
  object menus => ( isa => 'MenuItem' );
  object aliases => (isa => 'AliasObject');
}
package ExtendedAliasObject {
  use MooseX::DataModel;
  extends 'AliasObject';

  key extravalue => (isa => 'Str');
}
package ExtendedMenuSpec {
  use MooseX::DataModel;
  extends 'MenuSpec';
  key long_menus => (required => 1, isa => 'Bool');
  object aliases => (isa => 'ExtendedAliasObject');
}

package MenuItem {
  use MooseX::DataModel;
  key 'value' => (isa => 'Str', required => 1);
  key 'onclick' => (isa => 'Str');
}

use Data::Printer;
use Test::More;

my $model = ExtendedTest01->MooseX::DataModel::new_from_json($json);

isa_ok($model, 'ExtendedTest01');
ok(not(defined $model->title));
isa_ok($model->menu, 'ExtendedMenuSpec');
isa_ok($model->menu->items, 'ARRAY');
isa_ok($model->menu->items->[0], 'MenuItem');
cmp_ok($model->menu->long_menus, '==', 1);

cmp_ok($model->menu->aliases->{ alias1 }->value, 'eq', 'val1');
cmp_ok($model->menu->aliases->{ alias1 }->extravalue, 'eq', 'val1.1');

isa_ok($model->menu, 'ExtendedMenuSpec');
isa_ok($model->menu->menus, 'HASH');
isa_ok($model->menu->menus->{ menu1 }, 'MenuItem');

done_testing;
