#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;

plan tests => 4;

my $class         = 'Business::OnlinePayment';
my $engine        = 'CyberSource';
my $main_module   = "${class}::$engine";

my $methods       = [ qw(
	new content test_transaction require_avs submit is_success error_message
	failure_status authorization order_number card_token fraud_score
	fraud_transaction_id response_code response_headers response_page result_code
	avs_code cvv2_response transaction_type server port path build_subs get_fields
	remap_fields required_fields dump_contents silly_bool
) ];

use_ok $class;
use_ok $main_module;
can_ok $main_module, @$methods;
new_ok $class, [ $engine ];
