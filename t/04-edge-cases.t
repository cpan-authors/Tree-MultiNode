#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# ============================================================================
# Falsy keys and values through the full Handle API
# ============================================================================

subtest 'add_child with key 0 and value 0' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    $handle->add_child(0, 0);
    $handle->add_child(1, 1);

    $handle->first();
    is($handle->get_child_key(),   0, 'child key 0 retrievable');
    is($handle->get_child_value(), 0, 'child value 0 retrievable');
};

subtest 'add_child with empty string key and value' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    $handle->add_child("", "");
    $handle->add_child("nonempty", "val");

    $handle->first();
    is($handle->get_child_key(),   "", 'child key empty string retrievable');
    is($handle->get_child_value(), "", 'child value empty string retrievable');
};

subtest 'set_key and set_value with falsy values' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

    is($handle->set_key(0),  0,  'set_key(0) returns 0');
    is($handle->get_key(),   0,  'get_key returns 0');
    is($handle->set_key(""), "", 'set_key("") returns empty string');
    is($handle->get_key(),   "", 'get_key returns empty string');

    is($handle->set_value(0),  0,  'set_value(0) returns 0');
    is($handle->get_value(),   0,  'get_value returns 0');
    is($handle->set_value(""), "", 'set_value("") returns empty string');
    is($handle->get_value(),   "", 'get_value returns empty string');
};

subtest 'child_keys includes falsy keys' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    $handle->add_child(0,  "zero");
    $handle->add_child("", "empty");
    $handle->add_child("a", "alpha");

    my @keys = $handle->child_keys();
    is(scalar @keys, 3, 'three child keys returned');
    is($keys[0], 0,  'first key is 0');
    is($keys[1], "", 'second key is empty string');
    is($keys[2], "a", 'third key is a');
};

subtest 'kv_pairs with falsy keys' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    $handle->add_child(0,  "zero_val");
    $handle->add_child("", "empty_val");
    $handle->add_child("k", "normal");

    my %pairs = $handle->kv_pairs();
    is($pairs{0},   "zero_val",  'kv_pairs includes key 0');
    is($pairs{""},  "empty_val", 'kv_pairs includes empty string key');
    is($pairs{"k"}, "normal",    'kv_pairs includes normal key');
};

subtest 'child_key_positions with falsy keys' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    $handle->add_child(0,  "zero");
    $handle->add_child("", "empty");
    $handle->add_child("a", "alpha");

    my %pos = $handle->child_key_positions();
    is($pos{0},   0, 'position of key 0 is 0');
    is($pos{""},  1, 'position of empty string key is 1');
    is($pos{"a"}, 2, 'position of key a is 2');
};

# ============================================================================
# select() edge cases
# ============================================================================

subtest 'select returns undef when no match' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    my $found = $handle->select("nonexistent");
    is($found, undef, 'select returns undef for missing key');
};

subtest 'select returns undef on node with no children' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("leaf");

    my $found = $handle->select("anything");
    is($found, undef, 'select returns undef when no children');
};

subtest 'select with falsy key 0' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child(0, "zero");
    $handle->add_child(1, "one");

    my $found = $handle->select(0);
    ok($found, 'select finds key 0');
    is($handle->get_child_key(), 0, 'selected child has key 0');
};

subtest 'select sets curr_pos and curr_child' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("x", 10);
    $handle->add_child("y", 20);
    $handle->add_child("z", 30);

    $handle->select("y");
    is($handle->position(), 1, 'select set curr_pos to 1');
    is($handle->get_child_key(), "y", 'select set curr_child correctly');

    # Can navigate down to selected child
    $handle->down();
    is($handle->get_key(), "y", 'navigated down to selected child');
    is($handle->get_value(), 20, 'selected child has correct value');
};

# ============================================================================
# traverse edge cases
# ============================================================================

subtest 'traverse on leaf node visits only that node' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("leaf");
    $handle->set_value("alone");

    my @visited;
    $handle->traverse(sub {
        my $h = pop;
        push @visited, $h->get_key();
    });

    is(scalar @visited, 1, 'traverse visited exactly one node');
    is($visited[0], "leaf", 'traverse visited the leaf');
};

subtest 'traverse does not modify original handle position' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    $handle->first();
    $handle->down();
    is($handle->get_key(), "a", 'handle at child a before traverse');

    # Traverse from child a
    my @visited;
    $handle->traverse(sub {
        my $h = pop;
        push @visited, $h->get_key();
    });

    # Handle should still be at "a"
    is($handle->get_key(), "a", 'handle still at child a after traverse');
    is($handle->depth(), 1, 'handle depth unchanged after traverse');
};

subtest 'traverse passes extra args before handle' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    my @captured;
    $handle->traverse(sub {
        my $h = pop;
        push @captured, [@_];
    }, "arg1", "arg2");

    is(scalar @captured, 1, 'visited one node');
    is_deeply($captured[0], ["arg1", "arg2"], 'extra args passed correctly');
};

# ============================================================================
# Handle independence — two handles, one tree
# ============================================================================

subtest 'two handles navigate independently' => sub {
    my $tree = Tree::MultiNode->new;
    my $h1   = Tree::MultiNode::Handle->new($tree);

    $h1->set_key("root");
    $h1->add_child("left",  "L");
    $h1->add_child("right", "R");

    my $h2 = Tree::MultiNode::Handle->new($tree);

    # h1 goes left
    $h1->first();
    $h1->down();
    is($h1->get_key(), "left", 'h1 at left child');
    is($h1->depth(),   1,      'h1 depth is 1');

    # h2 should still be at root
    is($h2->get_key(), "root", 'h2 still at root');
    is($h2->depth(),   0,      'h2 depth is 0');

    # h2 goes right
    $h2->last();
    $h2->down();
    is($h2->get_key(), "right", 'h2 at right child');

    # h1 still at left
    is($h1->get_key(), "left", 'h1 still at left child');
};

subtest 'cloned handle starts at same position' => sub {
    my $tree = Tree::MultiNode->new;
    my $h1   = Tree::MultiNode::Handle->new($tree);
    $h1->set_key("root");
    $h1->add_child("child", "val");
    $h1->first();
    $h1->down();

    my $h2 = Tree::MultiNode::Handle->new($h1);
    is($h2->get_key(), "child", 'cloned handle at same node');
    is($h2->depth(),   1,       'cloned handle has same depth');

    # Navigate clone independently
    $h2->up();
    is($h2->get_key(), "root", 'clone moved to root');
    is($h1->get_key(), "child", 'original still at child');
};

# ============================================================================
# Node::dump smoke test
# ============================================================================

subtest 'Node::dump does not crash' => sub {
    my $node = Tree::MultiNode::Node->new("k", "v");

    # dump() prints to STDOUT — capture it
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT: $!";
        $node->dump();
    }

    like($output, qr/\[dump\]/, 'dump produces output');
    like($output, qr/k/, 'dump includes key');
    like($output, qr/v/, 'dump includes value');
    pass('dump did not crash');
};

subtest 'Node::dump with undef key and value' => sub {
    my $node = Tree::MultiNode::Node->new();

    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT: $!";
        $node->dump();
    }

    like($output, qr/\[dump\]/, 'dump produces output with undef members');
    pass('dump with undef members did not crash');
};

# ============================================================================
# child_kv_pairs with duplicate keys — hash semantics
# ============================================================================

subtest 'child_kv_pairs last value wins for duplicate keys' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("dup", "first");
    $handle->add_child("dup", "second");
    $handle->add_child("unique", "val");

    my %pairs = $handle->kv_pairs();
    is($pairs{"dup"},    "second", 'last value wins for duplicate key');
    is($pairs{"unique"}, "val",    'unique key preserved');
};

# ============================================================================
# Misc behavioral contracts
# ============================================================================

subtest 'add_child to different levels builds correct tree' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    # Level 1
    $handle->add_child("L1-a", "1a");
    $handle->add_child("L1-b", "1b");

    # Level 2 under L1-a
    $handle->first();
    $handle->down();
    $handle->add_child("L2-a1", "2a1");

    # Back up, go to L1-b, add children
    $handle->up();
    $handle->last();
    $handle->down();
    $handle->add_child("L2-b1", "2b1");
    $handle->add_child("L2-b2", "2b2");

    # Traverse and collect all nodes
    $handle->top();
    my @nodes;
    $handle->traverse(sub {
        my $h = pop;
        push @nodes, $h->get_key();
    });

    is(scalar @nodes, 6, 'tree has 6 nodes total');
    is($nodes[0], "root",  'root visited first');
    # Depth-first: root -> L1-a -> L2-a1 -> L1-b -> L2-b1 -> L2-b2
    is($nodes[1], "L1-a",  'L1-a second');
    is($nodes[2], "L2-a1", 'L2-a1 third');
    is($nodes[3], "L1-b",  'L1-b fourth');
    is($nodes[4], "L2-b1", 'L2-b1 fifth');
    is($nodes[5], "L2-b2", 'L2-b2 sixth');
};

subtest 'get_child_key and get_child_value at explicit position' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 10);
    $handle->add_child("b", 20);
    $handle->add_child("c", 30);

    # Access by explicit position without setting curr_pos
    is($handle->get_child_key(0),   "a",  'key at position 0');
    is($handle->get_child_key(2),   "c",  'key at position 2');
    is($handle->get_child_value(1), 20,   'value at position 1');

    # curr_pos should still be undef (explicit pos doesn't change it)
    is($handle->position(), undef, 'curr_pos unchanged by explicit get_child_key');
};

subtest 'top resets depth to 0' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->first();
    $handle->down();
    $handle->add_child("b", 2);
    $handle->first();
    $handle->down();

    is($handle->depth(), 2, 'at depth 2');
    $handle->top();
    is($handle->depth(),   0,      'top resets depth to 0');
    is($handle->get_key(), "root", 'top resets to root node');
};

# ============================================================================
# num_children
# ============================================================================

subtest 'Node::num_children' => sub {
    my $node = Tree::MultiNode::Node->new("root", "val");
    is($node->num_children(), 0, 'new node has 0 children');

    my $child1 = Tree::MultiNode::Node->new("a", 1);
    push @{$node->children}, $child1;
    is($node->num_children(), 1, 'after adding one child');

    my $child2 = Tree::MultiNode::Node->new("b", 2);
    push @{$node->children}, $child2;
    is($node->num_children(), 2, 'after adding two children');
};

subtest 'Handle::num_children' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    is($handle->num_children(), 0, 'root starts with 0 children');

    $handle->add_child("a", 1);
    is($handle->num_children(), 1, 'after add_child: 1 child');

    $handle->add_child("b", 2);
    $handle->add_child("c", 3);
    is($handle->num_children(), 3, 'after 3 add_child calls');

    # navigate down and check leaf
    $handle->first();
    $handle->down();
    is($handle->num_children(), 0, 'leaf node has 0 children');

    # add grandchildren and verify
    $handle->add_child("x", 10);
    $handle->add_child("y", 20);
    is($handle->num_children(), 2, 'after adding grandchildren');

    # go back up
    $handle->up();
    is($handle->num_children(), 3, 'parent still has 3 children');
};

subtest 'num_children consistent with scalar children' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    for my $i (0..4) {
        $handle->add_child("child$i", $i);
    }

    is($handle->num_children(), scalar($handle->children()),
       'num_children agrees with scalar children');
};

done_testing;
