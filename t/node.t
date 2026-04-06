#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# ============================================================================
# Tree::MultiNode::Node tests
# ============================================================================

subtest 'Node construction - empty' => sub {
    my $node = Tree::MultiNode::Node->new();
    isa_ok($node, 'Tree::MultiNode::Node');
    is($node->key(),   undef, 'empty node has undef key');
    is($node->value(), undef, 'empty node has undef value');
    is(ref($node->children()), 'ARRAY', 'empty node has children array');
    is(scalar @{$node->children()}, 0, 'empty node has no children');
    is($node->parent(), undef, 'empty node has no parent');
};

subtest 'Node construction - with key and value' => sub {
    my $node = Tree::MultiNode::Node->new("name", "Larry");
    is($node->key(),   "name",  'key set on construction');
    is($node->value(), "Larry", 'value set on construction');
};

subtest 'Node construction - cloning' => sub {
    my $orig = Tree::MultiNode::Node->new("color", "blue");
    my $clone = Tree::MultiNode::Node->new($orig);
    isa_ok($clone, 'Tree::MultiNode::Node');
    is($clone->key(),   "color", 'cloned key');
    is($clone->value(), "blue",  'cloned value');
};

subtest 'Node key/value setters' => sub {
    my $node = Tree::MultiNode::Node->new();
    is($node->key("hello"),   "hello",   'key setter returns new key');
    is($node->key(),          "hello",   'key getter returns set key');
    is($node->value("world"), "world",   'value setter returns new value');
    is($node->value(),        "world",   'value getter returns set value');
};

subtest 'Node clear_key / clear_value' => sub {
    my $node = Tree::MultiNode::Node->new("k", "v");
    my $old_key = $node->clear_key();
    is($old_key,      "k",   'clear_key returns old key');
    is($node->key(),  undef, 'key is undef after clear');

    my $old_val = $node->clear_value();
    is($old_val,        "v",   'clear_value returns old value');
    is($node->value(), undef, 'value is undef after clear');
};

subtest 'Node child_keys / child_values / child_kv_pairs' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("x", 10);
    $handle->add_child("y", 20);
    $handle->add_child("z", 30);

    my $node = $handle->{'curr_node'};
    my @keys = $node->child_keys();
    is_deeply(\@keys, ["x", "y", "z"], 'child_keys returns all keys in order');

    my @vals = $node->child_values();
    is_deeply(\@vals, [10, 20, 30], 'child_values returns all values in order');

    my %kv = $node->child_kv_pairs();
    is_deeply(\%kv, {x => 10, y => 20, z => 30}, 'child_kv_pairs returns hash');
};

subtest 'Node child_key_positions' => sub {
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);
    $handle->add_child("alpha", 1);
    $handle->add_child("beta",  2);
    $handle->add_child("gamma", 3);

    my $node = $handle->{'curr_node'};
    my %pos = $node->child_key_positions();
    is($pos{'alpha'}, 0, 'alpha at position 0');
    is($pos{'beta'},  1, 'beta at position 1');
    is($pos{'gamma'}, 2, 'gamma at position 2');
};

done_testing();
