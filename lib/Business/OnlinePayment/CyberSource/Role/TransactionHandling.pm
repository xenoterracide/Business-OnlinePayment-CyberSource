package Business::OnlinePayment::CyberSource::Role::TransactionHandling;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use Data::Dump 'dump';
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
		reference_code => $content->{invoice_number}
	};

	$content->{currency} ||= 'USD';

	# purchaser information
	$data->{bill_to}->{ip} = $content->{customer_ip} if $content->{customer_ip};
	$data->{bill_to}->{first_name} = $content->{first_name} if $content->{first_name};
	$data->{bill_to}->{last_name} = $content->{last_name} if $content->{last_name};
	$data->{bill_to}->{email} = $content->{email} if $content->{email};
	$data->{bill_to}->{phone_number} = $content->{phone} if $content->{phone};
	$data->{bill_to}->{street1} = $content->{address} if $content->{address};
	$data->{bill_to}->{city} = $content->{city} if $content->{city};
	$data->{bill_to}->{state} = $content->{state} if $content->{state};
	$data->{bill_to}->{postal_code} = $content->{zip} if $content->{zip};
	$data->{bill_to}->{country} = $content->{country} if $content->{country};

	# Purchase totals information
	$data->{purchase_totals} = {
		total                  => $content->{amount},
		currency               => $content->{currency},
	};

	# Other fields
	$data->{comments} = $content->{description} if $content->{description};

	$self->transaction_type( $content->{type} );

	if ( $content->{action} =~ qr/^authorization\ only|normal\ authorization$/ix ) {
		given ( $content->{type} ) {
			  when ( /^CC$/x ) {
				#Credit Card information
				my $year                 = 0;
				my $month                = 0;
				my $day                  = 0;

				$content->{expiration}     = ''
					unless $content->{expiration};

				if ( $content->{expiration} =~ /^\d{4}-\d{2}-\d{2}\b/x ) {
					( $year, $month, $day ) = split '-', $content->{expiration};
				}
				elsif ( $content->{expiration} =~ /^\d{2}\/\d{2,4}$/x ) {
					( $month, $year )       = split '/', $content->{expiration};
				}

				$year += 2000 if ( $year < 100 && $year > 0 );

				$data->{card}->{account_number} = $content->{card_number};

				$data->{card}->{expiration} = { year => $year, month => $month }
					if ( $month && $year );

				$data->{card}->{security_code} = $content->{cvv2} if $content->{cvv2};
			}
			default {
				Exception::Base->throw("$_ is an invalid payment type");
			}
		}
	}

	$self->username( $content->{login} );
	$self->password( $content->{password} );

	my $result                   = 0;

	given ( $content->{action} ) {
		when ( /^authorization\ only$/ix ) {
			$result = $self->authorize( $data );
		}
		when ( /^normal\ authorization$/ix ) {
			$result = $self->sale( $data );
		}
		when ( /^post\ authorization$/ix ) {
			$data->{service} = { request_id => $content->{request_id} };

			$result = $self->capture( $data );
		}
		default {
			Exception::Base->throw( "$_ is an invalid action" );
		}
	}

	return $result;
}

#### Object Attributes ####
## no critic ( RegularExpressions::ProhibitComplexRegexes )
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
		|sale
		|port
		|path
		|username
		|login
		|password
		| error_message
		| failure_status
		| capture
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
