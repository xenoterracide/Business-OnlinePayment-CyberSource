package Business::OnlinePayment::CyberSource::Role::InputHandling;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

# ABSTRACT:  Input handling convenience methods for Business::OnlinePayment::CyberSource
# VERSION

#### Subroutine Definitions ####

# Converts input into a hashref
# Accepts:  A hash or reference to a hash
# Returns:  A reference to the supplied hash

sub _parse_input { ## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines )
	my ( undef, @args ) = @_;
	my $data            = {};

	# shift off first element if only one exists and is of type HASH
	if ( scalar @args == 1 && ref $args[0] eq 'HASH' ) {
		$data             = shift @args;
	}
	# Cast into a hash if number of elements is even and first element is a string
	elsif ( ( scalar @args % 2 ) == 0 && ref $args[0] eq '' ) {
		$data             = { @args };
	}

	return $data;
}

1;

=pod

=head1 SYNOPSIS

  package Thing;

  use Moose;

  with 'Business::OnlinePayment::CyberSource::Role::InputHandling';

  sub blah {
  	my ( $self, @args ) = @_;
		my $data = $self->_parse_input( @args );

  	$data->{color} = 'red' unless $data->{color};
  }
	 1;

  my $thing = Thing->new();

  $thing->blah( color => 'blue' );
  $thing->blah( { color => 'blue' } );

=head1 DESCRIPTION

This role provides consumers with convenience methods for handling input.

=method _parse_input

Converts input into a hashref

Accepts:  A hash or reference to a hash
Returns:  A reference to the supplied hash

=cut
