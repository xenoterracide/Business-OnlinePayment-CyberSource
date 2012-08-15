package Business::OnlinePayment::CyberSource::Client;

use 5.010;
use strict;
use warnings;
use utf8::all;

use Moose;
use Data::Dump 'dump';
use MooseX::Aliases;
use Try::Tiny;
use Business::CyberSource::Client;
use MooseX::Types::CyberSource qw(AVSResult);
use MooseX::Types::Moose qw(Bool HashRef Int Str);
use Business::CyberSource::Request::Authorization;
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT:  CyberSource Client object  for Business::OnlinePayment::CyberSource
# VERSION

#### Subroutine Definitions ####

# Sends an authorization request to CyberSource
# Accepts:  A hash or reference to a hash of request parameters
# Returns:  1 if the transaction was successful and 0 otherwise

sub authorize          {
	my ( $self, @args ) = @_;
	my $data            = $self->_parse_input( @args );
	my $success         = 0;

	# Validate input
	my $message         = '';

	$message            = 'No request data specified to authorize'
		unless scalar keys $data > 0;

	$message            = 'purchase_totals data must be specified to authorize as a hashref'
		unless $data->{purchase_totals} && ref $data->{purchase_totals} eq 'HASH';

	$message            = 'No payment medium specified to authorize'
		unless $data->{card};

	Exception::Base->throw( $message ) if $message;

	my $request         = try {
		Business::CyberSource::Request::Authorization->new( $data );
	}
	catch {
		my $message = shift;

		$self->set_error_message( $message );

		return $success;
	};

	say "Ref: " . ref $request;

	try {
		my $response        = $self->run_transaction( $request );

		if ( $response->is_success() ) {
			my $res           = $response->trace->response();

			$success          = 1;

			$self->is_success( $success );
			$self->avs_code( $response->avs_code() );
			$self->authorization( $response->auth_record() );
			$self->order_number( $response->request_id() );
			$self->response_code( $res->code() );
			$self->response_page( $res->content() );
			$self->response_headers( { map { $_ => $res->headers->header( $_ ) } $res->headers->header_field_names() } );

			$self->cvv2_code( $response->cv_code() ) if $response->has_cv_code();
		}
		else {
			$self->set_error_message( $response->reason_text() );

			say "Error: " . $response->reason_text();
		}
	}
	catch {
		$self->set_error_message( $_ );

		say "Error: $_";
	};

	return $success;
}

# Sends a capture request to CyberSource
# Accepts:  A hash or reference to a hash of request parameters
# Returns:  1 if the transaction was successful and 0 otherwise

sub capture            {
	my ( $self, @args ) = @_;
	my $data            = $self->_parse_input( @args );
	my $success         = 0;

	my $request         = Business::CyberSource::Request::Capture->new( $data );
	my $response        = $self->run_transaction( $data );

	if ( 0 ) {
		;
	}

	return $success;
}

# Sends a credit request to CyberSource
# Accepts:  A hash or reference to a hash of request parameters
# Returns:  1 if the transaction was successful and 0 otherwise

sub credit             {
	my ( $self, @args ) = @_;
	my $data            = $self->_parse_input( @args );
	my $success         = 0;

	my $request         = Business::CyberSource::Request::Credit->new( $data );
	my $response        = $self->run_transaction( $data );

	if ( 0 ) {
		;
	}

	return $success;
}

# Resets all transaction fields
# Accepts:  Nothing
# Returns:  Nothing

sub _clear_fields      {
	my ( $self ) = @_;

	my $attributes = [ qw(
		success authorization order_number card_token fraud_score fraud_transaction_id
		response_code response_headers response_page result_code avs_code
		cvv2_response
	) ];

	$self->$_() foreach ( map { "clear_$_" } @$attributes );

	return;
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

#### Object Attributes ####

has is_success => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	clearer   => 'clear_success',
	init_arg  => undef,
	lazy      => 1,
);

# Authorization code
has authorization => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_authorization',
	clearer   => 'clear_authorization',
	init_arg  => undef,
	lazy      => 0,
);

# Number identifying the specific request
has order_number => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_order_number',
	clearer   => 'clear_order_number',
	init_arg  => undef,
	lazy      => 0,
);

# Used in stead of card number (not yet supported)
has card_token => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_card_token',
	clearer   => 'clear_card_token',
	init_arg  => undef,
	lazy      => 0,
);

# score assigned by ... (not yet supported)
has fraud_score => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_fraud_score',
	clearer   => 'clear_fraud_score',
	init_arg  => undef,
	lazy      => 0,
);

# Transaction id assigned by ... (not yet supported)
has fraud_transaction_id => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_fraud_transaction_id',
	clearer   => 'clear_fraud_transaction_id',
	init_arg  => undef,
	lazy      => 0,
);

# HTTP response code
has response_code => (
	isa       => Int,
	is        => 'rw',
	required  => 0,
	predicate => 'has_response_code',
	clearer   => 'clear_response_code',
	init_arg  => undef,
	lazy      => 0,
);

# HTTP response headers
has response_headers => (
	isa       => HashRef,
	is        => 'rw',
	required  => 0,
	predicate => 'has_response_headers',
	clearer   => 'clear_response_headers',
	init_arg  => undef,
	lazy      => 0,
);

# HTTP response content
has response_page => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_response_page',
	clearer   => 'clear_response_page',
	init_arg  => undef,
	lazy      => 0,
);

# ...
has result_code => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_result_code',
	clearer   => 'clear_result_code',
	init_arg  => undef,
	lazy      => 0,
);

# address verification response code
has avs_code => (
	isa       => AVSResult,
	is        => 'rw',
	required  => 0,
	predicate => 'has_avs_code',
	clearer   => 'clear_avs_code',
	init_arg  => undef,
	lazy      => 0,
);

# CVV2 response value
has cvv2_response => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_cvv2_response',
	clearer   => 'clear_cvv2_response',
	init_arg  => undef,
	lazy      => 0,
);

# Type of payment
has transaction_type => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_transaction_type',
	clearer   => 'clear_transaction_type',
	init_arg  => undef,
	lazy      => 0,
);

# Business::CyberSource client object
has _client => (
	isa       => 'Business::CyberSource::Client',
	is        => 'bare',
	builder   => '_build_client',
	required  => 0,
	predicate => 'has_client',
	init_arg  => undef,
	handles   => qr/^(?:run_transaction)$/x,
	lazy      => 1,
);

# Account username
has username => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	required  => 0,
	predicate => 'has_login',
	alias     => 'login',
	lazy      => 0,
);

# Account API key
has password => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_password',
	lazy      => 0,
);

# Is this a test transaction?
has test_transaction => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	predicate => 'has_test_transaction',
	trigger   => sub {
		my ( $self, $value ) = @_;

		$self->clear_server() if $value;

		return;
	},
	lazy      => 1,
);

# Require address verification
has require_avs => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	predicate => 'has_require_avs',
	lazy      => 1,
);

# Remote server
has server => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	default   => sub {
		my ( $self ) = @_;

		return ( $self->test_transaction() ) ? 'ics2wstest.ic3.com' : 'ics2ws.ic3.com';
	},
	required  => 0,
	predicate => 'has_server',
	clearer   => 'clear_server',
	lazy      => 1,
);

# Port for remote service
has port => (
	isa       => Int,
	is        => 'rw',
	default   => 443,
	required  => 0,
	predicate => 'has_port',
	lazy      => 1,
);

# Path to remote service
has path => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	default   => 'commerce/1.x/transactionProcessor',
	required  => 0,
	predicate => 'has_path',
	lazy      => 1,
);

# Murchant generated code to identify transaction
has reference_code => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_reference_code',
	clearer   => 'clear_reference_code',
	init_arg  => undef,
	lazy      => 0,
);

#### Method Modifiers ####

before qr/^(?:authorize|capture|credit)$/x, sub {
	my ( $self ) = @_;

	$self->_clear_fields();

	return;
};

around qr/^(?:server|port|path)$/x, sub {
	my ( $orig, $self, @args ) = @_;

	Exception::Base->throw( 'Setting server, port, and or path information is not supported by this module' ) if ( scalar @args > 0 );

	return $self->$orig( @args );
};

#### Consumed Roles ####

with
	'Business::OnlinePayment::CyberSource::Role::InputHandling',
	'Business::OnlinePayment::CyberSource::Role::ErrorReporting';

#### Meta class stuff ####

__PACKAGE__->meta->make_immutable();

1;

=pod

=head1 SYNOPSIS

  use Business::OnlinePayment::CyberSource::Request;

  my $request = Business::OnlinePayment::CyberSource::Request->new( $data );

  $request->submit();

  if ( $request->is_success() ) {
  	print "";
  }
  else {
  }

=head1 DESCRIPTION

Business::OnlinePayment::CyberSource::Request represents a transaction request to CyberSource and provides convenience methods for encoding and decoding messages.

=cut
