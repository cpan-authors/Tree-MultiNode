#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# ============================================================================
# Bug fix: negative position validation in add_child, add_child_node, position
# ============================================================================

subtest 'add_child rejects negative position' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    eval { $handle->add_child("bad", "val", -1) };
    like($@, qr/invalid/i, 'add_child rejects negative position');
};

subtest 'add_child_node rejects negative position' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 1);

    my $node = Tree::MultiNode::Node->new("bad", "val");
    eval { $handle->add_child_node($node, -1) };
    like($@, qr/invalid/i, 'add_child_node rejects negative position');
};

subtest 'position() rejects negative values' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    eval { $handle->position(-1) };
    like($@, qr/invalid/i, 'position() rejects -1');
};

done_testing;
