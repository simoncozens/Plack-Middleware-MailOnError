use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Plack::Middleware::MailOnError',
    AUTHOR              => q{Simon Cozens <simon@simon-cozens.org>},
    VERSION_FROM        => 'lib/Plack/Middleware/MailOnError.pm',
    ABSTRACT_FROM       => 'lib/Plack/Middleware/MailOnError.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Plack::Middleware' => 0,
        'Devel::StackTrace' => 0,
        'Try::Tiny' => 0,
        'Email::Sender' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Plack-Middleware-MailOnError-*' },
);
