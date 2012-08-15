package Business::OnlinePayment::CyberSource::Role::Configuration;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use Config::Any;
use File::HomeDir;
use Moose::Role;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(HashRef);

# ABSTRACT:  Configuration role for BOP::CyberSource
# VERSION

#### Subroutine Definitions ####

# Loads module configuration from file
# Accepts:  Nothing
# Returns:  A reference to a hash of configuration data

sub _load_config {
	my ( undef )  = @_;
	my $dir       = File::HomeDir::my_home();
	my $file      = 'cybs';
	my $config    = Config::Any->load_stems( { stems => [ "/etc/$file", "$dir/$file" ], flatten_to_hash => 1, use_ext => 1  } );

	if ( scalar keys $config > 0 ) {
		my ( $key ) = keys $config;

		$config     = $config->{ $key };
	}

	return $config;
}

before load_config => sub {
	warn 'DEPRECATED: do not call load_config directly, it will be removed '
		. 'as a public method in the next version'
		;
};

sub load_config {
	my ( $self ) = @_;

	return $self->_load_config();
}

#### Object Attributes ####

has config => (
	isa       => HashRef,
	is        => 'ro',
	builder   => '_load_config',
	required  => 1,
	predicate => 'has_config',
	lazy      => 1,
);

#### Method Modifiers ####

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
