#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# Bug fix: down() without current child should return undef, not corrupt handle

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

done_testing;
