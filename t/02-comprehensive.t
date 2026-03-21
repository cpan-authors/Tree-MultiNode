#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# ============================================================================
# Tree::MultiNode::Node tests
# ============================================================================

subtest 'Node construction - empty' => sub {
    my $node = Tree::MultiNode::Node->new();
    isa_ok($node, 'Tree::MultiNode::Node');
    is($node->key(),   undef, 'empty node has undef key');
    is($node->value(), undef, 'empty node has undef value');
    is(ref($node->children()), 'ARRAY', 'empty node has children array');
    is(scalar @{$node->children()}, 0, 'empty node has no children');
    is($node->parent(), undef, 'empty node has no parent');
};

subtest 'Node construction - with key and value' => sub {
    my $node = Tree::MultiNode::Node->new("name", "Larry");
    is($node->key(),   "name",  'key set on construction');
    is($node->value(), "Larry", 'value set on construction');
};

subtest 'Node construction - cloning' => sub {
    my $orig = Tree::MultiNode::Node->new("color", "blue");
    my $clone = Tree::MultiNode::Node->new($orig);
    isa_ok($clone, 'Tree::MultiNode::Node');
    is($clone->key(),   "color", 'cloned key');
    is($clone->value(), "blue",  'cloned value');
};

subtest 'Node key/value setters' => sub {
    my $node = Tree::MultiNode::Node->new();
    is($node->key("hello"),   "hello",   'key setter returns new key');
    is($node->key(),          "hello",   'key getter returns set key');
    is($node->value("world"), "world",   'value setter returns new value');
    is($node->value(),        "world",   'value getter returns set value');
};

subtest 'Node clear_key / clear_value' => sub {
    my $node = Tree::MultiNode::Node->new("k", "v");
    my $old_key = $node->clear_key();
    is($old_key,      "k",   'clear_key returns old key');
    is($node->key(),  undef, 'key is undef after clear');

    my $old_val = $node->clear_value();
    is($old_val,        "v",   'clear_value returns old value');
    is($node->value(), undef, 'value is undef after clear');
};

subtest 'Node child_keys / child_values / child_kv_pairs' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("x", 10);
    $handle->add_child("y", 20);
    $handle->add_child("z", 30);

    my $node = $handle->{'curr_node'};
    my @keys = $node->child_keys();
    is_deeply(\@keys, ["x", "y", "z"], 'child_keys returns all keys in order');

    my @vals = $node->child_values();
    is_deeply(\@vals, [10, 20, 30], 'child_values returns all values in order');

    my %kv = $node->child_kv_pairs();
    is_deeply(\%kv, {x => 10, y => 20, z => 30}, 'child_kv_pairs returns hash');
};

subtest 'Node child_key_positions' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("alpha", 1);
    $handle->add_child("beta",  2);
    $handle->add_child("gamma", 3);

    my $node = $handle->{'curr_node'};
    my %pos = $node->child_key_positions();
    is($pos{'alpha'}, 0, 'alpha at position 0');
    is($pos{'beta'},  1, 'beta at position 1');
    is($pos{'gamma'}, 2, 'gamma at position 2');
};

# ============================================================================
# Tree::MultiNode construction / destruction
# ============================================================================

subtest 'Tree construction' => sub {
    my $tree = Tree::MultiNode->new;
    isa_ok($tree, 'Tree::MultiNode');
    isa_ok($tree->{'top'}, 'Tree::MultiNode::Node');
};

subtest 'Tree destruction clears refs' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->down(0);
    $handle->add_child("deep", "val");

    # Just verify DESTROY doesn't crash
    $tree->DESTROY();
    pass('DESTROY completed without error');
};

# ============================================================================
# Handle construction and cloning
# ============================================================================

subtest 'Handle construction requires tree' => sub {
    eval { Tree::MultiNode::Handle->new("not a tree") };
    like($@, qr/invalid Tree::MultiNode reference/i, 'dies with bad argument');
};

subtest 'Handle cloning' => sub {
    my $tree   = Tree::MultiNode->new;
    my $h1     = Tree::MultiNode::Handle->new($tree);
    $h1->set_key("root");
    $h1->set_value("val");
    $h1->add_child("c1", 1);
    $h1->first();
    $h1->down();

    my $h2 = Tree::MultiNode::Handle->new($h1);
    isa_ok($h2, 'Tree::MultiNode::Handle');
    is($h2->get_key(), "c1", 'cloned handle at same position');
    is($h2->depth(),   1,    'cloned handle has correct depth');
};

# ============================================================================
# Handle navigation: first, next, prev, last
# ============================================================================

subtest 'first / next / prev / last navigation' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);
    $handle->add_child("d", 4);

    is($handle->first(), 0, 'first() returns 0');
    is($handle->get_child_key(), "a", 'first child is a');

    is($handle->next(), 1, 'next() returns 1');
    is($handle->get_child_key(), "b", 'second child is b');

    is($handle->next(), 2, 'next() returns 2');
    is($handle->get_child_key(), "c", 'third child is c');

    is($handle->next(), 3, 'next() returns 3');
    is($handle->get_child_key(), "d", 'fourth child is d');

    is($handle->next(), undef, 'next() past end returns undef');

    is($handle->last(), 3, 'last() returns 3');
    is($handle->get_child_key(), "d", 'last child is d');

    is($handle->prev(), 2, 'prev() returns 2');
    is($handle->get_child_key(), "c", 'prev child is c');

    is($handle->prev(), 1, 'prev() returns 1');
    is($handle->prev(), 0, 'prev() returns 0');
    is($handle->prev(), undef, 'prev() before start returns undef');
};

# ============================================================================
# Handle: up / down / top / depth
# ============================================================================

subtest 'down / up / top / depth tracking' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("L1", "v1");

    is($handle->depth(), 0, 'depth at root is 0');

    $handle->first();
    $handle->down();
    is($handle->depth(), 1, 'depth after down is 1');
    is($handle->get_key(), "L1", 'down moves to child');

    $handle->add_child("L2", "v2");
    $handle->first();
    $handle->down();
    is($handle->depth(), 2, 'depth after second down is 2');
    is($handle->get_key(), "L2", 'nested child key');

    $handle->up();
    is($handle->depth(), 1, 'depth after up is 1');

    $handle->top();
    is($handle->depth(), 0, 'depth after top is 0');
    is($handle->get_key(), "root", 'top returns to root');
};

subtest 'up from root returns undef' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    is($handle->up(), undef, 'up() at root returns undef');
};

subtest 'down with position argument' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    $handle->down(1);
    is($handle->get_key(), "b", 'down(1) moves to second child');
    is($handle->depth(), 1, 'depth is 1');
};

# ============================================================================
# Handle: position
# ============================================================================

subtest 'position get/set' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    $handle->position(2);
    is($handle->position(), 2, 'position returns set value');
    is($handle->get_child_key(), "c", 'position(2) selects third child');

    $handle->position(0);
    is($handle->position(), 0, 'position(0) works');
    is($handle->get_child_key(), "a", 'position(0) selects first child');
};

# ============================================================================
# Handle: select
# ============================================================================

subtest 'select by key' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("foo", 10);
    $handle->add_child("bar", 20);
    $handle->add_child("baz", 30);

    is($handle->select("bar"), 1, 'select returns true on match');
    is($handle->position(), 1, 'position set to found child');

    is($handle->select("nonexistent"), undef, 'select returns undef for no match');
};

subtest 'select with custom comparator' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("ABC", 1);
    $handle->add_child("def", 2);
    $handle->add_child("GHI", 3);

    # Case-insensitive search
    my $found = $handle->select("def", sub { return lc(shift) eq lc(shift) });
    is($found, 1, 'custom comparator finds match');
    is($handle->position(), 1, 'correct position with custom comparator');
};

# ============================================================================
# Handle: add_child with position
# ============================================================================

subtest 'add_child inserts at position' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("c", 3);

    # Insert "b" at position 0 (before "a")
    $handle->add_child("b", 2, 0);

    my @keys = map { $_->key() } $handle->children();
    is($keys[0], "b", 'inserted child at position 0');
    is($keys[1], "a", 'original first child shifted');
    is($keys[2], "c", 'original second child preserved');
};

# ============================================================================
# Handle: add_child_node
# ============================================================================

subtest 'add_child_node with Node object' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

    my $node = Tree::MultiNode::Node->new("imported", "value");
    $handle->add_child_node($node);

    is(scalar($handle->children()), 1, 'one child added');
    $handle->first();
    $handle->down();
    is($handle->get_key(),   "imported", 'child_node key correct');
    is($handle->get_value(), "value",    'child_node value correct');
};

subtest 'add_child_node with Tree object' => sub {
    my $main_tree = Tree::MultiNode->new;
    my $main_h    = Tree::MultiNode::Handle->new($main_tree);
    $main_h->set_key("main");

    my $sub_tree = Tree::MultiNode->new;
    my $sub_h    = Tree::MultiNode::Handle->new($sub_tree);
    $sub_h->set_key("subtree_root");
    $sub_h->set_value("subval");

    $main_h->add_child_node($sub_tree);

    is(scalar($main_h->children()), 1, 'subtree added as child');
    $main_h->first();
    $main_h->down();
    is($main_h->get_key(), "subtree_root", 'subtree root key accessible');
};

subtest 'add_child_node rejects invalid argument' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

    eval { $handle->add_child_node("not a node") };
    like($@, qr/Invalid child argument/, 'dies with non-node argument');
};

# ============================================================================
# Handle: children / child_keys / child_key_positions
# ============================================================================

subtest 'Handle::children returns list' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("x", 1);
    $handle->add_child("y", 2);

    my @children = $handle->children();
    is(scalar @children, 2, 'children returns correct count');
    isa_ok($children[0], 'Tree::MultiNode::Node');
};

subtest 'Handle::child_keys' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("p", 1);
    $handle->add_child("q", 2);

    my @keys = $handle->child_keys();
    is_deeply(\@keys, ["p", "q"], 'child_keys returns keys in order');
};

subtest 'Handle::child_key_positions' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("first",  1);
    $handle->add_child("second", 2);

    my %pos = $handle->child_key_positions();
    is($pos{'first'},  0, 'first at 0');
    is($pos{'second'}, 1, 'second at 1');
};

# ============================================================================
# Handle: get_child_key / get_child_value
# ============================================================================

subtest 'get_child_key with explicit position' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("aa", 11);
    $handle->add_child("bb", 22);
    $handle->add_child("cc", 33);

    is($handle->get_child_key(1), "bb", 'get_child_key(1)');
    is($handle->get_child_key(2), "cc", 'get_child_key(2)');

    # Position 0 triggers the shift||curr_pos bug (PR #2 will fix)
    $handle->first();
    is($handle->get_child_key(), "aa", 'get_child_key() uses curr_pos after first()');
};

subtest 'get_child_value with explicit position' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("aa", 11);
    $handle->add_child("bb", 22);

    is($handle->get_child_value(1), 22, 'get_child_value(1)');

    # Position 0 via curr_pos
    $handle->first();
    is($handle->get_child_value(), 11, 'get_child_value() uses curr_pos after first()');
};

# ============================================================================
# Handle: kv_pairs
# ============================================================================

subtest 'kv_pairs returns child key-value hash' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("m", 100);
    $handle->add_child("n", 200);

    my %pairs = $handle->kv_pairs();
    is($pairs{'m'}, 100, 'kv_pairs key m');
    is($pairs{'n'}, 200, 'kv_pairs key n');
};

# ============================================================================
# Handle: remove_child
# ============================================================================

subtest 'remove_child removes correct child' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    my ($key, $val) = $handle->remove_child(1);
    is($key, "b", 'removed child key');
    is($val, 2,   'removed child value');

    my @keys = map { $_->key() } $handle->children();
    is_deeply(\@keys, ["a", "c"], 'remaining children after removal');
};

subtest 'remove_child with invalid position dies' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("only", 1);

    eval { $handle->remove_child(5) };
    like($@, qr/invalid position/, 'remove_child with out-of-range position dies');
};

# ============================================================================
# Handle: traverse
# ============================================================================

subtest 'traverse visits all nodes depth-first' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("L", 1);
    $handle->add_child("R", 2);
    $handle->down(0);
    $handle->add_child("LL", 11);
    $handle->up();
    $handle->down(1);
    $handle->add_child("RL", 21);
    $handle->top();

    my @visited;
    $handle->traverse(sub {
        my $h = pop;
        push @visited, $h->get_key();
    });

    is(scalar @visited, 5, 'traverse visited 5 nodes');
    is($visited[0], "root", 'first visited is root');
};

subtest 'traverse passes extra arguments' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("only");

    my @received;
    $handle->traverse(sub {
        my $h = pop;
        push @received, [@_];
    }, "arg1", "arg2");

    is_deeply($received[0], ["arg1", "arg2"], 'extra args passed to callback');
};

# ============================================================================
# Handle: tree accessor
# ============================================================================

subtest 'Handle::tree returns the tree' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

    is($handle->tree(), $tree, 'tree() returns the original tree');
};

# ============================================================================
# Multiple handles on same tree
# ============================================================================

subtest 'multiple handles share same tree' => sub {
    my $tree = Tree::MultiNode->new;
    my $h1   = Tree::MultiNode::Handle->new($tree);
    my $h2   = Tree::MultiNode::Handle->new($tree);

    $h1->set_key("shared");
    is($h2->get_key(), "shared", 'second handle sees changes from first');

    $h1->add_child("child", "val");
    is(scalar($h2->children()), 1, 'second handle sees children added by first');
};

# ============================================================================
# Edge cases
# ============================================================================

subtest 'single child tree navigation' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("only_child", "val");

    is($handle->first(), 0, 'first on single child');
    is($handle->last(),  0, 'last on single child');
    is($handle->next(), undef, 'next from only child returns undef');
};

subtest 'deep tree traversal' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

    # Build a 5-level deep chain
    for my $i (0..4) {
        $handle->set_key("level_$i");
        $handle->add_child("level_" . ($i+1), $i+1);
        $handle->first();
        $handle->down();
    }

    is($handle->depth(), 5, 'reached depth 5');
    is($handle->get_key(), "level_5", 'at the deepest node');

    # Walk back up
    for my $i (reverse 0..4) {
        $handle->up();
        is($handle->depth(), $i, "back at depth $i");
    }

    is($handle->get_key(), "level_0", 'back at root');
};

subtest 'get_data returns key-value pair' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("thekey");
    $handle->set_value("theval");

    my ($k, $v) = $handle->get_data();
    is($k, "thekey", 'get_data key');
    is($v, "theval", 'get_data value');
};

done_testing();
