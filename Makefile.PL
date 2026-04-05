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
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'Scalar::Util' => 0,
        ($ExtUtils::MakeMaker::VERSION < 6.64 ? ('Test::More' => 0) : ()),
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.64 ? (
        TEST_REQUIRES => {
            'Test::More' => 0,
        },
    ) : ()),
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
                version => '2.01',
            },
            'Tree::MultiNode::Node' => {
                file    => 'lib/Tree/MultiNode/Node.pm',
                version => '2.01',
            },
            'Tree::MultiNode::Handle' => {
                file    => 'lib/Tree/MultiNode/Handle.pm',
                version => '2.01',
            },
        },
    },
);
