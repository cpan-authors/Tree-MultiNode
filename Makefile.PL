use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tree::MultiNode',
    AUTHOR              => 'Kyle R. Burton <krburton@cpan.org>',
    VERSION_FROM        => 'lib/Tree/MultiNode.pm',
    ABSTRACT_FROM       => 'lib/Tree/MultiNode.pm',
    PL_FILES            => {},
    MIN_PERL_VERSION    => '5.008',
    LICENSE             => 'perl',
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'Scalar::Util' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tree-MultiNode-*' },
    META_MERGE  => {
        'meta-spec' => { version => 2 },
        resources => {
            license => ['http://dev.perl.org/licenses/'],
            bugtracker => {
                web => 'https://github.com/cpan-authors/Tree-MultiNode/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Tree-MultiNode.git',
                web  => 'https://github.com/cpan-authors/Tree-MultiNode',
            },
        },
        provides => {
            'Tree::MultiNode' => {
                file    => 'lib/Tree/MultiNode.pm',
                version => MM->parse_version('lib/Tree/MultiNode.pm'),
            },
            'Tree::MultiNode::Node' => {
                file    => 'lib/Tree/MultiNode/Node.pm',
                version => MM->parse_version('lib/Tree/MultiNode/Node.pm'),
            },
            'Tree::MultiNode::Handle' => {
                file    => 'lib/Tree/MultiNode/Handle.pm',
                version => MM->parse_version('lib/Tree/MultiNode/Handle.pm'),
            },
        },
    },
);
