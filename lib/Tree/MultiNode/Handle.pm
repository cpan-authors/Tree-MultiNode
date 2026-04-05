package Tree::MultiNode::Handle;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(weaken);

our $VERSION = '2.01';

sub _debug {
    return unless $Tree::MultiNode::debug;
    no warnings 'uninitialized';
    print @_;
}

=head1 NAME

Tree::MultiNode::Handle -- a cursor for navigating a Tree::MultiNode tree.

=head1 DESCRIPTION

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

=cut

=head2 Tree::MultiNode::Handle::new

Constructs a new handle.  You must pass a tree object to Handle::new.

  my $tree   = Tree::MultiNode->new;
  my $handle = Tree::MultiNode::Handle->new($tree);

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;

    my $self = {};
    bless $self, $class;
    my $data = shift;
    _debug(__PACKAGE__, "::new() ref($data) is: ", ref($data), "\n");
    if ( ref($data) eq "Tree::MultiNode::Handle" ) {
        $self->_clone($data);
    }
    else {
        unless ( ref($data) eq "Tree::MultiNode" ) {
            confess "Error, invalid Tree::MultiNode reference:  $data\n";
        }

        $self->{'tree'}       = $data;
        $self->{'curr_pos'}   = undef;
        $self->{'curr_node'}  = $data->{'top'};
        $self->{'curr_child'} = undef;
        $self->{'curr_depth'} = 0;
    }
    return $self;
}

#
# internal method for making the current handle a copy of another
# handle...
#
sub _clone {
    my $self = shift;
    my $them = shift;
    _debug(__PACKAGE__, "::_clone() cloning: ", $them, "\n");
    _debug(__PACKAGE__, "::_clone() depth: ", $them->{'curr_depth'}, "\n");
    $self->{'tree'}       = $them->{'tree'};
    $self->{'curr_pos'}   = $them->{'curr_pos'};
    $self->{'curr_node'}  = $them->{'curr_node'};
    $self->{'curr_child'} = $them->{'curr_child'};
    $self->{'curr_depth'} = $them->{'curr_depth'};
    return 1;
}

=head2 Tree::MultiNode::Handle::tree

Returns the tree that was used to construct the node.  Useful if you're
trying to create another node into the tree.

  my $handle2 = Tree::MultiNode::Handle->new($handle->tree());

=cut

sub tree {
    my $self = shift;
    return $self->{'tree'};
}

=head2 Tree::MultiNode::Handle::get_data

Retrieves both the key, and value (as an array) for the current node.

  my ($key,$val) = $handle->get_data();

=cut

sub get_data {
    my $self = shift;
    my $node = $self->{'curr_node'};

    return ( $node->key, $node->value );
}

=head2 Tree::MultiNode::Handle::get_key

Retrieves the key for the current node.

  $key = $handle->get_key();

=cut

sub get_key {
    my $self = shift;
    my $node = $self->{'curr_node'};

    my $key = $node->key();

    _debug(__PACKAGE__, "::get_key() getting from ", $node, " : ", $key, "\n");

    return $key;
}

=head2 Tree::MultiNode::Handle::set_key

Sets the key for the current node.

  $handle->set_key("lname");

=cut

sub set_key {
    my $self = shift;
    my $key  = shift;
    my $node = $self->{'curr_node'};

    _debug(__PACKAGE__, "::set_key() setting key \"", $key, "\" on: ", $node, "\n");

    return $node->key($key);
}

=head2 Tree::MultiNode::Handle::get_value

Retrieves the value for the current node.

  $val = $handle->get_value();

=cut

sub get_value {
    my $self = shift;
    my $node = $self->{'curr_node'};

    my $value = $node->value();

    _debug(__PACKAGE__, "::get_value() getting from ", $node, " : ", $value, "\n");

    return $value;
}

=head2 Tree::MultiNode::Handle::set_value

Sets the value for the current node.

  $handle->set_value("Wall");

=cut

sub set_value {
    my $self  = shift;
    my $value = shift;
    my $node  = $self->{'curr_node'};

    _debug(__PACKAGE__, "::set_value() setting value \"", $value, "\" on: ", $node, "\n");

    return $node->value($value);
}

=head2 Tree::MultiNode::Handle::get_child

get_child takes an optional parameter which is the position of the child
that is to be retrieved.  If this position is not specified, get_child
attempts to return the current child.  get_child returns a Node object.

  my $child_node = $handle->get_child();

=cut

sub get_child {
    my $self     = shift;
    my $children = $self->{'curr_node'}->children;
    my $pos      = shift;
    $pos = defined $pos ? $pos : $self->{'curr_pos'};

    _debug(__PACKAGE__, "::get_child() children: ", $children, "   ", $pos, "\n");

    unless ( defined $children ) {
        return undef;
    }

    unless ( defined $pos && $pos <= $#{$children} ) {
        my $num = $#{$children};
        confess "Error, $pos is an invalid position [$num] $children.\n";
    }

    _debug(__PACKAGE__, "::get_child() returning [$pos]: ",
      ${$children}[$pos], "\n");
    return ( ${$children}[$pos] );
}

=head2 Tree::MultiNode::Handle::add_child

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

=cut

sub add_child {
    my $self = shift;
    my ( $key, $value, $pos ) = @_;
    my $children = $self->{'curr_node'}->children;
    _debug(__PACKAGE__, "::add_child() children: ", $children, "\n");
    my $child = Tree::MultiNode::Node->new( $key, $value );
    $child->{'parent'} = $self->{'curr_node'};
    weaken($child->{'parent'});

    _debug(__PACKAGE__, "::add_child() adding child ", $child, " (", $key, ",", $value, ") ",
      "to: ", $children, "\n");

    if ( defined $pos ) {
        _debug(__PACKAGE__, "::add_child() adding at ", $pos, " ", $child, "\n");
        unless ( $pos >= 0 && $pos <= $#{$children} ) {
            my $num = $#{$children};
            confess "Position $pos is invalid for child position [$num] $children.\n";
        }
        splice( @{$children}, $pos, 1, $child, ${$children}[$pos] );
    }
    else {
        _debug(__PACKAGE__, "::add_child() adding at end ", $child, "\n");
        push @{$children}, $child;
    }

    _debug(__PACKAGE__, "::add_child() children:",
      join( ',', @{ $self->{'curr_node'}->children } ), "\n");
}

=head2 Tree::MultiNode::Handle::add_child_node

Adds an existing node (or the top node of another tree) as a child of the
current node.  Works like C<add_child()> but accepts a pre-built
L<Tree::MultiNode::Node> or L<Tree::MultiNode> object instead of a key/value
pair.

When a Tree::MultiNode (tree) object is passed, its top node is extracted
and added as a child.  The original tree remains valid but now shares
structure with this tree -- the caller should not modify the original tree
after this call.

When a position is given, the new child is inserted before the existing
child at that position.  Without a position, the child is appended to the
end.

  # append an existing node as the last child
  my $node = Tree::MultiNode::Node->new("color", "red");
  $handle->add_child_node($node);

  # insert at a specific position
  $handle->add_child_node($node, 0);   # insert as first child

  # graft another tree's root node
  my $other = Tree::MultiNode->new();
  $handle->add_child_node($other);

=cut

sub add_child_node {
    my $self = shift;
    my ( $child, $pos ) = @_;
    my $children = $self->{'curr_node'}->children;
    _debug(__PACKAGE__, "::add_child_node() children: ", $children, "\n");
    if ( ref($child) eq 'Tree::MultiNode' ) {
        $child = $child->{'top'};
    }
    confess "Invalid child argument.\n"
      if ( ref($child) ne 'Tree::MultiNode::Node' );

    $child->{'parent'} = $self->{'curr_node'};
    weaken($child->{'parent'});

    _debug(__PACKAGE__, "::add_child_node() adding child ", $child,
      " to: ", $children, "\n");

    if ( defined $pos ) {
        _debug(__PACKAGE__, "::add_child_node() adding at ", $pos, " ", $child, "\n");
        unless ( $pos >= 0 && $pos <= $#{$children} ) {
            my $num = $#{$children};
            confess "Position $pos is invalid for child position [$num] $children.\n";
        }
        splice( @{$children}, $pos, 1, $child, ${$children}[$pos] );
    }
    else {
        _debug(__PACKAGE__, "::add_child_node() adding at end ", $child, "\n");
        push @{$children}, $child;
    }

    _debug(__PACKAGE__, "::add_child_node() children:",
      join( ',', @{ $self->{'curr_node'}->children } ), "\n");
}

=head2 Tree::MultiNode::Handle::depth

Gets the depth for the current node.

  my $depth = $handle->depth();

=cut

sub depth {
    my $self = shift;
    my $node = $self->{'curr_node'};

    _debug(__PACKAGE__, "::depth() getting depth \"", $self->{'curr_depth'}, "\" ",
      "on: ", $node, "\n");

    return $self->{'curr_depth'};
}

=head2 Tree::MultiNode::Handle::select

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

=cut

sub select {
    my $self = shift;
    my $key  = shift;
    my $code = shift || sub { return shift eq shift; };
    my ( $child, $pos );
    my $found = undef;

    $pos = 0;
    foreach $child ( $self->children() ) {
        if ( $code->( $key, $child->key() ) ) {
            $self->{'curr_pos'}   = $pos;
            $self->{'curr_child'} = $child;
            ++$found;
            last;
        }
        ++$pos;
    }

    return $found;
}

=head2 Tree::MultiNode::Handle::position

Sets, or retrieves the current child position.

  print "curr child pos is: ", $handle->position(), "\n";
  $handle->position(5);    # sets the 6th child as the current child

=cut

sub position {
    my $self = shift;
    my $pos  = shift;

    _debug(__PACKAGE__, "::position() ", $self, "  ", $pos, "\n");

    unless ( defined $pos ) {
        return $self->{'curr_pos'};
    }

    my $children = $self->{'curr_node'}->children;
    _debug(__PACKAGE__, "::position() children: ", $children, "\n");
    _debug(__PACKAGE__, "::position() position is $pos  ",
      $#{$children}, "\n");
    unless ( $pos >= 0 && $pos <= $#{$children} ) {
        my $num = $#{$children};
        confess "Error, $pos is invalid [$num] $children.\n";
    }
    $self->{'curr_pos'}   = $pos;
    $self->{'curr_child'} = $self->get_child($pos);
    return $self->{'curr_pos'};
}

=head2 Tree::MultiNode::Handle::first
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

=cut

sub first {
    my $self = shift;
    my $children = $self->{'curr_node'}->children;

    unless ( defined $children && @{$children} ) {
        return undef;
    }

    $self->{'curr_pos'}   = 0;
    $self->{'curr_child'} = $self->get_child(0);
    _debug(__PACKAGE__, "::first() set child[", $self->{'curr_pos'}, "]: ",
      $self->{'curr_child'}, "\n");
    return $self->{'curr_pos'};
}

sub next {
    my $self     = shift;
    my $children = $self->{'curr_node'}->children;
    _debug(__PACKAGE__, "::next() children: ", $children, "\n");

    # If no current child, behave like first() per documented contract
    unless ( defined $self->{'curr_pos'} ) {
        return $self->first();
    }

    my $pos = $self->{'curr_pos'} + 1;
    unless ( $pos >= 0 && $pos <= $#{$children} ) {
        return undef;
    }

    $self->{'curr_pos'}   = $pos;
    $self->{'curr_child'} = $self->get_child($pos);
    return $self->{'curr_pos'};
}

sub prev {
    my $self     = shift;
    my $children = $self->{'curr_node'}->children;
    _debug(__PACKAGE__, "::prev() children: ", $children, "\n");

    # If no current child, behave like last() per documented contract
    unless ( defined $self->{'curr_pos'} ) {
        return $self->last();
    }

    my $pos = $self->{'curr_pos'} - 1;
    unless ( $pos >= 0 && $pos <= $#{$children} ) {
        return undef;
    }

    $self->{'curr_pos'}   = $pos;
    $self->{'curr_child'} = $self->get_child($pos);
    return $self->{'curr_pos'};
}

sub last {
    my $self     = shift;
    my $children = $self->{'curr_node'}->children;

    unless ( defined $children && @{$children} ) {
        return undef;
    }

    my $pos      = $#{$children};
    _debug(__PACKAGE__, "::last() children [", $pos, "]: ", $children, "\n");

    $self->{'curr_pos'}   = $pos;
    $self->{'curr_child'} = $self->get_child($pos);
    return $self->{'curr_pos'};
}

=head2 Tree::MultiNode::Handle::down

down() moves the handle to point at the current child node.  It fails
if there is no current child node.  When down() is called, the current
child becomes invalid (undef).

  $handle->down();

=cut

sub down {
    my $self = shift;
    my $pos  = shift;
    my $node = $self->{'curr_node'};
    return undef unless defined $node;
    my $children = $node->children;
    _debug(__PACKAGE__, "::down() children: ", $children, "\n");

    if ( defined $pos ) {
        unless ( defined $self->position($pos) ) {
            confess "Error, $pos was an invalid position.\n";
        }
    }

    # Prevent corrupting the handle when no child is selected
    unless ( defined $self->{'curr_child'} ) {
        return undef;
    }

    $self->{'curr_pos'}   = undef;
    $self->{'curr_node'}  = $self->{'curr_child'};
    $self->{'curr_child'} = undef;
    ++$self->{'curr_depth'};
    _debug(__PACKAGE__, "::down() set to: ", $self->{'curr_node'}, "\n");

    return 1;
}

=head2 Tree::MultiNode::Handle::up

up() moves the handle to point at the parent of the current node.  It fails
if there is no parent node.  When up() is called, the current child becomes
invalid (undef).

  $handle->up();

=cut

sub up {
    my $self = shift;
    my $node = $self->{'curr_node'};
    return undef unless defined $node;
    my $parent = $node->parent();

    unless ( defined $parent ) {
        return undef;
    }

    $self->{'curr_pos'}   = undef;
    $self->{'curr_node'}  = $parent;
    $self->{'curr_child'} = undef;
    --$self->{'curr_depth'};

    return 1;
}

=head2 Tree::MultiNode::Handle::top

Resets the handle to point back at the top of the tree.
When top() is called, the current child becomes invalid (undef).

  $handle->top();

=cut

sub top {
    my $self = shift;
    my $tree = $self->{'tree'};

    $self->{'curr_pos'}   = undef;
    $self->{'curr_node'}  = $tree->{'top'};
    $self->{'curr_child'} = undef;
    $self->{'curr_depth'} = 0;

    return 1;
}

=head2 Tree::MultiNode::Handle::children

This returns an array of Node objects that represents the children of the
current Node.  Unlike Node::children(), the array Handle::children() is not
a reference to an array, but an array.  Useful if you need to iterate through
the children of the current node.

  print "There are: ", scalar($handle->children()), " children\n";
  foreach $child ($handle->children()) {
    print $child->key(), " : ", $child->value(), "\n";
  }

=cut

sub children {
    my $self = shift;
    my $node = $self->{'curr_node'};
    return undef unless defined $node;
    my $children = $node->children;

    return @{$children};
}

=head2 Tree::MultiNode::Handle::num_children

Returns the number of children for the current node.  This is more
efficient than C<scalar($handle-E<gt>children())> because it does not
copy the children array.

  my $count = $handle->num_children();

=cut

sub num_children {
    my $self = shift;
    return $self->{'curr_node'}->num_children();
}

=head2 Tree::MultiNode::Handle::child_key_positions

This function returns a hash table that consists of the
child keys as the hash keys, and the position in the child
array as the value.  This allows for a quick and dirty way
of looking up the position of a given key in the child list.

  my %h = $handle->child_key_positions();

=cut

sub child_key_positions {
    my $self = shift;
    my $node = $self->{'curr_node'};

    return $node->child_key_positions();
}

=head2 Tree::MultiNode::Handle::get_child_key

Returns the key at the specified position, or from the corresponding child
node.

  my $key = $handle->get_child_key();

=cut

sub get_child_key {
    my $self = shift;
    my $pos  = shift;
    $pos = $self->{'curr_pos'} unless defined $pos;

    my $node = $self->get_child($pos);
    return defined $node ? $node->key() : undef;
}

=head2 Tree::MultiNode::Handle::get_child_value

Returns the value at the specified position, or from the corresponding child
node.

  my $value = $handle->get_child_value();

=cut

sub get_child_value {
    my $self = shift;
    my $pos  = shift;
    $pos = defined $pos ? $pos : $self->{'curr_pos'};

    _debug(__PACKAGE__, "::get_child_value() pos is: ", $pos, "\n");
    my $node = $self->get_child($pos);
    return defined $node ? $node->value() : undef;
}

=head2 Tree::MultiNode::Handle::kv_pairs

Returns Tree::MultiNode::Node::child_kv_pairs() for the
current node for this handle.

  my %pairs = $handle->kv_pairs();

=cut

sub kv_pairs {
    my $self = shift;
    my $node = $self->{'curr_node'};

    return $node->child_kv_pairs();
}

=head2 Tree::MultiNode::Handle::remove_child

Removes the child at the specified position, or at the current child
position if no position is given.  Returns the key and value of the
removed child node.

  my ($key, $value) = $handle->remove_child(0);

=cut

sub remove_child {
    my $self = shift;
    my $pos  = shift;
    $pos = defined $pos ? $pos : $self->{'curr_pos'};

    _debug(__PACKAGE__, "::remove_child() pos is: ", $pos, "\n");

    my $children = $self->{'curr_node'}->children;

    unless ( defined $children ) {
        return undef;
    }

    unless ( defined $pos && $pos >= 0 && $pos <= $#{$children} ) {
        my $num = $#{$children};
        confess "Error, $pos is an invalid position [$num] $children.\n";
    }

    my $node = splice( @{$children}, $pos, 1 );
    $self->{'curr_node'}->{'children'} = $children;

    # Reset handle's child cursor to avoid stale references
    $self->{'curr_pos'}   = undef;
    $self->{'curr_child'} = undef;

    return ( $node->key, $node->value );
}

=head2 Tree::MultiNode::Handle::child_keys

Returns the keys from the current node's children.
Returns undef if there is no current node.

=cut

sub child_keys {
    my $self = shift;
    my $node = $self->{'curr_node'};
    return undef unless $node;
    return $node->child_keys();
}

=head2 Tree::MultiNode::Handle::child_values

Returns the values from the current node's children.
Returns undef if there is no current node.

=cut

sub child_values {
    my $self = shift;
    my $node = $self->{'curr_node'};
    return undef unless $node;
    return $node->child_values();
}

=head2 Tree::MultiNode::Handle::traverse

  $handle->traverse(sub {
    my $h = pop;
    printf "%sk: %s v: %s\n",('  ' x $handle->depth()),$h->get_data();
  });

Traverse takes a subroutine reference, and will visit each node of the tree,
starting with the node the handle currently points to, recursively down from the
current position of the handle.  Each time the subroutine is called, it will be
passed a handle which points to the node to be visited.  Any additional
arguments after the sub ref will be passed to the traverse function _before_
the handle is passed.  This should allow you to pass constant arguments to the
sub ref.

Modifying the node that the handle points to will cause traverse to work
from the new node forward.

=cut

sub traverse {
    my ( $self, $subref, @args ) = @_;
    confess "Error, invalid sub ref: $subref\n" unless 'CODE' eq ref($subref);

    # operate on a cloned handle
    return Tree::MultiNode::Handle->new($self)->_traverseImpl( $subref, @args );
}

sub _traverseImpl {
    my ( $self, $subref, @args ) = @_;
    $subref->( @args, $self );
    my $num_children = $self->num_children();
    for ( my $i = 0; $i < $num_children; ++$i ) {
        $self->down($i);
        $self->_traverseImpl( $subref, @args );
        $self->up();
    }
    return;
}

=head2 Tree::MultiNode::Handle::otraverse

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
=cut

sub otraverse {
    my ( $self, $obj, $method, @args ) = @_;
    confess "Error, invalid sub ref: $method\n" unless 'CODE' eq ref($method);

    # operate on a cloned handle
    return Tree::MultiNode::Handle->new($self)->_otraverseImpl( $obj, $method, @args );
}

sub _otraverseImpl {
    my ( $self, $obj, $method, @args ) = @_;
    $obj->$method( @args, $self );
    my $num_children = $self->num_children();
    for ( my $i = 0; $i < $num_children; ++$i ) {
        $self->down($i);
        $self->_otraverseImpl( $obj, $method, @args );
        $self->up();
    }
    return;
}

1;
