#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# ============================================================================
# Bug fix: add_child_node must not destroy the passed Tree::MultiNode
# ============================================================================

subtest 'add_child_node with Tree preserves the source tree' => sub {
    my $tree1   = Tree::MultiNode->new();
    my $handle1 = Tree::MultiNode::Handle->new($tree1);
    $handle1->set_key("root1");

    my $tree2   = Tree::MultiNode->new();
    my $handle2 = Tree::MultiNode::Handle->new($tree2);
    $handle2->set_key("subtree");
    $handle2->set_value("data");

    $handle1->add_child_node($tree2);

    # tree2 should still be usable
    my $handle2b = Tree::MultiNode::Handle->new($tree2);
    is($handle2b->get_key(), "subtree", 'source tree still accessible after add_child_node');
    is($handle2b->get_value(), "data",  'source tree value intact');
};

subtest 'add_child_node with Node works correctly' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");

    my $node = Tree::MultiNode::Node->new("child_key", "child_val");
    $handle->add_child_node($node);

    is(scalar($handle->children()), 1, 'one child added');
    $handle->first();
    is($handle->get_child_key(), "child_key", 'child key correct');
    is($handle->get_child_value(), "child_val", 'child value correct');
};

subtest 'add_child_node with position inserts correctly' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    my $node = Tree::MultiNode::Node->new("inserted", 99);
    $handle->add_child_node($node, 0);

    is(scalar($handle->children()), 3, 'three children after insert');
    $handle->first();
    is($handle->get_child_key(), "inserted", 'inserted node is at position 0');
    $handle->next();
    is($handle->get_child_key(), "a", 'original first child shifted to position 1');
};

subtest 'add_child_node rejects invalid child types' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    eval { $handle->add_child_node("not a node") };
    like($@, qr/Invalid child argument/, 'rejects string argument');

    eval { $handle->add_child_node({}) };
    like($@, qr/Invalid child argument/, 'rejects hashref argument');
};

done_testing;
