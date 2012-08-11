package Business::OnlinePayment::CyberSource::Role::TransactionHandling;

use 5.010;
use strict;
use warnings;
use utf8::all;
use namespace::autoclean;

use Moose::Role;
use MooseX::StrictConstructor;
use Try::Tiny;

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

	$content->{currency}     = 'USD' unless $content->{currency};

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
			Exception::Base->throw("$_ is an invalid action type");
		}
	}

	my $request              = $self->_build_request( $data );
	my $response             = $self->client->run_transaction( $request );

=ignore
	$self->{config} ||= $self->_load_config;
	my $content = $self->{'_content'};

	my $reply   = {};
	my $request = {};

	my $error_handler = Business::OnlinePayment::CyberSource::Error->new;

	# If it's available but not set, grab the merchant_id from the conf
	if ( !defined( $content->{'login'} )
		|| $content->{'login'} eq '' )
	{
		$content->{'login'} = $self->{config}->{'merchantID'};
	}

	$self->required_fields(qw(action login invoice_number));
	$self->map_fields(
		login          => 'merchantID',
		invoice_number => 'merchantReferenceCode',
	);

	$content->{'application'} ||= 'Business::OnlinePayment::CyberSource';
	$content->{'version'} ||= $Business::OnlinePayment::VERSION;
	$self->map_fields(
		application => 'clientApplication',
		version     => 'clientApplicationVersion',
		user        => 'clientApplicationUser',
	);

	### Handle The Actions
	# Reset them all
	foreach my $action (@action_list) {
		$content->{$action} = 'false';
	}

	# Set them correctly
	foreach my $action ( @{ $actions{ lc( $content->{'action'} ) } } ) {
		$content->{$action} = 'true';
	}

	# Allow for Advanced Fraud Check
	if ( defined( $content->{'fraud_check'} )
		&& lc( $content->{'fraud_check'} ) eq 'true' )
	{
		$content->{'afsService_run'} = 'true';
	}

	my %request_base = $self->get_fields(
		@action_list, qw( afsService_run
			merchantID merchantReferenceCode
			clientApplication clientApplicationVersion clientApplicationUser
			)
	);

	$self->request_merge( $request, \%request_base );

	$self->map_fields(
		company             => 'billTo_company',
		first_name          => 'billTo_firstName',
		last_name           => 'billTo_lastName',
		address             => 'billTo_street1',
		address2            => 'billTo_street2',
		city                => 'billTo_city',
		state               => 'billTo_state',
		zip                 => 'billTo_postalCode',
		country             => 'billTo_country',
		ssn                 => 'billTo_ssn',
		phone               => 'billTo_phoneNumber',
		email               => 'billTo_email',
		card_number         => 'card_accountNumber',
		cvv2_status         => 'card_cvIndicator',
		cvv2                => 'card_cvNumber',
		ship_last_name      => 'shipTo_lastName',
		ship_first_name     => 'shipTo_firstName',
		ship_address        => 'shipTo_street1',
		ship_address2       => 'shipTo_street2',
		ship_city           => 'shipTo_city',
		ship_state          => 'shipTo_state',
		ship_zip            => 'shipTo_postalCode',
		ship_country        => 'shiptTo_country',
		ship_email          => 'shipTo_email',
		ship_phone          => 'shipTo_phoneNumber',
		customer_hostname   => 'billTo_hostname',
		customer_browser    => 'billTo_httpBrowserType',
		customer_ip         => 'billTo_ipAddress',
		avs_level           => 'ccAuthService_avsLevel',
		cavv                => 'ccAuthService_cavv',
		xid                 => 'ccAuthService_xid',
		eci_raw             => 'ccAouthService_eciRaw',
		avs_decline_flags   => 'businessRules_declineAVSFlags',
		avs_ignore_result   => 'businessRules_ignoreAVSResult',
		capture_anyway      => 'businessRules_ignoreCVResult',
		merchant_descriptor => 'invoiceHeader_merchantDescriptor',
		AMEX_Data1          => 'invoiceHeader_amexDataTAA1',
		AMEX_Data2          => 'invoiceHeader_amexDataTAA2',
		AMEX_Data3          => 'invoiceHeader_amexDataTAA3',
		AMEX_Data4          => 'invoiceHeader_amexDataTAA4',
		fraud_threshold     => 'businessRules_scoreThreshold',
		order_number        => 'request_id',
		security_key        => 'request_token',
	);

	my %request = $self->get_fields(
		qw( purchaseTotals_currency
			billTo_company billTo_firstName billTo_lastName billTo_street1
			billTo_street2 billTo_city billTo_state billTo_postalCode billTo_country
			billTo_ssn billTo_phoneNumber billTo_email card_accountNumber
			card_cvIndicator card_cvNumber shipTo_lastName shipTo_firstName
			shipTo_street1 shipTo_street2 shipTo_city shipTo_state shipTo_postalCode
			shiptTo_country shipTo_email shipTo_phoneNumber billTo_hostname
			billTo_httpBrowserType billTo_ipAddress ccAuthService_avsLevel
			merchant_descriptor AMEX_Data1 AMEX_Data2 AMEX_Data3 AMEX_Data4
			businessRules_scoreThreshold
			)
	);

	$self->request_merge( $request, \%request );

	#Split up the expiration
	if ( defined( $content->{'expiration'} ) ) {

		# This works for MM/YYYY, MM/YY, MMYYYY, and MMYY
		$content->{'expiration'} =~ /^(\d+)\D*\d*(\d{2})$/xms
			or croak "unparsable expiration " . $content->{expiration};
		$request->{'card_expirationMonth'} = $1;
		$request->{'card_expirationYear'}  = $2;
	}

	$self->_set_item_list( $content, $request );

	# SSN
	if ( defined( $content->{'ssn'} )
		&& $content->{'ssn'} ne '' )
	{
		$content->{'ssn'} =~ s/-//gxms;
	}

	$content->{'card_cardType'} = $card_types{ lc( $self->transaction_type ) };

	# Check and convert the data for an Authorization
	if ( lc( $content->{'ccAuthService_run'} ) eq 'true' ) {

		$self->required_fields(
			qw(first_name last_name city country email address card_number expiration invoice_number type)
		);

	}

	if ( lc( $content->{'ccAuthReversalService_run'} ) eq 'true' ) {
		$self->required_fields(qw(request_id));
		$request->{'ccAuthReversalService_authRequestID'} =
			$content->{'request_id'};
	}
	if ( lc( $content->{'ccCaptureService_run'} ) eq 'true' ) {

		if ( lc( $content->{'ccAuthService_run'} ) ne 'true' ) {
			$self->required_fields(qw(order_number));
			$request->{'ccCaptureService_authRequestID'} =
				$content->{'request_id'};
			$self->required_fields(qw(security_key));
			$request->{ $request_token{'ccCaptureService_run'} } =
				$content->{'security_key'};
			if ( defined( $content->{'auth_code'} ) ) {
				$request->{'ccCaptureService_authverbalAuthCode'} =
					$content->{'auth_code'};
				$request->{'ccCaptureService_authType'} = 'verbal';
			}
		}

	}
	if ( lc( $content->{'ccCreditService_run'} ) eq 'true' ) {
		if ( defined( $content->{'request_id'} )
			&& $content->{'request_id'} ne '' )
		{
			$self->required_fields(qw(request_id));
			$request->{'ccCreditService_captureRequestID'} =
				$content->{'request_id'};
			$self->required_fields(qw(security_key));
			$request->{ $request_token{'ccCreditService_run'} } =
				$content->{'security_key'};
		}
		else {
			$self->required_fields(
				qw(first_name last_name city country email address card_number expiration invoice_number type)
			);
		}
	}
	if ( lc( $request->{'afsService_run'} ) eq 'true' ) {
		if (  !defined( $content->{'items'} )
			|| scalar( $content->{'items'} ) < 1 )
		{
			croak(    'Advanced Fraud Screen requests require that you populate'
					. ' the items hash.' );
		}
	}

# Configuration should always take over!  There's nothing so confusing as having the config show test and
# it still sends to live

	if (
		$self->{config}->{'sendToProduction'}
		&& ( lc( $self->{config}->{'sendToProduction'} ) eq 'true'
			|| $self->{config}->{'sendToProduction'} eq '' )
		)
	{
		$self->{config}->{'sendToProduction'} =
			$self->test_transaction() ? "false" : "true";
	}

#
# Use the configuration values for some of the business logic - However, let the request override these...
#
	if (  !defined( $request->{'businessRules_declineAVSFlags'} )
		&& defined( $self->{config}->{'businessRules_declineAVSFlags'} ) )
	{
		$request->{'businessRules_declineAVSFlags'} =
			$self->{config}->{'businessRules_declineAVSFlags'};
	}
	if (  !defined( $request->{'businessRules_ignoreAVSResult'} )
		&& defined( $self->{config}->{'businessRules_ignoreAVSResult'} ) )
	{
		$request->{'businessRules_ignoreAVSResult'} =
			$self->{config}->{'businessRules_ignoreAVSResult'};
	}
	if (  !defined( $request->{'businessRules_ignoreCVResult'} )
		&& defined( $self->{config}->{'businessRules_ignoreCVResult'} ) )
	{
		$request->{'businessRules_ignoreCVResult'} =
			$self->{config}->{'businessRules_ignoreCVResult'};
	}

#####
###Heres the Magic
#####
	my $cybs_return_code =
		CyberSource::SOAPI::cybs_run_transaction( $self->{config}, $request,
		$reply );

	if ( $cybs_return_code != CyberSource::SOAPI::CYBS_S_OK ) {
		$self->is_success(0);
		if ( $cybs_return_code == CyberSource::SOAPI::CYBS_S_PERL_PARAM_ERROR )
		{
			$self->error_message( 'A parsing error occurred '
					. '- there is a problem with one or more of the parameters.'
			);
		}
		elsif ( $cybs_return_code == CyberSource::SOAPI::CYBS_S_PRE_SEND_ERROR )
		{
			$self->error_message( 'Could not create the request - '
					. 'There is probably an error with your client configuration.'
					. ' More Information: "'
					. $reply->{CyberSource::SOAPI::CYBS_SK_ERROR_INFO} );
		}
		elsif ( $cybs_return_code == CyberSource::SOAPI::CYBS_S_PRE_SEND_ERROR )
		{
			$self->error_message(
				'Something bad happened while sending. More Information: "'
					. $reply->{CyberSource::SOAPI::CYBS_SK_ERROR_INFO}
					. '"' );
		}
		else {
			$self->error_message( 'Something REALLY bad happened. '
					. 'Your transaction may have been processed or it could have '
					. 'blown up. '
					. 'Check the business center to figure it out. '
					. 'Good Luck... More Information: "'
					. $reply->{CyberSource::SOAPI::CYBS_SK_ERROR_INFO}
					. '" Raw Error: "'
					. $reply->{CyberSource::SOAPI::CYBS_SK_RAW_REPLY}
					. '" Probable Request ID: "'
					. $reply->{CyberSource::SOAPI::CYBS_SK_FAULT_REQUEST_ID}
					. '" return code: "'
					. $cybs_return_code
					. '"' );
		}
		return 0;
	}

	# Fields for all queries
	$self->server_response($reply);
	$self->order_number( $reply->{'requestID'} );
	$self->result_code( $reply->{'reasonCode'} );
	$self->security_key( $reply->{'requestToken'} );

	if ( $reply->{'decision'} eq 'ACCEPT' ) {
		$self->is_success(1);
	}
	else {
		$self->is_success(0);
		$self->error_message( $error_handler->get_text( $self->result_code ) );
		$self->failure_status(
			$error_handler->get_failure_status( $self->result_code ) );
	}

	my $ccAuthHash         = {};
	my $ccAuthReversalHash = {};
	my $ccCaptureHash      = {};
	my $ccCreditHash       = {};
	my $afsHash            = {};

	foreach my $key ( keys %{$reply} ) {
		if ( $key =~ /^ccAuthReply_(.*)/xms )
		{    ## no critic ( ControlStructures::ProhibitCascadingIfElse )
			$ccAuthHash->{$key} = $reply->{$key};
		}
		elsif ( $key =~ /^ccAuthReversalReply_(.*)/xms ) {
			$ccAuthReversalHash->{$key} = $reply->{$key};
		}
		elsif ( $key =~ /^ccCaptureReply_(.*)/xms ) {
			$ccCaptureHash->{$key} = $reply->{$key};
		}
		elsif ( $key =~ /^ccCreditReply_(.*)/xms ) {
			$ccCreditHash->{$key} = $reply->{$key};
		}
		elsif ( $key =~ /^afsReply_(.*)/xms ) {
			$afsHash->{$key} = $reply->{$key};
		}
	}

	if ( $request->{'ccAuthService_run'} eq 'true' ) {
		$self->avs_code( $reply->{'ccAuthReply_avsCode'} );
		$self->authorization( $reply->{'ccAuthReply_authorizationCode'} );
		$self->auth_reply($ccAuthHash);

		#    $self->request_id($reply->{'requestID'});
	}
	if ( $request->{'ccAuthReversalService_run'} eq 'true' ) {
		$self->auth_reversal_reply($ccAuthReversalHash);
	}
	if ( $request->{'ccCaptureService_run'} eq 'true' ) {
		$self->capture_reply($ccCaptureHash);
	}
	if ( $request->{'ccCreditService_run'} eq 'true' ) {
		$self->credit_reply($ccCreditHash);
	}
	if ( $request->{'afsService_run'} eq 'true' ) {
		$self->afs_reply($afsHash);
	}
	return $self->is_success;
=cut

	return;
}

# builds the Business::CyberSource client
# Accepts:  Nothing
# Returns:  A reference to a Business::CyberSource::Client object

sub _build_client {
	my ( $self )             = @_;
	my $username             = $self->login();
	my $password             = $self->password();
	my $test                 = $self->test_mode();

	my $data                 = {
		username               => $username,
		password               => $password,
		production             => ! $test,
	};

	my $client               = Business::CyberSource::Client->new( $data );

	return $client;
}

#### Object Attributes ####

has _client => (
	isa       => 'Business::CyberSource::Client',
	is        => 'ro',
	builder   => '_build_client',
	required  => 0,
	init_arg  => undef,
	reader    => 'client',
	lazy      => 1,
);

#### Method Modifiers ####

before client => sub {
	my ( $self ) = @_;

	Exception::Base->throw( 'client is not a publically accessible method' )
		unless ( ref $self eq __PACKAGE__ && ( caller )[0] eq __PACKAGE__ );
};

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
