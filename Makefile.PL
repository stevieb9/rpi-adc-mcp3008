use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::ADC::MCP3008',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/ADC/MCP3008.pm',
    ABSTRACT_FROM    => 'lib/RPi/ADC/MCP3008.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    LIBS             => ['-lwiringPi', '-lpthread'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-ADC-MCP3008-*' },
);
