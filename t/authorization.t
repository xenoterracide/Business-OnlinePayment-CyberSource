#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
	my $username = $ENV{BOPC_UN};
	my $password = $ENV{BOPC_PW};

	plan skip_all =>
		'No credentials set in the environment.  Set BOPC_UN and BOPC_PW to run this test.'
		unless ( $username && $password );
}

my $class         = 'Business::OnlinePayment';
my $engine        = 'CyberSource';

use_ok "${class}::$engine";

my $client        = new_ok $class, [ $engine ];
my $username      = $ENV{BOPC_UN};
my $password      = $ENV{BOPC_PW};

my $data          = {
	login           => $username,
	password        => $password,
	reference_code  => 44544,
	type            => 'CC',
	action          => 'Normal Authorization',
	description     => 'Business::OnlinePayment visa test',
	amount          => '9000',
	invoice_number  => '100100',
	first_name      => 'Tofu',
	last_name       => 'Beast',
	address         => '123 Anystreet',
	city            => 'Anywhere',
	state           => 'UT',
	zip             => '84058',
	country         => 'US',
	email           => 'tofu@beast.org',
	card_number     => '4111111111111111',
	expiration      => '12/25',
	cvv2 => 1111,
};

$client->content( %$data );
$client->test_transaction(1);    # test, dont really charge

$ENV{PERL_BUSINESS_CYBERSOURCE_DEBUG} = 1;

my $success       = $client->submit();

ok $client->is_success(), 'transaction successful'
	or diag $client->error_message();

is   $client->is_success(), $success, 'Success matches';
like $client->authorization(), qr/^\w+$/, 'Authorization is a string';
like $client->order_number(), qr/^\w+$/, 'Order number is a string';
ok   ! defined( $client->card_token() ), 'Card token is not defined';
ok   ! defined( $client->fraud_score() ), 'Fraud score is not defined';
ok   ! defined( $client->fraud_transaction_id() ), 'Fraud transaction id is not defined';
is   $client->response_code(), 200, 'Response code is 200';
is   ref( $client->response_headers() ), 'HASH', 'Response headers is a hashref';
like $client->response_page(), qr/^.+$/sm, 'Response page is a string';
like $client->result_code(), qr/^\w+$/, 'Result code is a string';
like $client->avs_code(), qr/^\w+$/, 'AVS code is a string';
like $client->cvv2_response(), qr/^\w+$/, 'CVV2 code is a string';
is   $client->transaction_type(), $data->{type}, 'Type matches';
is   $client->login(), $ENV{BOPC_UN}, 'Login matches';
is   $client->password(), $ENV{BOPC_PW}, 'Password matches';
is   $client->test_transaction(), 1, 'Test transaction matches';
is   $client->require_avs(), 0, 'Require AVS matches';
is   $client->server(), 'ics2wstest.ic3.com', 'Server matches';
is   $client->port(), 443, 'Port matches';
is   $client->path(), 'commerce/1.x/transactionProcessor', 'Path matches';
is   $client->reference_code(), $data->{reference_code}, 'Reference code matches';

done_testing;
