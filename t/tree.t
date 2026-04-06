#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# ============================================================================
# Tree::MultiNode construction / destruction
# ============================================================================

subtest 'Tree construction' => sub {
    my $tree = Tree::MultiNode->new;
    isa_ok($tree, 'Tree::MultiNode');
    isa_ok($tree->{'top'}, 'Tree::MultiNode::Node');
};

subtest 'Tree destruction clears refs' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("a", 1);
    $handle->add_child("b", 2);
    $handle->down(0);
    $handle->add_child("deep", "val");

    # Just verify DESTROY doesn't crash
    $tree->DESTROY();
    pass('DESTROY completed without error');
};

done_testing();
