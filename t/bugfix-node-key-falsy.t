#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# Verify Node::key() still works with falsy values (regression check)

subtest 'Node::key() handles falsy values' => sub {
    my $node = Tree::MultiNode::Node->new();
    $node->key(0);
    is($node->key(), 0, 'key can be set to 0');

    $node->key("");
    is($node->key(), "", 'key can be set to empty string');
};

done_testing;
