#!/usr/bin/perl
use strict;
use warnings;
use Env qw( CYBS_CONF );
use Test::More;

#testing/testing is valid and seems to work...

plan skip_all => 'You MUST set ENV variable CYBS_CONF to test this!'
		unless -e $CYBS_CONF;

use Business::OnlinePayment;

my $tx
	= Business::OnlinePayment->new(
		'CyberSource',
		conf_file => $CYBS_CONF,
	);

$tx->content(
	type           => 'VISA',
	action         => 'Normal Authorization',
	description    => 'Business::OnlinePayment visa test',
	amount         => '49.95',
	invoice_number => '100100',
	first_name     => 'Tofu',
	last_name      => 'Beast',
	address        => '123 Anystreet',
	city           => 'Anywhere',
	state          => 'UT',
	zip            => '84058',
	country        => 'US',
	email          => 'tofu@beast.org',
	card_number    => '4111111111111111',
	expiration     => '12/25',
);
$tx->test_transaction(1);    # test, dont really charge
$tx->submit();

ok( $tx->is_success, 'transaction successful' )
	or diag $tx->error_message;

ok( $tx->security_key, 'check security key exists' )
	or diag $tx->error_message;
done_testing;
