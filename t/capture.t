#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
#testing/testing is valid and seems to work... (but not for auth + capture)
use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("CyberSource");
$tx->content(
	type           => 'VISA',
	action         => 'Authorization Only',
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
	email          => 'tofu@beast.com',
	card_number    => '4007000000027',
	expiration     => '08/06',
);
$tx->test_transaction(1);    # test, dont really charge
$tx->submit();

ok ( $tx->is_success, 'transaction is success' );

note( $tx->order_number );

my $settle_tx = Business::OnlinePayment("CyberSource")->new;

$settle_tx->content(
	type           => 'VISA',
	action         => 'Post Authorization',
	description    => 'Business::OnlinePayment visa test',
	amount         => '49.95',
	invoice_number => '100100',
	order_number   => $tx->order_number,
);

$settle_tx->test_transaction(1);    # test, dont really charge
$settle_tx->submit();

ok( $settle_tx->is_success, 'settle is success' )
	or diag ( $tx->error_message );
done_testing;
