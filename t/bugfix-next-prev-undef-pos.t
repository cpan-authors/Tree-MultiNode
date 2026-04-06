#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# Bug fix: next() with undef curr_pos should behave like first()
# Bug fix: prev() with undef curr_pos should behave like last()

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

done_testing;
