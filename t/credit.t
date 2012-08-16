#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Class::Load 0.20 qw( load_class );

my $username = $ENV{PERL_BUSINESS_CYBERSOURCE_USERNAME};
my $password = $ENV{PERL_BUSINESS_CYBERSOURCE_PASSWORD};

plan skip_all
	=> 'No credentials set in the environment.'
	. ' Set PERL_BUSINESS_CYBERSOURCE_USERNAME and '
	. 'PERL_BUSINESS_CYBERSOURCE_PASSWORD to run this test.'
	unless ( $username && $password );

my $client = new_ok( load_class('Business::OnlinePayment'), [ 'CyberSource' ]);

my $data          = {
	login           => $username,
	password        => $password,
	invoice_number  => 44544,
	type            => 'CC',
	action          => 'Credit',
	description     => 'Business::OnlinePayment credit test',
	amount          => '9000',
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

my $success       = $client->submit();

ok $client->is_success(), 'Credit was successful'
	or diag $client->error_message();

is $client->is_success(), $success, 'Success maches';

done_testing;
