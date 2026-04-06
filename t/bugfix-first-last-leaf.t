#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# Bug fix: first()/last() crash on leaf nodes (no children)

subtest 'first() returns undef on leaf node' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("leaf");
    is(scalar($handle->children()), 0, 'node has no children');
    is($handle->first(), undef, 'first() returns undef on leaf node');
};

subtest 'last() returns undef on leaf node' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("leaf");
    is(scalar($handle->children()), 0, 'node has no children');
    is($handle->last(), undef, 'last() returns undef on leaf node');
};

subtest 'first() still works normally with children' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    is($handle->first(), 0, 'first() returns 0');
    is($handle->get_child_key(), "a", 'first child is a');
};

done_testing;
