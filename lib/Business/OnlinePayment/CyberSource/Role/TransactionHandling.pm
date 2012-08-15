package Business::OnlinePayment::CyberSource::Role::TransactionHandling;

use 5.010;
use strict;
use warnings;
use utf8::all;
use namespace::autoclean;

use Moose::Role;
use MooseX::StrictConstructor;
use Try::Tiny;
use Business::OnlinePayment::CyberSource::Client;

# ABSTRACT:  Transaction handling role for BOP::CyberSource
# VERSION

#### Subroutine Definitions ####

# Submits the transaction request to CyberSource
# Accepts:  Nothing
# Returns:  Nothing

sub submit             {
	my ( $self )             = @_;
	my $content              = { $self->content() };

	# Default values
	my $data                 = {
		reference_code => $content->{reference_code}
	};

	$content->{currency} ||= 'USD';

	# purchaser information
	$data->{bill_to}         = {
		ip                     => $content->{customer_ip},
		first_name             => $content->{first_name},
		last_name              => $content->{last_name},
		email                  => $content->{email},
		phone_number           => $content->{phone},
		street1                => $content->{address},
		city                   => $content->{city},
		state                  => $content->{state},
		postal_code            => $content->{zip},
		country                => $content->{country},
	};

	# Purchase totals information
	$data->{purchase_totals} = {
		total                  => $content->{amount},
		currency               => $content->{currency},
	};

	$self->transaction_type( $content->{type} );

	given ( $content->{type} ) {
		  when ( /^CC$/x ) {
			#Credit Card information
			$content->{expiration}     = ''
				unless $content->{expiration} && $content->{expiration} =~ /^\d{4}-\d{2}-\d{2}\b/x;

			my ( $year, $month, $day ) = split /-/x, $content->{expiration};

			$data->{card}            = {
				account_number         => $content->{card_number},
				expiration             => { year => $year, month => $month },
				security_code          => $content->{cvv2},
			};
		}
		default {
			Exception::Base->throw("$_ is an invalid payment type");
		}
	}

	my $result                   = 0;

	given ( $content->{action} ) {
		  when ( /^normal\sauthorization$/ix ) {
			$result = $self->authorize( $data );
		}
		default {
			Exception::Base->throw( "$_ is an invalid action" );
		}
	}

	return $result;
}

#### Object Attributes ####

has _client => (
	isa       => 'Business::OnlinePayment::CyberSource::Client',
	is        => 'bare',
	default   => sub { Business::OnlinePayment::CyberSource::Client->new() },
	required  => 0,
	handles    => qr/^(?:
		is_\w+
		|auth\w+
		|order\w+
		|card\w+
		|fraud\w+
		|\w*response\w*
		|\w+code
		|\w*transaction\w*
		|require\w+
		|server
		|port
		|path
		|username
		|login
		|password
	)$/x,
	init_arg  => undef,
	lazy      => 1,
);

#### Method Modifiers ####

1;

=pod

=head1 SYNOPSIS

  package Thing {

  use Moose;

  with 'Business::OnlinePayment::CyberSource::Role::TransactionHandling';
  }

my $thing = Thing->new();

$thing->submit();

=head1 DESCRIPTION

This role provides consumers with methods for sending transaction requests to CyberSource and handling responses to those requests.

=method submit

=cut
