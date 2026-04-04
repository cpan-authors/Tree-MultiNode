# NAME

[![testsuite](https://github.com/cpan-authors/Tree-MultiNode/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/Tree-MultiNode/actions/workflows/testsuite.yml)

Tree::MultiNode -- a multi-node tree object.  Most useful for
modeling hierarchical data structures.

# SYNOPSIS

    use Tree::MultiNode;
    use strict;
    use warnings;
    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

    $handle->set_key("top");
    $handle->set_value("level");

    $handle->add_child("child","1");
    $handle->add_child("child","2");

    $handle->first();
    $handle->down();

    $handle->add_child("grandchild","1-1");
    $handle->up();

    $handle->last();
    $handle->down();

    $handle->add_child("grandchild","2-1");
    $handle->up();

    $handle->top();
    &dump_tree($handle);

    my $depth = 0;
    sub dump_tree
    {
      ++$depth;
      my $handle = shift;
      my $lead = ' ' x ($depth*2);
      my($key,$val);

      ($key,$val) = $handle->get_data();

      print $lead, "key:   $key\n";
      print $lead, "val:   $val\n";
      print $lead, "depth: $depth\n";

      my $i;
      for( $i = 0; $i < scalar($handle->children); ++$i ) {
        $handle->down($i);
          &dump_tree($handle);
        $handle->up();
      }
      --$depth;
    }

# DESCRIPTION

Tree::MultiNode, Tree::MultiNode::Node, and MultiNode::Handle are objects
modeled after C++ classes that I had written to help me model hierarchical
information as data structures (such as the relationships between records in
an RDBMS).  The tree is basically a list of lists type data structure, where
each node has a key, a value, and a list of children.  The tree has no
internal sorting, though all operations preserve the order of the child
nodes.

## Creating a Tree

The concept of creating a handle based on a tree lets you have multiple handles
into a single tree without having to copy the tree.  You have to use a handle
for all operations on the tree (other than construction).

When you first construct a tree, it will have a single empty node.  When you
construct a handle into that tree, it will set the top node in the tree as
it's current node.

    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

## Using a Handle to Manipulate the Tree

At this point, you can set the key/value in the top node, or start adding
child nodes.

    $handle->set_key("blah");
    $handle->set_value("foo");

    $handle->add_child("quz","baz");
    # or
    $handle->add_child();

add\_child can take 3 parameters -- a key, a value, and a position.  The key
and value will set the key/value of the child on construction.  If pos is
passed, the new child will be inserted into the list of children.

To move the handle so it points at a child (so you can start manipulating that
child), there are a series of methods to call:

    $handle->first();   # sets the current child to the first in the list
    $handle->next();    # sets the next, or first if there was no next
    $handle->prev();    # sets the previous, or last if there was no next
    $handle->last();    # sets to the last child
    $handle->down();    # positions the handle's current node to the
                        # current child

To move back up, you can call the method up:

    $handle->up();      # moves to this node's parent

up() will fail if the current node has no parent node.  Most of the member
functions return either undef to indicate failure, or some other value to
indicate success.

## $Tree::MultiNode::debug

If set to a true value, it enables debugging output in the code.  This will
likely be removed in future versions as the code becomes more stable.

# API REFERENCE

## Tree::MultiNode

The tree object.

## Tree::MultiNode::new

    @param    package name or tree object [scalar]
    @returns  new tree object

Creates a new Tree.  The tree will have a single top level node when created.
The first node will have no value (undef) in either it's key or it's value.

    my $tree = Tree::MultiNode->new;

# SEE ALSO

Algorithms in C++
   Robert Sedgwick
   Addison Wesley 1992
   ISBN 0201510596

The Art of Computer Programming, Volume 1: Fundamental Algorithms,
   third edition, Donald E. Knuth

# AUTHORS

Kyle R. Burton <mortis@voicenet.com> (initial version, and maintenence)

Daniel X. Pape <dpape@canis.uiuc.edu> (see Changes file from the source archive)

Eric Joanis <joanis@cs.toronto.edu>

Todd Rinaldo <toddr@cpan.org>

# BUGS

Please report bugs via the issue tracker at
[https://github.com/cpan-authors/Tree-MultiNode/issues](https://github.com/cpan-authors/Tree-MultiNode/issues).

# LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See [perlartistic](https://metacpan.org/pod/perlartistic) and [perlgpl](https://metacpan.org/pod/perlgpl).
