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
		$self->error_message( $_ );

		return $success;
	};

	my $response        = $self->run_transaction( $request );

	if ( $response->is_success() ) {
		my $res           = $response->trace->response();

		$success          = 1;

		$self->is_success( $success );
		$self->avs_code( $response->avs_code() );
		$self->response_code( $res->code() );
		$self->response_page( $res->content() );
		$self->response_headers( { map { $_ => $res->headers->header( $_ ) } $res->headers->header_field_names() } );

		$self->cvv2_code( $response->cv_code() ) if $response->has_cv_code();
}

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
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_success',
	init_arg  => undef,
	lazy      => 1,
);

has authorization => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_authorization',
	init_arg  => undef,
	lazy      => 1,
);

has order_number => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_order_number',
	init_arg  => undef,
	lazy      => 1,
);

has card_token => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_card_token',
	init_arg  => undef,
	lazy      => 1,
);

has fraud_score => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_fraud_score',
	init_arg  => undef,
	lazy      => 1,
);

has fraud_transaction_id => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_fraud_transaction_id',
	init_arg  => undef,
	lazy      => 1,
);

has response_code => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_response_code',
	init_arg  => undef,
	lazy      => 1,
);

has response_headers => (
	isa       => HashRef,
	is        => 'rw',
	default   => sub { {} },
	required  => 0,
	clearer   => 'clear_response_headers',
	init_arg  => undef,
	lazy      => 1,
);

has response_page => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_response_page',
	init_arg  => undef,
	lazy      => 1,
);

has result_code => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_result_code',
	init_arg  => undef,
	lazy      => 1,
);

has avs_code => (
	isa       => AVSResult,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_avs_code',
	init_arg  => undef,
	lazy      => 1,
);

has cvv2_response => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_cvv2_response',
	init_arg  => undef,
	lazy      => 1,
);

has transaction_type => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	clearer   => 'clear_transaction_type',
	init_arg  => undef,
	lazy      => 1,
);

has _client => (
	isa       => 'Business::CyberSource::Client',
	is        => 'bare',
	builder   => '_build_client',
	required  => 0,
	init_arg  => undef,
	handles   => qr/^(?:run_transaction)$/x,
	lazy      => 1,
);

# Account username
has username => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	required  => 0,
	alias     => 'login',
	lazy      => 0,
);

# Account API key
has password => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	lazy      => 0,
);

# Is this a test transaction?
has test_transaction => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	lazy      => 1,
);

# Require address verification
has require_avs => (
	isa       => Bool,
	is        => 'rw',
	default   => 0,
	required  => 0,
	lazy      => 1,
);

# Remote server
has server => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	builder   => '_build_server',
	required  => 0,
	lazy      => 1,
);

# Port for remote service
has port => (
	isa       => Int,
	is        => 'rw',
	builder   => '_build_port',
	required  => 0,
	lazy      => 1,
);

# Path to remote service
has path => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	builder   => '_build_path',
	required  => 0,
	lazy      => 1,
);

has reference_code => (
	isa       => Str,
	is        => 'rw',
	default   => '',
	required  => 0,
	lazy      => 1,
);

#### Method Modifiers ####

before qr/^(?:authorize|capture|credit)$/x, sub {
	my ( $self ) = @_;

	$self->_clear_fields();

	return;
};

#### Consumed Roles ####

with
	'Business::OnlinePayment::CyberSource::Role::InputHandling',
	'Business::OnlinePayment::CyberSource::Role::ErrorReporting';

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
