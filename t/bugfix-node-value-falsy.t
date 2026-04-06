#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# Bug fix: Node::value() should accept falsy values including undef

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

done_testing;
