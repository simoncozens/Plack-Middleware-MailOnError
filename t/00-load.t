#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::MailOnError' );
}

diag( "Testing Plack::Middleware::MailOnError $Plack::Middleware::MailOnError::VERSION, Perl $], $^X" );
