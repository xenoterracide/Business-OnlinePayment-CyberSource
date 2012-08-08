package Business::OnlinePayment::CyberSource::Action::ECHECK;

use 5.010;
use strict;
use warnings;
use utf8::all;

use Moose;
use MooseX::Types::Moose qw(Str);

# ABSTRACT:  Credit card action data for Business::OnlinePayment::CyberSource
# VERSION

extends 'Business::OnlinePayment::CyberSource::Action';

# Before constructor hook
# Accepts:  A hash or reference to a hash of construction parameters
# Returns:  A reference to a hash of construction parameters

sub BUILDARGS {
	my ( undef, @args ) = @_;
	my $data            = {};

	if ( scalar @args == 1 && ref $args[0] eq 'HASH' ) {
		$data             = shift @args;
	}
	elsif ( ( scalar @args % 2 ) == 0 ) {
		$data             = { @args };
	}

	$data->{type}       = 'ECHECK';

	return $data;
}

1;

=pod

=cut
