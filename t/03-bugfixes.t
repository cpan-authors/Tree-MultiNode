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

# ============================================================================
# Weak parent refs: no circular reference leaks
# ============================================================================

subtest 'parent is a weak reference' => sub {
    require Scalar::Util;
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->first();
    $handle->down();

    my $node = $handle->{'curr_node'};
    ok(defined $node->parent(), 'child has a parent');
    ok(Scalar::Util::isweak($node->{'parent'}), 'parent ref is weak');
};

subtest 'tree is freed when it goes out of scope' => sub {
    require Scalar::Util;
    my $weak_top;
    {
        my $tree   = Tree::MultiNode->new();
        my $handle = Tree::MultiNode::Handle->new($tree);
        $handle->add_child("a", 1);
        $handle->first();
        $handle->down();
        $handle->add_child("grandchild", 2);

        $weak_top = $tree->{'top'};
        Scalar::Util::weaken($weak_top);
        ok(defined $weak_top, 'top node alive while tree in scope');
    }
    is($weak_top, undef, 'top node freed after tree goes out of scope');
};

subtest 'removed subtree is freed without leaking' => sub {
    require Scalar::Util;
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);

    # Get a weak ref to the child node before removing it
    $handle->first();
    my $weak_child = $handle->get_child(0);
    Scalar::Util::weaken($weak_child);
    ok(defined $weak_child, 'child node alive before removal');

    $handle->remove_child(0);
    is($weak_child, undef, 'removed child node freed (no circular ref leak)');
};

subtest 'no crash during tree destruction (issue #16)' => sub {
    # This used to produce "Can't use an undefined value as an ARRAY reference"
    # during cleanup when _clearrefs encountered nodes with undef children.
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->first();
    $handle->down();
    $handle->add_child("grandchild", 3);
    $handle->up();

    # Force destruction — should not warn or die
    undef $handle;
    undef $tree;
    pass('tree destruction completed without errors');
};

# ============================================================================
# Bug fix: Node::_clone children array was wrapped instead of copied
# ============================================================================

subtest 'Node::_clone preserves children correctly' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->add_child("c", 3);

    my $original = $handle->{'curr_node'};
    my $clone    = Tree::MultiNode::Node->new($original);

    # Clone should have same number of children as original
    my $orig_children  = $original->children;
    my $clone_children = $clone->children;
    is(scalar @$clone_children, scalar @$orig_children,
       'clone has same number of children as original');
    is(scalar @$clone_children, 3, 'clone has 3 children');

    # Each child should be a Node, not a nested array ref
    for my $i (0 .. $#{$clone_children}) {
        is(ref($clone_children->[$i]), 'Tree::MultiNode::Node',
           "clone child $i is a Node object");
    }

    # Children should have correct keys
    is($clone_children->[0]->key(), "a", 'clone child 0 key is a');
    is($clone_children->[1]->key(), "b", 'clone child 1 key is b');
    is($clone_children->[2]->key(), "c", 'clone child 2 key is c');
};

subtest 'Node::_clone children point to clone as parent' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("x", 10);
    $handle->add_child("y", 20);

    my $original = $handle->{'curr_node'};
    my $clone    = Tree::MultiNode::Node->new($original);

    my $clone_children = $clone->children;
    for my $i (0 .. $#{$clone_children}) {
        is($clone_children->[$i]->parent(), $clone,
           "clone child $i parent points to clone, not original");
    }
};

subtest 'Node::_clone creates fully independent deep copy' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    my $original = $handle->{'curr_node'};
    my $clone    = Tree::MultiNode::Node->new($original);

    # Modifying clone's children should not affect original
    $clone->children->[0]->key("CHANGED");
    is($original->children->[0]->key(), "a",
       'modifying clone child does not affect original');

    # Adding to clone's children array should not affect original
    my $new_child = Tree::MultiNode::Node->new("z", 99);
    push @{$clone->children}, $new_child;
    is(scalar @{$original->children}, 2, 'original still has 2 children');
    is(scalar @{$clone->children}, 3,    'clone now has 3 children');
};

subtest 'Node::_clone with no children' => sub {
    my $node  = Tree::MultiNode::Node->new("leaf", "val");
    my $clone = Tree::MultiNode::Node->new($node);

    is($clone->key(),   "leaf", 'cloned key');
    is($clone->value(), "val",  'cloned value');
    is(scalar @{$clone->children}, 0, 'clone has empty children array');
};

subtest 'Node::_clone parent refs are weak' => sub {
    require Scalar::Util;
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("child", 1);

    my $original = $handle->{'curr_node'};
    my $clone    = Tree::MultiNode::Node->new($original);

    my $clone_children = $clone->children;
    for my $i (0 .. $#{$clone_children}) {
        ok(Scalar::Util::isweak($clone_children->[$i]->{'parent'}),
           "clone child $i parent ref is weak");
    }
};

# ============================================================================
# Bug fix: first()/last() crash on leaf nodes (no children)
# ============================================================================

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

# ============================================================================
# Bug fix: down() without current child should return undef, not corrupt handle
# ============================================================================

subtest 'down() without current child returns undef' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("child", 1);

    # No child selected — curr_child is undef
    is($handle->down(), undef, 'down() returns undef when no child selected');

    # Handle should still be valid and pointing at root
    is($handle->get_key(), "root", 'handle still points at root after failed down()');
    is($handle->depth(), 0, 'depth unchanged after failed down()');
};

subtest 'down() after up() without reselecting child returns undef' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("child", 1);

    $handle->first();
    $handle->down();
    is($handle->get_key(), "child", 'navigated down to child');
    $handle->up();
    is($handle->get_key(), "root", 'navigated back to root');

    # curr_child is now undef after up()
    is($handle->down(), undef, 'down() returns undef after up() without reselecting');
    is($handle->get_key(), "root", 'handle still at root');
};

subtest 'down() after top() without reselecting child returns undef' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("child", 1);
    $handle->first();
    $handle->down();
    $handle->top();

    is($handle->down(), undef, 'down() returns undef after top() without reselecting');
    is($handle->get_key(), "root", 'handle still at root');
    is($handle->depth(), 0, 'depth unchanged');
};

subtest 'down(pos) still works correctly' => sub {
    my $tree   = Tree::MultiNode->new();
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("root");
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);

    $handle->down(1);
    is($handle->get_key(), "b", 'down(1) navigates to child b');
    is($handle->depth(), 1, 'depth is 1 after down');
};

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
