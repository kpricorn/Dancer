use Test::More import => ['!pass'];

my @keywords = qw(
    after
    any
    before
    before_template
    cookies
    content_type
    dance
    debug
    dirname
    error
    false
    get 
    layout
    load
    load_app
    logger
    mime_type
    params
    pass
    path
    post 
    put
    r
    redirect
    request
    send_file
    send_error
    set
    set_cookie
    session
    splat
    status
    template
    uri_for
    upload
    true
    var
    vars
    warning
); 

plan tests => scalar(@keywords);

use Dancer ':syntax';

foreach my $symbol (@keywords) {
    ok(exists($::{$symbol}), "symbol `$symbol' is exported");
}
