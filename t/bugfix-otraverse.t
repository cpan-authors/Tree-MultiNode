#!perl -T

use strict;
use warnings;
use Test::More;

use Tree::MultiNode;

# otraverse: verify it works correctly with object + method pattern

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
