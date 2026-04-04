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

## Tree::MultiNode::Node

Please note that the Node object is used internally by the MultiNode object.  
Though you have the ability to interact with the nodes, it is unlikely that
you should need to.  That being said, the interface is documented here anyway.

## Tree::MultiNode::Node::new

    new($)
      @param    package name or node object to clone [scalar]
      @returns  new node object

    new($$)
      @param    key   [scalar]
      @param    value [scalar]
      @returns  new node object

Creates a new Node.  There are three behaviors for new.  A constructor with no
arguments creates a new, empty node.  A single argument of another node object
will create a clone of the node object.  If two arguments are passed, the first
is stored as the key, and the second is stored as the value.

    # clone an existing node
    my $node = Tree::MultiNode::Node->new($oldNode);
    # or
    my $node = $oldNode->new();

    # create a new node
    my $node = Tree::MultiNode::Node->new;
    my $node = Tree::MultiNode::Node->new("fname");
    my $node = Tree::MultiNode::Node->new("fname","Larry");

## Tree::MultiNode::Node::key

    @param     key [scalar]
    @returns   the key [scalar]

Used to set, or retrieve the key for a node.  If a parameter is passed,
it sets the key for the node.  The value of the key member is always
returned.

    print $node3->key(), "\n";    # 'fname'

## Tree::MultiNode::Node::value

    @param    the value to set [scalar]
    @returns  the value [scalar]

Used to set, or retrieve the value for a node.  If a parameter is passed,
it sets the value for the node (including undef and other falsy values like
0 or "").  The value of the value member is always returned.

    print $node3->value(), "\n";   # 'Larry'
    $node3->value(0);              # sets value to 0
    $node3->value(undef);          # sets value to undef

## Tree::MultiNode::Node::clear\_key

    @returns  the deleted key

Clears the key member by deleting it.

    $node3->clear_key();

## Tree::MultiNode::Node::clear\_value

    @returns  the deleted value

Clears the value member by deleting it.

    $node3->clear_value();

## Tree::MultiNode::Node::children

    @returns  reference to children [array reference]

Returns a reference to the array that contains the children of the
node object.

    $array_ref = $node3->children();

## Tree::MultiNode::Node::child\_keys  
Tree::MultiNode::Node::child\_values
Tree::MultiNode::Node::child\_kv\_pairs

These functions return arrays consisting of the appropriate data
from the child nodes.

    my @keys     = $handle->child_keys();
    my @vals     = $handle->child_values();
    my %kv_pairs = $handle->child_kv_pairs();

## Tree::MultiNode::Node::child\_key\_positions  

This function returns a hash table that consists of the
child keys as the hash keys, and the position in the child
array as the value.  This allows for a quick and dirty way
of looking up the position of a given key in the child list.

    my %h = $node->child_key_positions();

## Tree::MultiNode::Node::parent

Returns a reference to the parent node of the current node.

    $node_parent = $node3->parent();

## Tree::MultiNode::Node::dump

Used for diagnostics, it prints out the members of the node.

    $node3->dump();

## Tree::MultiNode::Handle

Handle is used as a 'pointer' into the tree.  It has a few attributes that it keeps
track of.  These are:

    1. the top of the tree 
    2. the current node
    3. the current child node
    4. the depth of the current node

The top of the tree never changes, and you can reset the handle to point back at
the top of the tree by calling the top() method.  

The current node is where the handle is 'pointing' in the tree.  The current node
is changed with functions like top(), down(), and up().

The current child node is used for traversing downward into the tree.  The members
first(), next(), prev(), last(), and position() can be used to set the current child,
and then traverse down into it.

The depth of the current node is a measure of the length of the path
from the top of the tree to the current node, i.e., the top of the node
has a depth of 0, each of its children has a depth of 1, etc.

## Tree::MultiNode::Handle::new

Constructs a new handle.  You must pass a tree object to Handle::new.

    my $tree   = Tree::MultiNode->new;
    my $handle = Tree::MultiNode::Handle->new($tree);

## Tree::MultiNode::Handle::tree

Returns the tree that was used to construct the node.  Useful if you're
trying to create another node into the tree.

    my $handle2 = Tree::MultiNode::Handle->new($handle->tree());

## Tree::MultiNode::Handle::get\_data

Retrieves both the key, and value (as an array) for the current node.

    my ($key,$val) = $handle->get_data();

## Tree::MultiNode::Handle::get\_key

Retrieves the key for the current node.

    $key = $handle->get_key();

## Tree::MultiNode::Handle::set\_key

Sets the key for the current node.

    $handle->set_key("lname");

## Tree::MultiNode::Handle::get\_value

Retrieves the value for the current node.

    $val = $handle->get_value();

## Tree::MultiNode::Handle::set\_value

Sets the value for the current node.

    $handle->set_value("Wall");

## Tree::MultiNode::Handle::get\_child

get\_child takes an optional parameter which is the position of the child
that is to be retrieved.  If this position is not specified, get\_child 
attempts to return the current child.  get\_child returns a Node object.

    my $child_node = $handle->get_child();

## Tree::MultiNode::Handle::add\_child

This member adds a new child node to the end of the array of children for the
current node.  There are three optional parameters:

    - a key
    - a value
    - a position

If passed, the key and value will be set in the new child.  If a position is 
passed, the new child will be inserted into the current array of children at
the position specified.

    $handle->add_child();                    # adds a blank child
    $handle->add_child("language","perl");   # adds a child to the end
    $handle->add_child("language","C++",0);  # adds a child to the front

## Tree::MultiNode::Handle::add\_child\_node

Recently added via RT # 5435 -- Currently in need of proper documentation and test patches

    I've patched Tree::MultiNode 1.0.10 to add a method I'm currently calling add_child_node().
    It works just like add_child() except it takes either a Tree::MultiNode::Node or a 
    Tree::MultiNode object instead. I found this extremely useful when using recursion to populate
    a tree. It could also be used to subsume any tree into another tree, so this touches on the
    topic of the other bug item here asking for methods to copy/move trees/nodes.

## Tree::MultiNode::Handle::depth

Gets the depth for the current node.

    my $depth = $handle->depth();

## Tree::MultiNode::Handle::select

Sets the current child via a specified value -- basically it iterates
through the array of children, looking for a match.  You have to 
supply the key to look for, and optionally a sub ref to find it.  The 
default for this sub is 

    sub { return shift eq shift; }

Which is sufficient for testing the equality of strings (the most common
thing that I think will get stored in the tree).  If you're storing multiple
data types as keys, you'll have to write a sub that figures out how to 
perform the comparisons in a sane manner.

The code reference should take two arguments, and compare them -- return
false if they don't match, and true if they do.

    $handle->select('lname', sub { return shift eq shift; } );

## Tree::MultiNode::Handle::position

Sets, or retrieves the current child position.

    print "curr child pos is: ", $handle->position(), "\n";
    $handle->position(5);    # sets the 6th child as the current child

## Tree::MultiNode::Handle::first
Tree::MultiNode::Handle::next
Tree::MultiNode::Handle::prev
Tree::MultiNode::Handle::last

These functions manipulate the current child member.  first() sets the first
child as the current child, while last() sets the last.  next(), and prev() will
move to the next/prev child respectively.  If there is no current child node,
next() will have the same effect as first(), and prev() will operate as last().
prev() fails if the current child is the first child, and next() fails if the
current child is the last child -- i.e., they do not wrap around.

These functions will fail if there are no children for the current node.

    $handle->first();  # sets to the 0th child
    $handle->next();   # to the 1st child
    $handle->prev();   # back to the 0th child
    $handle->last();   # go straight to the last child.

## Tree::MultiNode::Handle::down

down() moves the handle to point at the current child node.  It fails
if there is no current child node.  When down() is called, the current
child becomes invalid (undef).

    $handle->down();

## Tree::MultiNode::Handle::up

up() moves the handle to point at the parent of the current node.  It fails
if there is no parent node.  When up() is called, the current child becomes
invalid (undef).

    $handle->up();

## Tree::MultiNode::Handle::top

Resets the handle to point back at the top of the tree.  
When top() is called, the current child becomes invalid (undef).

    $handle->top();

## Tree::MultiNode::Handle::children

This returns an array of Node objects that represents the children of the
current Node.  Unlike Node::children(), the array Handle::children() is not
a reference to an array, but an array.  Useful if you need to iterate through
the children of the current node.

    print "There are: ", scalar($handle->children()), " children\n";
    foreach $child ($handle->children()) {
      print $child->key(), " : ", $child->value(), "\n";
    }

## Tree::MultiNode::Handle::child\_key\_positions

This function returns a hash table that consists of the
child keys as the hash keys, and the position in the child
array as the value.  This allows for a quick and dirty way
of looking up the position of a given key in the child list.

    my %h = $handle->child_key_positions();

## Tree::MultiNode::Handle::get\_child\_key

Returns the key at the specified position, or from the corresponding child
node.

    my $key = $handle->get_child_key();

## Tree::MultiNode::Handle::get\_child\_value

Returns the value at the specified position, or from the corresponding child
node.

    my $value = $handle->get_child_value();

## Tree::MultiNode::Handle::kv\_pairs

Returns Tree::MultiNode::Node::child\_kv\_pairs() for the
current node for this handle.

    my %pairs = $handle->kv_pairs();

## Tree::MultiNode::Handle::remove\_child

Removes the child at the specified position, or at the current child
position if no position is given.  Returns the key and value of the
removed child node.

    my ($key, $value) = $handle->remove_child(0);

## Tree::MultiNode::Handle::child\_keys

Returns the keys from the current node's children.
Returns undef if there is no current node.

## Tree::MultiNode::Handle::traverse

    $handle->traverse(sub {
      my $h = pop;
      printf "%sk: %s v: %s\n",('  ' x $handle->depth()),$h->get_data();
    });

Traverse takes a subroutine reference, and will visit each node of the tree,
starting with the node the handle currently points to, recursively down from the
current position of the handle.  Each time the subroutine is called, it will be
passed a handle which points to the node to be visited.  Any additional
arguments after the sub ref will be passed to the traverse function \_before\_
the handle is passed.  This should allow you to pass constant arguments to the
sub ref.

Modifying the node that the handle points to will cause traverse to work
from the new node forward.

## Tree::MultiNode::Handle::otraverse

Like traverse(), but designed for passing an object method.  The first
argument after the handle should be the object, the second should be
the method name or code reference, followed by any additional arguments.
The handle is passed as the last argument to the method.

This allows you to have the subref be a method on an object (and still
pass the object's 'self' to the method).

    $handle->otraverse( $obj, \&Some::Object::method, $const1, \%const2 );

    ...
    sub method
    {
      my $handle = pop;
      my $self   = shift;
      my $const1 = shift;
      my $const2 = shift;
      # do something
    }

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
