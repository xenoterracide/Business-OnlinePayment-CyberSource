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
	my $content              = $self->content();

	# Default values
	my $data                 = {
		reference_code => $self->_generate_transaction_id()
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
		  when ( /^normal authorization$/xi ) {
			$result = $self->authorize();
		}
		default {
			Exception::Base->throw( "$_ is an invalid action" );
		}
	}

	return $result;
}

# builds the Business::CyberSource client
# Accepts:  Nothing
# Returns:  A reference to a Business::CyberSource::Client object

sub _build_client {
	my ( $self )             = @_;
	my $username             = $self->login();
	my $password             = $self->password();
	my $test                 = $self->test_transaction();

	my $data                 = {
		username               => $username,
		password               => $password,
		production             => ! $test,
	};

	my $client               = Business::CyberSource::Client->new( $data );

	return $client;
}

sub _build_request {
	my ( undef ) = @_;
	my $request  = Business::OnlinePayment::CyberSource::Request->new();

	return $request;
}

#### Object Attributes ####

has _client => (
	isa       => 'Business::OnlinePayment::CyberSource::Client',
	is        => 'bare',
	builder   => '_build_client',
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
