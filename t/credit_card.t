BEGIN { $| = 1; print "1..1\n"; }

#testing/testing is valid and seems to work...

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("CyberSource");
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
             expiration     => '08/10',
);
$tx->test_transaction('true'); # test, dont really charge
$tx->submit();

if($tx->is_success()) {
    print "ok 1\n";
} else {
    #warn $tx->error_message;
    print "not ok 1\n";
}
