package Dancer::Handler::PSGI;

use strict;
use warnings;
use Carp;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::SharedData;
use Dancer::Logger;

sub new {
    my $class = shift;

    croak "Plack::Request is needed by the PSGI handler"
      unless Dancer::ModuleLoader->load('Plack::Request');

    my $self = {};
    bless $self, $class;
    return $self;
}

sub start {
    my $self = shift;
    my $app = $self->psgi_app();

    if (Dancer::Config::setting('plack_middlewares')) {
        $app = $self->apply_plack_middlewares($app);
    }

    return $app;
}

sub apply_plack_middlewares {
    my ($self, $app) = @_;
    my $middlewares = Dancer::Config::setting('plack_middlewares');

    croak "Plack::Builder is needed for middlewares support"
      unless Dancer::ModuleLoader->load('Plack::Builder');

    my $builder = Plack::Builder->new();
    for my $m (@$middlewares) {
        $builder->add_middleware($m->[0], %{$m->[1]});
    }
    $app = $builder->to_app($app);

    return $app;
}

sub init_request_headers {
    my ($self, $env) = @_;
    my $plack = Plack::Request->new($env);
    Dancer::SharedData->headers($plack->headers);
}

1;
