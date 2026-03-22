#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# ============================================================================
# Bug fix: remove_child must reset curr_pos/curr_child on the handle
# ============================================================================

subtest 'remove_child resets handle cursor state' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    # Position at child 1 ("b")
    $handle->position(1);
    is($handle->get_child_key(), "b", 'positioned at child b');

    # Remove child at position 0 ("a")
    my ($key, $val) = $handle->remove_child(0);
    is($key, "a", 'removed child key is a');
    is($val, 1,   'removed child value is 1');

    # After removal, handle cursor should be reset
    is($handle->position(), undef, 'curr_pos is undef after remove_child');
};

subtest 'remove_child at current position resets cursor' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("x", 10);
    $handle->add_child("y", 20);

    $handle->first();
    is($handle->get_child_key(), "x", 'positioned at child x');

    # Remove current child
    my ($key, $val) = $handle->remove_child();
    is($key, "x",  'removed correct child');
    is($val, 10,   'removed correct value');

    # Cursor should be reset
    is($handle->position(), undef, 'curr_pos reset after removing current child');

    # Should still have one child left
    is(scalar($handle->children()), 1, 'one child remaining');
};

subtest 'remove_child then navigate works correctly' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    # Remove middle child
    $handle->remove_child(1);

    # Re-navigate: should work fine with 2 remaining children
    $handle->first();
    is($handle->get_child_key(), "a", 'first child is a after removal');

    $handle->next();
    is($handle->get_child_key(), "c", 'second child is c (b was removed)');
};

# ============================================================================
# Bug fix: Node::value() should accept falsy values including undef
# ============================================================================

subtest 'Node::value() accepts 0' => sub {
    my $node = Tree::MultiNode::Node->new("count", 42);
    is($node->value(), 42, 'initial value is 42');

    $node->value(0);
    is($node->value(), 0, 'value set to 0');
};

subtest 'Node::value() accepts empty string' => sub {
    my $node = Tree::MultiNode::Node->new("name", "Larry");
    is($node->value(), "Larry", 'initial value is Larry');

    $node->value("");
    is($node->value(), "", 'value set to empty string');
};

subtest 'Node::value() accepts undef' => sub {
    my $node = Tree::MultiNode::Node->new("key", "val");
    is($node->value(), "val", 'initial value is val');

    $node->value(undef);
    is($node->value(), undef, 'value set to undef via value()');
};

subtest 'Node::value() getter returns without setting' => sub {
    my $node = Tree::MultiNode::Node->new("k", "original");
    is($node->value(), "original", 'getter does not modify value');
    is($node->value(), "original", 'calling getter again still returns original');
};

# ============================================================================
# Verify Node::key() still works with falsy values (regression check)
# ============================================================================

subtest 'Node::key() handles falsy values' => sub {
    my $node = Tree::MultiNode::Node->new();
    $node->key(0);
    is($node->key(), 0, 'key can be set to 0');

    $node->key("");
    is($node->key(), "", 'key can be set to empty string');
};

done_testing;
