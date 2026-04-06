#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# Weak parent refs: no circular reference leaks

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

done_testing;
