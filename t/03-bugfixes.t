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

# ============================================================================
# Bug fix: next() with undef curr_pos should behave like first()
# Bug fix: prev() with undef curr_pos should behave like last()
# ============================================================================

subtest 'next() with undef curr_pos behaves like first()' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    # After construction, curr_pos is undef
    is($handle->position(), undef, 'curr_pos starts undef');

    # next() should behave like first() when curr_pos is undef
    is($handle->next(), 0, 'next() with undef curr_pos returns 0 (like first)');
    is($handle->get_child_key(), "a", 'current child is first child after next()');
};

subtest 'prev() with undef curr_pos behaves like last()' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    # curr_pos is undef
    is($handle->position(), undef, 'curr_pos starts undef');

    # prev() should behave like last() when curr_pos is undef
    is($handle->prev(), 2, 'prev() with undef curr_pos returns last index (like last)');
    is($handle->get_child_key(), "c", 'current child is last child after prev()');
};

subtest 'next() after down() resets to first child' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("child1", 1);
    $handle->add_child("child2", 2);

    # Navigate down into first child
    $handle->first();
    $handle->down();

    # After down(), curr_pos is undef — add grandchildren
    $handle->add_child("gc1", 10);
    $handle->add_child("gc2", 20);

    # next() should behave like first() since curr_pos is undef after down()
    is($handle->next(), 0, 'next() after down() acts like first()');
    is($handle->get_child_key(), "gc1", 'positioned at first grandchild');
};

subtest 'prev() after up() resets to last child' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("child1", 1);
    $handle->add_child("child2", 2);
    $handle->add_child("child3", 3);

    # Navigate down and back up to reset curr_pos
    $handle->first();
    $handle->down();
    $handle->up();

    # After up(), curr_pos is undef
    is($handle->position(), undef, 'curr_pos is undef after up()');

    # prev() should behave like last()
    is($handle->prev(), 2, 'prev() after up() acts like last()');
    is($handle->get_child_key(), "child3", 'positioned at last child');
};

# ============================================================================
# otraverse: verify it works correctly with object + method pattern
# ============================================================================

subtest 'otraverse calls method on object for each node' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->set_value("r");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->first();
    $handle->down();
    $handle->add_child("a1", 11);
    $handle->top();

    # Collector object to accumulate visited keys
    my $collector = bless { keys => [] }, 'TestCollector';
    no strict 'refs';
    *TestCollector::collect = sub {
        my $self   = shift;
        my $handle = pop;
        push @{$self->{keys}}, $handle->get_key();
    };
    use strict 'refs';

    $handle->otraverse($collector, \&TestCollector::collect);

    is_deeply(
        $collector->{keys},
        [qw(root a a1 b)],
        'otraverse visits all nodes in correct order via object method'
    );
};

done_testing;
