use Test::More tests => 8, import => ['!pass'];

# This test simulates the behaviour of the auto_reload feature,
# when a random route tree is refreshed.
# The underlying system is a route tree merge, that should be able
# to detect a route hander that has changed, and that should keep
# an untouched route handler.

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::App;
use Dancer::Route;

# first registry
get '/one' => sub { 1 }; # would be in One.pm
get '/two' => sub { 2 }; # would be in Two.pm
my $first_reg = Dancer::App->current->registry;

#use Data::Dumper;
#warn Dumper($first_reg);
#exit;

# make sure it looks OK
my $expected_patterns = ['/one', '/two'];
my $expected_results  = [1, 2];
my @routes = @{ $first_reg->{routes}{get} };
is_deeply([map { $_->{pattern} } @routes ], $expected_patterns, 
    "route patterns look OK");
is_deeply([map {$_->{code}->() } @routes], $expected_results, 
    "route actions look OK");

# Simulate a route handler tree reload
my $orig_reg = Dancer::App->current->registry;
Dancer::App->current->init_registry();

# here, simulate a reload of Two.pm
get '/two' => sub { "two" };
my $new_reg = Dancer::App->current->registry;

ok(Dancer::App->current->merge_registries($orig_reg, $new_reg),
    "route registry merge went OK"); 

# make sure the merge did success
my $second_reg = Dancer::App->current->registry;
$expected_patterns = ['/one', '/two'];
$expected_results  = [1, "two"];
@routes = @{ $second_reg->{routes}{get} };
is_deeply([map { $_->{pattern} } @routes ], $expected_patterns, 
    "route patterns look OK");
is_deeply([map {$_->{code}->() } @routes], $expected_results, 
    "route actions look OK");

# make sure a merge with an empty tree keeps the original one
my $third_reg = Dancer::Route::Registry->new;
ok(Dancer::App->current->registry->merge($second_reg, $third_reg),
    "merge with an empty tree (unchanged route trees)"); 
my $reg = Dancer::App->current->registry;
@routes = @{ $reg->{routes}{get} };
is_deeply([map { $_->{pattern} } @routes ], $expected_patterns, 
    "route patterns look OK");
is_deeply([map {$_->{code}->() } @routes], $expected_results, 
    "route actions look OK");

