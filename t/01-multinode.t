#!perl -T

use Test::More tests => 85;

use Tree::MultiNode;

my $tree   = Tree::MultiNode->new;
my $handle = Tree::MultiNode::Handle->new($tree);
isa_ok($tree, 'Tree::MultiNode');
isa_ok($handle, 'Tree::MultiNode::Handle');

$handle->add_child("a", 1);
$handle->add_child("b", 1);
$handle->add_child("c", 1);

$handle->remove_child(1);
my %pairs = $handle->kv_pairs();

pass("**** [$0] Pairs: " .  join(', ',%pairs));

ok(!defined $pairs{'b'}, "pair b not defined");
ok( defined $pairs{'a'}, "pair a defined");
ok( defined $pairs{'c'}, "pair c defined");

pass("**** test remove_child at position 0");
{
    my $t2 = Tree::MultiNode->new;
    my $h2 = Tree::MultiNode::Handle->new($t2);
    $h2->add_child("x", 10);
    $h2->add_child("y", 20);
    $h2->add_child("z", 30);

    my @rv = $h2->remove_child(0);
    is($rv[0], "x", "remove_child(0) returns correct key");
    is($rv[1], 10,  "remove_child(0) returns correct value");

    my %p2 = $h2->kv_pairs();
    ok(!defined $p2{'x'}, "child x removed");
    ok( defined $p2{'y'}, "child y still present");
    ok( defined $p2{'z'}, "child z still present");

    my @keys = $h2->child_keys();
    is(scalar @keys, 2, "child count is 2 after remove_child(0)");
}

pass("**** test remove_child updates children persistently");
{
    my $t3 = Tree::MultiNode->new;
    my $h3 = Tree::MultiNode::Handle->new($t3);
    $h3->add_child("p", 1);
    $h3->add_child("q", 2);
    $h3->remove_child(0);
    my @keys = $h3->child_keys();
    is(scalar @keys, 1, "children persist after remove_child");
}

pass("**** testing traverse...");
pass("**** ....t digit formatting...");
$tree   = new Tree::MultiNode();
$handle = new Tree::MultiNode::Handle($tree);
isa_ok($tree, 'Tree::MultiNode');
isa_ok($handle, 'Tree::MultiNode::Handle');

is($handle->set_key('1'),             1,     'set_key');
is($handle->set_value('foo'),         'foo', 'set_value');
is($handle->add_child('1:1','bar'),   undef, '  add_child("1:1", "bar")');
is($handle->down(0),                  1,     '  down(0)');;
is($handle->add_child('1:1:1','baz'), undef, '    add_child("1:1:1", "baz")');
is($handle->add_child('1:1:2','boz'), undef, '    add_child("1:1:1", "boz")');
is($handle->up(),                     1,     '    up');
is($handle->add_child('1:2','qux'),   undef, '  add_child("1:2", "qux")');
is($handle->down(1),                  1,     '  down(1)');
is($handle->add_child('1:2:1','qaz'), undef, '    add_child("1:2:1","qaz")');
is($handle->add_child('1:2:2','qoz'), undef, '    add_child("1:2:2","qoz")');

is($handle->top(), 1, "move to top of tree");
my $count = 0;
$handle->traverse(sub {
    my $h = pop;
    pass(sprintf("**** %sk: %- 5s v: %s", '  ' x $handle->depth, $h->get_data));

    $count++;
    isa_ok($h, 'Tree::MultiNode::Handle');
    is($_[0], 'arg1', "Traverse argument 1 received");
    is($_[1], 'arg2', "Traverse argument 2 received");
    is($_[2], 'arg3', "Traverse argument 3 received");
  },
  'arg1',
  'arg2',
  'arg3'
);


pass("**** Testing select...");
is($handle->top(), 1, "move to top of tree");
pass("**** Children: " . join(', ',$handle->child_keys()));

is($handle->select('1:2'), 1, "Select 1:2") or die("Error, select() failed");

is($handle->down(), 1, "down()");
is($handle->get_value, 'qux', "select(1:2) positioned on the correct child");

is($count, 7, "Traversed 7 nodes");

pass("**** test storing 'zero' as a child key");
is($handle->add_child('zero','fuzz'), undef, 'add_child("zero", "fuzz")');
is($handle->last, 2, 'last() -- TODO: Why is this a 2 return?');
is($handle->down, 1, "down()");
is($handle->get_value, 'fuzz', "down sent us to key with value fuzz");
is($handle->set_key(0), 0, "set_key(0)");
is($handle->get_key, 0, "0 Stores as a key");

pass("**** test Node constructor with falsy keys");
{
    my $node_zero = Tree::MultiNode::Node->new(0, "zero_val");
    is($node_zero->key(), 0, "Node->new(0, ...) preserves key 0");
    is($node_zero->value(), "zero_val", "Node->new(0, ...) preserves value");

    my $node_empty = Tree::MultiNode::Node->new("", "empty_val");
    is($node_empty->key(), "", "Node->new('', ...) preserves empty string key");
    is($node_empty->value(), "empty_val", "Node->new('', ...) preserves value");
}

#done_testing();
