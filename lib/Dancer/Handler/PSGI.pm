package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Headers;
use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::SharedData;
use Dancer::Logger;

sub new {
    my $class = shift;

    die "Plack::Request is needed by the PSGI handler"
      unless Dancer::ModuleLoader->load('Plack::Request');

    my $self = {};
    bless $self, $class;
    return $self;
}

sub dance {
    my $self = shift;

    my $app = sub {
        my $env = shift;
        $self->init_request_headers($env);
        my $request = Dancer::Request->new($env);
        $self->handle_request($request);
    };

    if (Dancer::Config::setting('plack_middlewares')) {
        $app = $self->apply_plack_middlewares($app);
    }

    return $app;
}

sub apply_plack_middlewares {
    my ($self, $app) = @_;

    my $middlewares = Dancer::Config::setting('plack_middlewares');
    die "Plack::Builder is needed for middlewares support"
      unless Dancer::ModuleLoader->load('Plack::Builder');

    my $builder = Plack::Builder->new();
    for my $m (@$middlewares) {
        $builder->add_middleware($m->[0], %{$m->[1]});
    }
    $app = $builder->to_app($app);
    $app;
}

sub init_request_headers {
    my ($self, $env) = @_;

    my $plack = Plack::Request->new($env);
    my $headers = Dancer::Headers->new(headers => $plack->headers);
    Dancer::SharedData->headers($headers);
}

1;
