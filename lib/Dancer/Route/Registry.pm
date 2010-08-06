package Dancer::Route::Registry;
use strict;
use warnings;

use base 'Dancer::Object';
use Dancer::Logger;

Dancer::Route::Registry->attributes(qw(
    id
    before_filters
));

my $id = 1;

sub init {
    my ($self) = @_;
    
    unless (defined $self->{id}) {
        $self->{id} = $id++;
    }
    $self->{routes} = {};
    $self->{before_filters} = [];
}

sub is_empty {
    my ($self) = @_;
    for my $method (keys %{ $self->{routes}}) {
        return 0 if scalar(@{ $self->{routes}{$method}});
    }
    return 1;
}   

sub before_filter {
    my ($class, $filter) = @_;
    Dancer::App->current->registry->add_before_filter($filter);
}

# replace any ':foo' by '(.+)' and stores all the named
# matches defined in $REG->{route_params}{$route}
sub add_before_filter {
    my ($self, $filter) = @_;

    my $compiled_filter = sub {
        return if Dancer::Response->halted;
        Dancer::Logger::core("entering before filter");
        
        eval { $filter->() };
        if ($@) {
            my $err = Dancer::Error->new(
                code => 500,
                title => 'Before filter error',
                message => "An error occured while executing the filter: $@");
            return Dancer::halt($err->render);
        }
    };

    push @{ $self->{before_filters} }, $compiled_filter;
}

sub routes {
    my ($self, $method) = @_;

    if ( $method ) {
        my $route = $self->{routes}{$method};
        $route ? return $route : [];
    }
    else {
        return $self->{routes};
    }
}

sub add_route {
    my ($self, $route) = @_;
    $self->{routes}{$route->method} ||= [];
    
    my @registered = @{ $self->{routes}{$route->method} };
    my $last = $registered[$#registered];
    $route->set_previous($last) if defined $last;
    push @{ $self->{routes}{$route->method} }, $route;
}

# sugar for add_route

sub register_route {
    my ($self, %args) = @_;

    # look if the caller (where the route is declared) exists as a Dancer::App
    # object
    my ($package) = caller(2);
    if (Dancer::App->app_exists($package)) {
        my $app = Dancer::App->get($package);
        my $route = Dancer::Route->new(prefix => $app->prefix, %args);
        $app->registry->add_route($route);
    }
    else {
        # FIXME maybe this code is useless, drop it later if so
        my $route = Dancer::Route->new(%args);
        $self->add_route($route);
    }
}

# sugar for Dancer.pm
# class, any, ARRAY(0x9864818), '/path', CODE(0x990ac88)
# or
# class, any, '/path', CODE(0x990ac88)
sub any_add {
    my ($self, $pattern, @rest) = @_;

    my @methods = qw(get post put delete options);

    if (ref($pattern) eq 'ARRAY') {
        @methods = @$pattern;
        $pattern = shift @rest;
    }

    die "Syntax error, methods should be provided as an ARRAY ref"
        if grep /^$pattern$/, @methods;

    $self->universal_add($_, $pattern, @rest) for @methods;
    return scalar(@methods);
}

sub universal_add {
    my ($self, $method, $pattern, @rest) = @_;

    my %options;
    my $code;

    if (@rest == 1) {
        $code = $rest[0];
    }
    else {
        %options = %{$rest[0]};
        $code = $rest[1];
    }

    my %route_args = (
        method => $method,
        code   => $code,
        options => \%options,
        pattern => $pattern,
    );

    $self->register_route(%route_args);
}

# look for a route in the given array
sub find_route {
    my ($self, $r, $reg) = @_;
    foreach my $route (@$reg) {
        return $route if $r->equals($route);
    }
    return undef;
}

1;
