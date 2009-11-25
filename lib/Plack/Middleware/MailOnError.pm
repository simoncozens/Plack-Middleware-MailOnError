package Plack::Middleware::MailOnError;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack;
use Plack::Util;
use Devel::StackTrace;
use Plack::Request;
use Try::Tiny;
use Email::Send;
use Sys::Hostname;

__PACKAGE__->mk_accessors(qw( page_generator 
admin_mail_address mailer mailer_args from_address));

our $StackTraceClass = "Devel::StackTrace";

# Optional since it needs PadWalker
if (try { require Devel::StackTrace::WithLexicals; 1 }) {
    $StackTraceClass = "Devel::StackTrace::WithLexicals";
}

sub call {
    my($self, $env) = @_;

    my $trace;
    local $SIG{__DIE__} = sub {
        $trace = $StackTraceClass->new;
        die @_;
    };

    my $res = try { $self->app->($env) };
    if ($trace && (!$res or $res->[0] == 500)) {
        $self->ship_as_mail($trace, $env) if $self->admin_mail_address;
        my $body = $self->page_generator ?
            $self->page_generator()->($env) : $self->_default_error_page();
        $res = [500, ['Content-Type' => 'text/html; charset=utf-8'], [ $body ]];
    }
    return $res;
}

sub ship_as_mail {
    my ($self, $trace, $env) = @_;
    my ($error) = $trace->frame(1)->args;
    $trace = $self->text_trace($trace);
    my $from_address = $self->from_address || "plack\@".hostname();
    use Data::Dumper;
    my $request = Dumper($env);
    my $message = <<EOM;
From: Plack <$from_address>
To: Adminstrator <@{[$self->admin_mail_address]}>
Subject: Error in Plack application

Error:
$error

Request environment:
$request

Stack Trace:
$trace

EOM
    my $sender = Email::Send->new({mailer => $self->mailer||'SMTP' });
    $sender->mailer_args($self->mailer_args);
    $sender->send($message);
}

sub _default_error_page {return q{
<html>
<head> <title>Server Error</title> </head>
<body>
    <h1>Server Error</h1>

    <p> We're sorry, but an error has prevented your request from being
    carried out. The site administrator has been informed.</p>
</body>
</html>
}}

sub text_trace {
    my ($self, $trace) = @_;
    my $i = 0;
    my $out;
    $trace->next_frame;
    while (my $frame = $trace->next_frame) {
        $out .= join("", 
            ++$i,
            ":  ",
            $frame->subroutine ? ("in " . $frame->subroutine) : '',
            ' at ',
            $frame->filename ? $frame->filename : '',
            ' line ',
            $frame->line,
            _build_context($frame) || '',
            $frame->can('lexicals') ? _build_lexicals($frame->lexicals, $i) : ''
,
            "\n"
        );
    }
    return $out;
}

sub _build_context {
    my $frame = shift;
    my $file    = $frame->filename;
    my $linenum = $frame->line;
    my $code;
    my $output = "\n";
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        open my $fh, '<', $file or return;
        local $. = 0; local $/ = "\n";
        while (my $line = <$fh>) {
            next unless $. == $start .. $. == $end;
            $line    =~ s|\t|        |g;
            $output .= sprintf( '%s%5d: %s',($.==$linenum ? "*** " : "    "), 
                                $., $line);
        }
        close $file;
    }
    return $output."\n";
}

=head1 NAME

Plack::Middleware::MailOnError - Send emails when things break

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Plack::Middleware::MailOnError",
            page_generator => sub { "<html><body> OOPS! </body></html>" },
            admin_mail_address => 'root@localhost',
            mailer => 'SMTP',
            mailer_args => [Host => "localhost"],
            from_address => 'plack@localhost';

        $app;
    }

=head1 DESCRIPTION

This middleware allows you to present to the user custom error pages
when a Plack-based web application dies with an error. In addition, if
an email address is provided, the middleware sends details of the
request and Perl stacktrace to the administrator.

=head1 AUTHOR

Simon Cozens, C<< <simon at simon-cozens.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-middleware-mailonerror at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-MailOnError>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Simon Cozens.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Plack::Middleware::MailOnError
