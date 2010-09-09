use Test::More;
use strict;
use warnings;

use Dancer::Headers;
use Dancer::ModuleLoader;

my $headers = ['Some-Header' => 42];
my $dh = Dancer::Headers->new(headers => $headers);
is $dh->get('Some-Header'), '42',
    "Dancer::Headers works with arrayref";

is_deeply $dh->get_all, {'Some-Header' => 42},
    "get_all works";

ok(!$dh->get('Foo-Bar'), 'no header define for Foo-Bar');

if ( Dancer::ModuleLoader->load('HTTP::Headers') ) {
    my $headers = HTTP::Headers->new( 'Some-Header' => 42 );
    $dh = Dancer::Headers->new( headers => $headers );
    is $dh->get('Some-Header'), '42',
      "Dancer::Headers works with HTTP::Headers object";

    is_deeply $dh->get_all, { 'Some-Header' => 42 }, "get_all works";

    $headers->header( 'Other-Header' => 23 );
    $dh = Dancer::Headers->new( headers => $headers );
    is_deeply $dh->get_all, { 'Some-Header' => 42, 'Other-Header' => 23 };
}

done_testing;
