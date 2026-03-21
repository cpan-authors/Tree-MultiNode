# CLAUDE.md — Tree::MultiNode

## What is this

A Perl module for modeling hierarchical data as multi-node trees. Each node has a key, a value, and an ordered list of children. Operations use a Handle (cursor) that points into the tree.

Three packages in one file (`lib/Tree/MultiNode.pm`):
- `Tree::MultiNode` — tree container (holds the top node)
- `Tree::MultiNode::Node` — individual node (key, value, children, parent)
- `Tree::MultiNode::Handle` — cursor for navigating and manipulating the tree

## Commands

```bash
perl Makefile.PL && make        # Build
make test                       # Run tests (t/)
prove -b xt/*.t                 # Extended tests (pod coverage)
prove -bv t/01-multinode.t      # Run a single test file verbosely
```

## Architecture

- Single-file module: `lib/Tree/MultiNode.pm`
- Tests: `t/00-load.t` (smoke), `t/01-multinode.t` (functional)
- Extended tests: `xt/` (pod, pod-coverage)
- CI: GitHub Actions across Linux (Perl 5.8–latest), macOS, Windows

## Conventions

- Tests use `Test::More` with a declared plan (`tests => N`)
- Tests run under taint mode (`#!perl -T`)
- No external dependencies beyond core Perl and Test::More
- `$Tree::MultiNode::debug` enables verbose debug prints throughout

## Known Issues

- Several methods use `shift || $self->{'curr_pos'}` which treats position 0 as falsy — open PRs #2 and #3 address this pattern
- `Node::new()` has `$key || undef` which drops falsy keys like `0` or `""` — PR #3 addresses this
- POD for `remove_child` heading actually documents `kv_pairs` — PR #3 fixes this
- `remove_child` does not reset `curr_pos`/`curr_child` on the handle after removal
- `Node::value()` setter uses `defined $value` so you cannot set a value to `undef` (use `clear_value()` instead)
