#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Class::Load 0.20 qw( load_class );

my $client   = new_ok( load_class('Business::OnlinePayment'), [ 'CyberSource' ]);
my $datetime = $client->_expiration_to_datetime( '0416' );

isa_ok $datetime, 'DateTime';
is     $datetime->ymd(), '2016-04-30', 'expiration matches';

$datetime    = $client->_expiration_to_datetime( '04/16' );

isa_ok $datetime, 'DateTime';
is     $datetime->ymd(), '2016-04-30', 'Expiration matches';

$datetime    = $client->_expiration_to_datetime( '04/2016' );

isa_ok $datetime, 'DateTime';
is     $datetime->ymd(), '2016-04-30', 'Expiration matches';

$datetime    = $client->_expiration_to_datetime( '2016-04-12' );

isa_ok $datetime, 'DateTime';
is     $datetime->ymd(), '2016-04-30', 'Expiration matches';

done_testing;
