package Business::OnlinePayment::CyberSource::Role::Configuration;

use 5.010;
use strict;
use warnings;
use utf8::all;

use Moose::Role;
use MooseX::Types::Moose qw(HashRef);

# ABSTRACT:  Configuration role for BOP::CyberSource
# VERSION

#### Subroutine Definitions ####

sub set_defaults {
	my $self = shift;

	return $self->build_subs(
		qw( order_number avs_code  cvv2_response cavv_response
			auth_reply auth_reversal_reply capture_reply
			credit_reply afs_reply failure_status security_key request_token
			)
	);
}

sub _load_config {
	my $self = shift;

	# The default is /etc/
	my $conf_file = ( $self->can('conf_file') && $self->conf_file )
		|| '/etc/cybs.ini';

	my %config = CyberSource::SOAPI::cybs_load_config($conf_file);

	return \%config;
}

before load_config => sub {
	carp 'DEPRECATED: do not call load_config directly, it will be removed '
		. 'as a public method in the next version'
		;
};

sub load_config {
	my $self = shift;
	return $self->_load_config;
}

#### Object Attributes ####

has config => (
	isa       => HashRef,
	is        => 'ro',
	default   => sub { {} },
	required  => 1,
	predicate => 'has_config',
	lazy      => 1,
);

#### Method Modifiers ####

around BUILDARGS => sub {
	my ( $orig, $self, @args ) = @_;
	my $data                   = {};

	if ( scalar @args == 1 && ref $args[0] eq 'HASH' ) {
		$data                    = shift @args;
	}
	elsif ( ( scalar @args % 2 ) == 0 ) {
		$data                    = { @args };
	}

	$data->{config}            = {};

	return $self->$orig( $data );
};

1;

=pod

=head1 SYNOPSIS

  package Thing {

  use Moose;

  with 'Business::OnlinePayment::CyberSource::Role::Configuration';
  }

my $thing = Thing->new( config => { blah => 'hope' } );
  my $blah  = $thing->config->{blah};

=head1 DESCRIPTION

This role provides consumers with a configuration hash attribute.

=cut
