use Test::More tests => 1;
use Plack::Middleware::MailOnError;
use Devel::StackTrace;

sub foo {
    bar();
}

sub baz {
    return Plack::Middleware::MailOnError->text_trace(Devel::StackTrace->new());
}

sub bar {
    baz();
}

my $result = foo();

# A bit more filler

is($result, <<'EOF', "");
1:  in main::baz at t/01-stacktrace.t line 14
       11: }
       12: 
       13: sub bar {
***    14:     baz();
       15: }
       16: 
       17: my $result = foo();


2:  in main::bar at t/01-stacktrace.t line 6
        3: use Devel::StackTrace;
        4: 
        5: sub foo {
***     6:     bar();
        7: }
        8: 
        9: sub baz {


3:  in main::foo at t/01-stacktrace.t line 17
       14:     baz();
       15: }
       16: 
***    17: my $result = foo();
       18: 
       19: # A bit more filler
       20: 


EOF
