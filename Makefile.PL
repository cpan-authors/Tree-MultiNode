use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tree::MultiNode',
    AUTHOR              => 'Kyle R. Burton <krburton@cpan.org>',
    VERSION_FROM        => 'lib/Tree/MultiNode.pm',
    ABSTRACT_FROM       => 'lib/Tree/MultiNode.pm',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'Test::More'     => 0,  # For testing
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
    },
);
