#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# Bug fix: Node::_clone children array was wrapped instead of copied

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

done_testing;
