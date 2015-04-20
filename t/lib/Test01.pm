{ "menu": {
   "id": "file",
   "value": "File",
   "items": [
     {"value": "New", "onclick": "CreateNewDoc()"},
     {"value": "Open", "onclick": "OpenDoc()"},
     {"value": "Close", "onclick": "CloseDoc()"}
   ]
 }
}



package Test01 {
  use MooseX::DataModel;

  key menu => ( required => 1, isa => 'MenuSpec');
}

package MenuSpec => {
  use MooseX::DataModel;
  key id => ( required => 1, isa => 'Str');
  key value => ( required => 1, isa => 'Str');
  array items => ( isa => 'MenuItem' );
}

package MenuItem => {
  use MooseX::DataModel;
  key 'value';
  key 'onclick';
}



