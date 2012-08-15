#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use File::HomeDir;
use Test::More;

BEGIN {
	my $dir         = File::HomeDir::my_home();
	my $file        = 'cybs.ini';

	plan skip_all => "You must have the configuration file: $file"
		. " in either /etc or $dir to run this test"
		unless -f "/etc/$file" || -f "$dir/$file";
}

my $class         = 'Business::OnlinePayment';
my $engine        = 'CyberSource';

use_ok "${class}::$engine";

my $tx = new_ok $class, [ $engine ];

my $data = {
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
};

$tx->content( $data );
$tx->test_transaction(1);    # test, dont really charge
$tx->submit();

ok( $tx->is_success, 'transaction successful' )
	or diag $tx->error_message;

ok( $tx->security_key, 'check security key exists' )
	or diag $tx->error_message;

done_testing;
