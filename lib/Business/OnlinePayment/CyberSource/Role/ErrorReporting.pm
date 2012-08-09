package Business::OnlinePayment::CyberSource::Role::ErrorReporting;

use 5.010;
use strict;
use warnings;
use utf8::all;

use Moose::Role;
use MooseX::Types::Moose qw(ArrayRef HashRef);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT:  Error reporting role for BOP::CyberSource
# VERSION

#### Subroutine Definitions ####

sub has_errors    {
	my ( $self ) = @_;
	my $result   = 0;

	$result      = 1 if ( scalar @{ $self->errors() } > 0 );

	return $result;
}

sub error_message {
	my ( $self ) = @_;
	my $message  = join "------\n", @{ $self->errors() };

	return $message;
}

#### Object Attributes ####

has errors          => (
	isa       => ArrayRef,
	is        => 'ro',
	default   => sub { [] },
	required  => 0,
	init_arg  => undef,
	lazy      => 1,
);

has response_status => (
	isa       => NonEmptySimpleStr,
	is        => 'rw',
	required  => 0,
	predicate => 'has_response_status',
	reader    => 'failure_status',
	init_arg  => undef,
	lazy      => 0,
);

has status_map      => (
	isa       => HashRef,
	is        => 'ro',
	default   => sub {
		my ( undef ) = @_;
		my $statuses = [ qw(expired nsf stolen pickup blacklisted declined) ];
		my $map      = { map { $_ => 1 } @$statuses };

		return $map;
	},
	required  => 0,
	init_arg  => undef,
	lazy      => 1,
);

1;

=pod

=head1 SYNOPSIS

  package Thing {

  use Moose;

  with 'Business::OnlinePayment::CyberSource::Role::ErrorReporting';
  }

  my $thing = Thing->new();

  if ( $thing->has_errors() ) {
	  my $errors = $thing->errors();
	}

=head1 DESCRIPTION

This role provides consumers with an errors array attribute and supporting methods.

=method has_errors

=method has_response_status

=method error_message

=cut
