#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#testing/testing is valid and seems to work...

use Business::OnlinePayment;

plan skip_all => 'You must have the default configuration file: '
	.'/etc/cybs.ini configured'
	unless -e '/etc/cybs.ini';

my $tx = Business::OnlinePayment->new('CyberSource');
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
