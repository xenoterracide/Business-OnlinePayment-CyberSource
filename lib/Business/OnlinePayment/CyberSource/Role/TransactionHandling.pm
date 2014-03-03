package Business::OnlinePayment::CyberSource::Role::TransactionHandling;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use DateTime;
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
	my $map = {
		ip => 'customer_ip',
		first_name => 'first_name',
		last_name => 'last_name',
		email => 'email',
		phone_number => 'phone',
		street1 => 'address',
		city => 'city',
		state => 'state',
		postal_code => 'zip',
		country => 'country',
	};

	foreach my $name ( keys %$map ) {
		if (
			$content->{ $map->{$name} }
			&& $content->{action} !~ /^Post\ Authorization|Void$/ix
		) {
			$data->{bill_to}->{$name} = $content->{ $map->{$name} }
				unless ( $content->{po_number} && $content->{action} =~ /^Credit$/ix );
		}
	}

	# Purchase totals information
	$data->{purchase_totals} = {
		total                  => $content->{amount},
		currency               => $content->{currency},
	};

	$data->{service} = { request_id => $content->{po_number} }
		if $content->{po_number};

	$data->{reference_code} =  $content->{invoice_number}
		if $content->{invoice_number}
		;

	# Other fields
	$data->{comments} = $content->{description} if $content->{description};

	$self->transaction_type( $content->{type} );

	if ( $content->{action} =~ qr/^authorization\ only|normal\ authorization|credit$/ix ) {
		given ( $content->{type} ) {
			  when ( /^CC$/x ) {
				#Credit Card information
				my $expiration = $self->_expiration_to_datetime( $content->{expiration} );

				$data->{card}->{account_number} = $content->{card_number};

				$data->{card}->{expiration}     = $expiration if $expiration;
				$data->{card}->{security_code}  = $content->{cvv2} if $content->{cvv2};
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
			$result = $self->capture( $data );
		}
		when ( /^void$/ix ) {
			$result = $self->auth_reversal( $data );
		}
		when ( /^credit$/ix ) {
			$result = $self->credit( $data );
		}
		default {
			Exception::Base->throw( "$_ is an invalid action" );
		}
	}

	return $result;
}

# Converts an expiration date string to a DateTime object
# Accepts:  An expiration date expressed as YYYY-MM-DD, MM/YY, or MMYY
# Returns:  A DateTime object on success and undef otherwise

sub _expiration_to_datetime {
	my ( undef, $date ) = @_;
	my $year            = 0;
	my $month           = 0;

	return unless defined $date;

	$date               = '' unless $date;

	if ( $date ) {
  if ( $date =~ /^\d{2}\/\d{2,4}$/x ) {
						( $month, $year )       = split '/', $date;
					}

					if ( $date =~ /^\d{4}$/x ) {
						$month                  = substr $date, 0, 2;
						$year                   = substr $date, 2, 2;
					}

					if ( $date =~ /^\d{4}-\d{2}-\d{2}\b/x ) {
						( $year, $month ) = split '-', $date;
					}
				}

	$year               = 0 if ( $year < 0 );
	$year              += 2000 if ( $year < 100 && $year >= 0 );

	my $expiration = DateTime->last_day_of_month( year => $year, month => $month );

	return $expiration;
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
		|invoice_number
		|credit
	)$/x,
	init_arg  => undef,
	lazy      => 1,
);

#### Method Modifiers ####

1;

=pod

=head1 SYNOPSIS

  package Thing;

  use Moose;

  with 'Business::OnlinePayment::CyberSource::Role::TransactionHandling';
  1;

my $thing = Thing->new();

$thing->submit();

=head1 DESCRIPTION

This role provides consumers with methods for sending transaction requests to CyberSource and handling responses to those requests.

=method submit

=cut
