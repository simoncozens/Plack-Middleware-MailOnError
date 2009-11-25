use strict;
use warnings;
use Test::More;
use Plack::Middleware::MailOnError;
use Plack::Builder;


my $handler = builder {
    enable "Plack::Middleware::MailOnError";
    sub { die "orz" }
};

my $res = $handler->(+{});
is scalar(@$res), 3;
is $res->[0], 500;
is_deeply $res->[1], ['Content-Type' => 'text/html; charset=utf-8'];
like $res->[2]->[0], qr/Server Error/;

$handler = builder {
    enable "Plack::Middleware::MailOnError",
        page_generator => sub { ok("I've been called"); return "It's all gone wrong" };
    sub { die "orz" }
};
$res = $handler->(+{});
is_deeply $res->[1], ['Content-Type' => 'text/html; charset=utf-8'];
like $res->[2]->[0], qr/gone wrong/;

done_testing;

