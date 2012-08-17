package Business::OnlinePayment::CyberSource;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use Moose;
use Data::Dump 'dump';
use Exception::Base;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool HashRef Int);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT:  CyberSource backend for Business::OnlinePayment
# VERSION

extends 'Business::OnlinePayment';

#### Subroutine Definitions ####

# Post-construction hook
# Accepts:  A reference to a hash of construction parameters
# Returns:  Nothing

sub BUILD {
	my ( $self ) = @_;
	my $fields   = [ qw(type action reference_code amount) ];

	$self->required_fields( @$fields );

	return;
}

#### Object Attributes ####

#### Applied Roles ####

with 'Business::OnlinePayment::CyberSource::Role::TransactionHandling';

#### Method Modifiers ####

#### Meta class stuff ####

__PACKAGE__->meta->make_immutable();

1;

=pod

=head1 SYNOPSIS

	use Business::OnlinePayment;

	my $tx = Business::OnlinePayment->new( "CyberSource" );
	$tx->content(
		login          => 'username',
		password       => 'password',
		type           => 'CC',
		action         => 'Normal Authorization',
		invoice_number => '00000001',
		first_name     => 'Peter',
		last_name      => 'Bowen',
		address        => '123 Anystreet',
		city           => 'Orem',
		state          => 'Utah',
		zip            => '84097',
		country        => 'US',
		email          => 'foo@bar.net',
		card_number    => '4111111111111111',
		expiration     => '09/06',
		cvv2           => '1234', #optional
		amount         => '5.00',
		currency       => 'USD',
	);

	$tx->submit();

	if($tx->is_success()) {
		print "Card processed successfully: ".$tx->authorization."\n";
	} else {
		print "Card was rejected: ".$tx->error_message."\n";
	}

	####
	# Two step transaction, authorization and capture.
	# If you don't need to review order before capture, you can
	# process in one step as above.
	####

  $tx = Business::OnlinePayment->new("CyberSource");
	$tx->content(
		login          => 'username',
		password       => 'password',
		type           => 'CC',
		action         => 'Authorization Only',
		invoice_number  => 44544,
		description     => 'Business::OnlinePayment visa test',
		amount          => '42.39',
		first_name      => 'Tofu',
		last_name       => 'Beast',
		address         => '123 Anystreet',
		city            => 'Anywhere',
		state           => 'Utah',
		zip             => '84058',
		country         => 'US',
		email           => 'tofu@beast.org',
		card_number     => '4111111111111111',
		expiration      => '12/25',
		cvv2            => 1111,
	);
	$tx->submit();

	if($tx->is_success()) {
		# get information about authorization
		my $authorization = $tx->authorization();
		my $order_number = $tx->order_number();
		my $avs_code = $tx->avs_code(); # AVS Response Code();
		my $cvv2_response = $tx->cvv2_response(); # CVV2/CVC2/CID Response Code();

		# now capture transaction

		$tx->content(
			login          => 'username',
			password       => 'password',
			type           => 'CC',
			action         => 'Post Authorization',
			invoice_number => 44544,
			amount         => '42.39',
			po_number       => $tx->order_number(),
		);

		$tx->submit();

		if($tx->is_success()) {
			print "Card captured successfully: ".$tx->authorization."\n";
		} else {
			print "Card was rejected: ".$tx->error_message."\n";
		}

	} else {
		print "Card was rejected: " . $tx->error_message() . "\n";
	}

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC

Content required: type, login, action, amount, first_name, last_name, card_number, expiration.

=head2 Settling

To settle an authorization-only transaction (where you set action to
C<Authorization Only>), submit the C<order_number> code in the field
C<po_number> with the action set to C<Post Authorization>.

You can get the transaction id from the authorization by calling the
C<order_number> method on the object returned from the authorization.
You must also submit the amount field with a value less than or equal
to the amount specified in the original authorization.

=method BUILD

this is a before-construction hook for Moose.  You Will never call this method directly.

=head1 ACKNOWLEDGMENTS

=over 4

=item Jason Kohles

For writing BOP - I didn't have to create my own framework.

=item Ivan Kohler

Tested the first pre-release version and fixed a number of bugs.
He also encouraged me to add better error reporting for system
errors.  He also added failure_status support.

=item Jason (Jayce^) Hall

Adding Request Token Requirements (Among other significant improvements... )

=back

=head1 SEE ALSO

L<Business::OnlinePayment>

=cut
