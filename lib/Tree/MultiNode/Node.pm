package Tree::MultiNode::Node;
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

Tree::MultiNode::Node -- a node in a Tree::MultiNode tree.

=head1 DESCRIPTION

Please note that the Node object is used internally by the MultiNode object.
Though you have the ability to interact with the nodes, it is unlikely that
you should need to.  That being said, the interface is documented here anyway.

=head2 Tree::MultiNode::Node::new

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

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {};
    bless $self, $class;

    my $node = shift;
    if ( ref($node) eq "Tree::MultiNode::Node" ) {

        # become a copy of that node...
        $self->_clone($node);
    }
    else {
        my ( $key, $value );
        $key   = $node;
        $value = shift;
        _debug(__PACKAGE__, "::new() key,val = ", $key, ",", $value, "\n");
        $self->{'children'} = [];
        $self->{'parent'}   = undef;
        $self->{'key'}      = defined $key ? $key : undef;
        $self->{'value'}    = defined $value ? $value : undef;
    }

    return $self;
}

#
# internal method for making the current node a clone of another
# node...
#
sub _clone {
    my $self = shift;
    my $them = shift;
    $self->{'parent'}   = $them->parent;
    weaken($self->{'parent'}) if defined $self->{'parent'};
    $self->{'children'} = [ $them->children ];
    $self->{'key'}      = $them->key;
    $self->{'value'}    = $them->value;
}

=head2 Tree::MultiNode::Node::key

  @param     key [scalar]
  @returns   the key [scalar]

Used to set, or retrieve the key for a node.  If a parameter is passed,
it sets the key for the node.  The value of the key member is always
returned.

  print $node3->key(), "\n";    # 'fname'

=cut

sub key {
    my ( $self, $key ) = @_;

    if ( @_ > 1 ) {
        _debug(__PACKAGE__, "::key() setting key: ", $key, " on ", $self, "\n");
        $self->{'key'} = $key;
    }

    return $self->{'key'};
}

=head2 Tree::MultiNode::Node::value

  @param    the value to set [scalar]
  @returns  the value [scalar]

Used to set, or retrieve the value for a node.  If a parameter is passed,
it sets the value for the node (including undef and other falsy values like
0 or "").  The value of the value member is always returned.

  print $node3->value(), "\n";   # 'Larry'
  $node3->value(0);              # sets value to 0
  $node3->value(undef);          # sets value to undef

=cut

sub value {
    my ( $self, $value ) = @_;

    if ( @_ > 1 ) {
        _debug(__PACKAGE__, "::value() setting value: ", $value, " on ", $self, "\n");
        $self->{'value'} = $value;
    }

    return $self->{'value'};
}

=head2 Tree::MultiNode::Node::clear_key

  @returns  the deleted key

Clears the key member by deleting it.

  $node3->clear_key();

=cut

sub clear_key {
    my $self = shift;
    return delete $self->{'key'};
}

=head2 Tree::MultiNode::Node::clear_value

  @returns  the deleted value

Clears the value member by deleting it.

  $node3->clear_value();

=cut

sub clear_value {
    my $self = shift;
    return delete $self->{'value'};
}

=head2 Tree::MultiNode::Node::children

  @returns  reference to children [array reference]

Returns a reference to the array that contains the children of the
node object.

  $array_ref = $node3->children();

=cut

sub children {
    my $self = shift;
    return $self->{'children'};
}

=head2 Tree::MultiNode::Node::child_keys
Tree::MultiNode::Node::child_values
Tree::MultiNode::Node::child_kv_pairs

These functions return arrays consisting of the appropriate data
from the child nodes.

  my @keys     = $handle->child_keys();
  my @vals     = $handle->child_values();
  my %kv_pairs = $handle->child_kv_pairs();

=cut

sub child_keys {
    my $self     = shift;
    my $children = $self->{'children'};
    my @keys;
    my $node;

    foreach $node (@$children) {
        push @keys, $node->key();
    }

    return @keys;
}

sub child_values {
    my $self     = shift;
    my $children = $self->{'children'};
    my @values;
    my $node;

    foreach $node (@$children) {
        push @values, $node->value();
    }

    return @values;
}

sub child_kv_pairs {
    my $self     = shift;
    my $children = $self->{'children'};
    my %h;
    my $node;

    foreach $node (@$children) {
        $h{ $node->key() } = $node->value();
    }

    return %h;
}

=head2 Tree::MultiNode::Node::child_key_positions

This function returns a hash table that consists of the
child keys as the hash keys, and the position in the child
array as the value.  This allows for a quick and dirty way
of looking up the position of a given key in the child list.

  my %h = $node->child_key_positions();

=cut

sub child_key_positions {
    my $self     = shift;
    my $children = $self->{'children'};
    my ( %h, $i, $node );

    $i = 0;
    foreach $node (@$children) {
        $h{ $node->key() } = $i++;
    }

    return %h;
}

=head2 Tree::MultiNode::Node::num_children

Returns the number of children for this node.

  my $count = $node->num_children();

=cut

sub num_children {
    my $self = shift;
    return scalar @{$self->{'children'}};
}

=head2 Tree::MultiNode::Node::parent

Returns a reference to the parent node of the current node.

  $node_parent = $node3->parent();

=cut

sub parent {
    my $self = shift;
    return $self->{'parent'};
}

=head2 Tree::MultiNode::Node::dump

Used for diagnostics, it prints out the members of the node.

  $node3->dump();

=cut

sub dump {
    my $self = shift;

    no warnings 'uninitialized';
    print "[dump] key:       ", $self->{'key'},      "\n";
    print "[dump] val:       ", $self->{'value'},    "\n";
    print "[dump] parent:    ", $self->{'parent'},   "\n";
    print "[dump] children:  ", $self->{'children'}, "\n";
}

sub _clearrefs {
    my $self = shift;
    delete $self->{'parent'};
    my $children = $self->{'children'};
    if ( defined $children ) {
        foreach my $child ( @{$children} ) {
            $child->_clearrefs() if defined $child;
        }
    }
    delete $self->{'children'};
}

1;
