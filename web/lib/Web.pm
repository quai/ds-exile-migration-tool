package Web;
use Mojo::Base 'Mojolicious';

sub startup {
	my $self = shift;

	my $config = $self->plugin('Config');

	my $r = $self->routes;
	$r->get('/')->to('Plugins#overview');

}

1;
