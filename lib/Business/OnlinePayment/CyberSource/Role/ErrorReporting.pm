package Business::OnlinePayment::CyberSource::Role::ErrorReporting;

use 5.010;
use strict;
use warnings;
use utf8::all;
use namespace::autoclean;

use Moose::Role;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT:  Error reporting role for BOP::CyberSource
# VERSION

#### Subroutine Definitions ####

#### Object Attributes ####

has error          => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_errors',
	clearer   => 'clear_error',
	reader    => 'error_message',
	writer    => 'set_error_message',
	init_arg  => undef,
	lazy      => 0,
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
