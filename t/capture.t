BEGIN { $| = 1; print "1..2\n"; }

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
$tx->test_transaction(1); # test, dont really charge
$tx->submit();

unless($tx->is_success()) {
  print "not ok 1\n";
  print "not ok 2\n";
} else {
  my $order_number = $tx->order_number;
  warn $order_number;
  print "ok 1\n";
  
  my $settle_tx = new Business::OnlinePayment("CyberSource");
  $settle_tx->content(
                      type           => 'VISA',
                      action         => 'Post Authorization',
                      description    => 'Business::OnlinePayment visa test',
                      amount         => '49.95',
                      invoice_number => '100100',
                      order_number   => $order_number,
                     );
  
  $settle_tx->test_transaction(1); # test, dont really charge
  $settle_tx->submit();
  
  if($settle_tx->is_success()) {
    print "ok 2\n";
  } else {
    warn $settle_tx->error_message;
    print "not ok 2\n";
  }
  
}
