package Business::OnlinePayment::CyberSource;

use strict;
use Carp;
use Business::OnlinePayment;
use Business::OnlinePayment::CyberSource::Error;
use cybs;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.05';

# ACTION MAP
my @action_list = ('ccAuthService_run', 'ccAuthReversalService_run',
                   'ccCaptureService_run', 'ccCreditService_run',
                   'afsService_run');

my %actions = ('normal authorization' => ['ccAuthService_run', 'ccCaptureService_run'],
               'authorization only'   => ['ccAuthService_run'],
               'credit'               => ['ccCreditService_run'],
               'post authorization'   => ['ccCaptureService_run'],
               'void authorization'   => ['ccAuthReversalService_run'],
               );

# CARD TYPE MAP
my %card_types = ('visa'               => '001',
                  'mastercard'         => '002',
                  'american express'   => '003',
                  'discover'           => '004',
                  'diners club'        => '005',
                  'carte blanche'      => '006',
                  'jcb'                => '007',
                  'optima'             => '008',
                  );





sub set_defaults {
  my $self = shift;
  my $startup = {};
  # The default is /etc/
  my $conf_file = ( $self->can('conf_file') && $self->conf_file ) || '/etc/cybs.ini';

  my %config = &cybs::cybs_load_config( $conf_file );

  $self->{'_config'} = \%config;

  $self->build_subs(qw( order_number avs_code  cvv2_response cavv_response
                        auth_reply auth_reversal_reply capture_reply credit_reply afs_reply
                      ));
}

sub map_fields {
    my($self,%map) = @_;

    my %content = $self->content();
    foreach(keys %map) {
        $content{$map{$_}} = $content{$_};
    }
    $self->content(%content);
}

sub get_fields {
    my($self,@fields) = @_;

    my %content = $self->content();
    my %new = ();
    foreach( grep defined $content{$_}, @fields) { $new{$_} = $content{$_}; }
    return %new;
}

sub submit {
  my($self) = @_;

  my $config = $self->{'_config'};
  my $content = $self->{'_content'};

  my $reply = {};
  my $request = {};

  my $error_handler = new Business::OnlinePayment::CyberSource::Error;

  # If it's available but not set, grab the merchant_id from the conf
  if (!defined($content->{'login'}) ||
      $content->{'login'} eq '') {
    $content->{'login'} = $config->{'merchantID'};
  }

  $self->required_fields(qw(action login invoice_number));
  $self->map_fields(login             => 'merchantID',
                    invoice_number    => 'merchantReferenceCode',
                    );


  $content->{'application'} ||= 'Business::OnlinePayment::CyberSource';
  $content->{'version'} ||= $VERSION;
  $self->map_fields(application   => 'clientApplication',
                    version       => 'clientApplicationVersion',
                    user          => 'clientApplicationUser',
                    );

  ### Handle The Actions
  # Reset them all
  foreach my $action (@action_list) {
    $content->{$action} = 'false';
  }

  # Set them correctly
  foreach my $action (@{$actions{lc($content->{'action'})}}) {
    $content->{$action} = 'true';
  }

  # Allow for Advanced Fraud Check
  if (defined($content->{'fraud_check'}) && lc($content->{'fraud_check'}) eq 'true') {
    $content->{'afsService_run'} = 'true';
  }

  my %request_base = $self->get_fields(@action_list, qw( afsService_run
                                       merchantID merchantReferenceCode
                                       clientApplication clientApplicationVersion clientApplicationUser
                                      ));

  $self->request_merge($request,\%request_base);

  $self->map_fields(company           => 'billTo_company',
                    first_name        => 'billTo_firstName',
                    last_name         => 'billTo_lastName',
                    address           => 'billTo_street1',
                    address2          => 'billTo_street2',
                    city              => 'billTo_city',
                    state             => 'billTo_state',
                    zip               => 'billTo_postalCode',
                    country           => 'billTo_country',                        ,
                    ssn               => 'billTo_ssn',
                    phone             => 'billTo_phoneNumber',
                    email             => 'billTo_email',
                    card_number       => 'card_accountNumber',
                    cvv2_status       => 'card_cvIndicator',
                    cvv2              => 'card_cvNumber',
                    ship_last_name    => 'shipTo_lastName',
                    ship_first_name   => 'shipTo_firstName',
                    ship_address      => 'shipTo_street1',
                    ship_address2     => 'shipTo_street2',
                    ship_city         => 'shipTo_city',
                    ship_state        => 'shipTo_state',
                    ship_zip          => 'shipTo_postalCode',
                    ship_country      => 'shiptTo_country',
                    ship_email        => 'shipTo_email',
                    ship_phone        => 'shipTo_phoneNumber',
                    customer_hostname => 'billTo_hostname',
                    customer_browser  => 'billTo_httpBrowserType',
                    customer_ip       => 'billTo_ipAddress',
                    avs_level         => 'ccAuthService_avsLevel',
                    cavv              => 'ccAuthService_cavv',
                    xid               => 'ccAuthService_xid',
                    eci_raw           => 'ccAouthService_eciRaw',
                    avs_decline_flags => 'businessRules_declineAVSFlags',
                    avs_ignore_result => 'businessRules_ignoreAVSResult',
                    capture_anyway    => 'businessRules_ignoreCVResult',
                    merchant_descriptor => 'invoiceHeader_merchantDescriptor',
                    AMEX_Data1          => 'invoiceHeader_amexDataTAA1',
                    AMEX_Data2          => 'invoiceHeader_amexDataTAA2',
                    AMEX_Data3          => 'invoiceHeader_amexDataTAA3',
                    AMEX_Data4          => 'invoiceHeader_amexDataTAA4',
                    fraud_threshold     => 'businessRules_scoreThreshold',
                    order_number        => 'request_id',
                   );

  my %request = $self->get_fields( qw( purchaseTotals_currency
                                       billTo_company billTo_firstName billTo_lastName billTo_street1
                                       billTo_street2 billTo_city billTo_state billTo_postalCode billTo_country
                                       billTo_ssn billTo_phoneNumber billTo_email card_accountNumber
                                       card_cvIndicator card_cvNumber shipTo_lastName shipTo_firstName
                                       shipTo_street1 shipTo_street2 shipTo_city shipTo_state shipTo_postalCode
                                       shiptTo_country shipTo_email shipTo_phoneNumber billTo_hostname
                                       billTo_httpBrowserType billTo_ipAddress ccAuthService_avsLevel
                                       merchant_descriptor AMEX_Data1 AMEX_Data2 AMEX_Data3 AMEX_Data4
                                       businessRules_scoreThreshold
                                     ));

  $self->request_merge($request,\%request);

  #Split up the expiration
  if (defined($content->{'expiration'})) {
    # This works for MM/YYYY, MM/YY, MMYYYY, and MMYY
    $content->{'expiration'} =~ /^(\d+)\D*\d*(\d{2})$/
      or croak "unparsable expiration ". $content->{expiration};
    $request->{'card_expirationMonth'} = $1;
    $request->{'card_expirationYear'} = $2;
  }

  $self->_set_item_list($content, $request);

  # SSN
  if (defined($content->{'ssn'}) && 
      $content->{'ssn'} ne '') {
    $content->{'ssn'} =~ s/-//g;
  }

  $content->{'card_cardType'} = $card_types{lc($self->transaction_type)};

  # Check and convert the data for an Authorization
  if (lc($content->{'ccAuthService_run'}) eq 'true') {

    $self->required_fields(qw(first_name last_name city country email address card_number expiration invoice_number type));

  }

  if (lc($content->{'ccAuthReversalService_run'}) eq 'true') {
    $self->required_fields(qw(request_id));
    $request->{'ccAuthReversalService_authRequestID'} = $content->{'request_id'};
  }
  if (lc($content->{'ccCaptureService_run'}) eq 'true') {

    if (lc($content->{'ccAuthService_run'}) ne 'true') {
      $self->required_fields(qw(order_number));
      $request->{'ccCaptureService_authRequestID'} = $content->{'request_id'};
      if (defined($content->{'auth_code'})) {
        $request->{'ccCaptureService_authverbalAuthCode'} = $content->{'auth_code'};
        $request->{'ccCaptureService_authType'} = 'verbal';
      }
    }

  }
  if (lc($content->{'ccCreditService_run'}) eq 'true') {
    if (defined($content->{'request_id'}) &&
        $content->{'request_id'} ne '') {
      $self->required_fields(qw(request_id));
      $request->{'ccCreditService_captureRequestID'} = $content->{'request_id'};
    } else {
      $self->required_fields(qw(first_name last_name city country email address card_number expiration invoice_number type));
    }
  }
  if (lc($request->{'afsService_run'}) eq 'true') {
    if (!defined($content->{'items'}) || scalar($content->{'items'}) < 1) {
      &Carp::croak("Advanced Fraud Screen requests require that you populate the items hash.");
    }
  }

  # Configuration should always take over!  There's nothing so confusing as having the config show test and
  # it still sends to live
  if (lc($config->{'sendToProduction'}) eq 'true' ||
      $config->{'sendToProduction'} eq '') {
    $config->{'sendToProduction'} = $self->test_transaction()?"false":"true";
  }

  # Use the configuration values for some of the business logic - However, let the request override these...
  if (!defined($request->{'businessRules_declineAVSFlags'}) && defined($config->{'businessRules_declineAVSFlags'}) ) {
    $request->{'businessRules_declineAVSFlags'} = $config->{'businessRules_declineAVSFlags'};
  }
  if (!defined($request->{'businessRules_ignoreAVSResult'}) && defined($config->{'businessRules_ignoreAVSResult'}) ) {
    $request->{'businessRules_ignoreAVSResult'} = $config->{'businessRules_ignoreAVSResult'};
  }
  if (!defined($request->{'businessRules_ignoreCVResult'}) && defined($config->{'businessRules_ignoreCVResult'}) ) {
    $request->{'businessRules_ignoreCVResult'} = $config->{'businessRules_ignoreCVResult'}
  }

  ##### 
  ###Here's the Magic
  #####
  my $cybs_return_code = &cybs::cybs_run_transaction($config, $request, $reply);

  if ( $cybs_return_code != &cybs::CYBS_S_OK ) {
    $self->is_success(0);
    if ( $cybs_return_code == &cybs::CYBS_S_PERL_PARAM_ERROR ) {
      $self->error_message("A parsing error occurred - there is a problem with one or more of the parameters.");
    } elsif ( $cybs_return_code == &cybs::CYBS_S_PRE_SEND_ERROR ) {
      $self->error_message("Could not create the request - There is probably an error with your client configuration. More Information:" . $reply->{&cybs::CYBS_SK_ERROR_INFO});
    } elsif ( $cybs_return_code == &cybs::CYBS_S_PRE_SEND_ERROR ) {
      $self->error_message("Something bad happened while sending. More Information:" . $reply->{&cybs::CYBS_SK_ERROR_INFO});
     } else {
      $self->error_message('Something REALLY bad happened. Your transaction may have been processed or it could have blown up.  Check the business center to figure it out. Good Luck... More Information:' .$reply->{&cybs::CYBS_SK_ERROR_INFO} . ' Raw Error:' . $reply->{&cybs::CYBS_SK_RAW_REPLY} . ' Probable Request ID:' . $reply->{&cybs::CYBS_SK_FAULT_REQUEST_ID});
    }
    return 0;
  }
  
  # Fields for all queries
  $self->server_response($reply);
  $self->order_number($reply->{'requestID'});
  $self->result_code($reply->{'reasonCode'});

  if ($reply->{'decision'} eq 'ACCEPT') {
    $self->is_success(1);
  } else {
    $self->is_success(0);
    $self->error_message($error_handler->get_text($self->result_code));
  }

  my $ccAuthHash = {};
  my $ccAuthReversalHash = {};
  my $ccCaptureHash = {};
  my $ccCreditHash = {};
  my $afsHash = {};

  foreach my $key (keys %{$reply}) {
    if ($key =~ /^ccAuthReply_(.*)/) {
      $ccAuthHash->{$key} = $reply->{$key};
    } elsif ($key =~ /^ccAuthReversalReply_(.*)/) {
      $ccAuthReversalHash->{$key} = $reply->{$key};
    } elsif ($key =~ /^ccCaptureReply_(.*)/) {
      $ccCaptureHash->{$key} = $reply->{$key};
    } elsif ($key =~ /^ccCreditReply_(.*)/) {
      $ccCreditHash->{$key} = $reply->{$key};
    } elsif ($key =~ /^afsReply_(.*)/) {
      $afsHash->{$key} = $reply->{$key};
    }
  }

  if ($request->{'ccAuthService_run'} eq 'true') {
    $self->avs_code($reply->{'ccAuthReply_avsCode'});
    $self->authorization($reply->{'ccAuthReply_authorizationCode'});
    $self->auth_reply($ccAuthHash);
#    $self->request_id($reply->{'requestID'});
  }
  if ($request->{'ccAuthReversalService_run'} eq 'true') {
    $self->auth_reversal_reply($ccAuthReversalHash);
  }
  if ($request->{'ccCaptureService_run'} eq 'true') {
    $self->capture_reply($ccCaptureHash);
  }
  if ($request->{'ccCreditService_run'} eq 'true') {
    $self->credit_reply($ccCreditHash);
  }
  if ($request->{'afsService_run'} eq 'true') {
    $self->afs_reply($afsHash);
  }
  return $self->is_success;
}

sub _set_item_list {
  # Big time side effects - The items are going to be loaded into the hash
  my ($self, $content, $request) = @_;

  # Here go the items/amounts
  if (defined($content->{'items'}) && scalar($content->{'items'}) > 0) {
    foreach my $item (@{$content->{'items'}}) {
      if (defined($item->{'type'}) && $item->{'type'} ne '') {
        $request->{"item_".$item->{'number'}."_productCode"} = $item->{'type'};
      }
      if (defined($item->{'SKU'}) && $item->{'SKU'} ne '') {
        $request->{"item_".$item->{'number'}."_productSKU"} = $item->{'SKU'};
      }
      if (defined($item->{'name'}) && $item->{'name'} ne '') {
        $request->{"item_".$item->{'number'}."_productName"} = $item->{'name'};
      }
      if (defined($item->{'quantity'}) && $item->{'quantity'} ne '') {
        $request->{"item_".$item->{'number'}."_quantity"} = $item->{'quantity'};
      }
      if (defined($item->{'tax'}) && $item->{'tax'} ne '') {
        $request->{"item_".$item->{'number'}."_taxAmount"} = $item->{'tax'};
      }
      if (defined($item->{'unit_price'}) && $item->{'unit_price'} ne '') {
        $request->{"item_".$item->{'number'}."_unitPrice"} = $item->{'unit_price'};
      } else {
        &Carp::croak("Item " . $item->{'number'} . " has no unit_price");
      }
    } 
  } elsif (defined($content->{'amount'}) && $content->{'amount'} ne '') {
    if (defined($content->{'freight'}) && $content->{'freight'} ne '') {
      $request->{'purchaseTotals_freightAmount'} = $content->{'freight'};
    }
    if (defined($content->{'tax'}) && $content->{'tax'} ne '') {
      $request->{'purchaseTotals_taxAmount'} = $content->{'tax'};
    }
    $request->{'purchaseTotals_grandTotalAmount'} = $content->{'amount'};
  } else {
    &Carp::croak("It's impossible to auth without items or amount populated!");
  }
  
  if ($content->{'recurring_billing'}) {
    $request->{'ccAuthService_commerceIndicator'} = 'recurring';
  } else  {
    $request->{'ccAuthService_commerceIndicator'} = 'internet';
  }
  # Set the Currency
  if (defined($content->{'currency'}) && $content->{'currency'} ne '') {
    $request->{'purchaseTotals_currency'} = $content->{'currency'};
    } else {
      $request->{'purchaseTotals_currency'} = 'USD';
    }
}

sub request_merge {
  my ($self, $request, $merge) = @_;
  foreach my $key (keys %{$merge}) {
    $request->{$key} = $merge->{$key};
  }
}

1;
__END__

=head1 NAME

Business::OnlinePayment::CyberSource - CyberSource backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("CyberSource",
                                       conf_file => '/path/to/cybs.ini'");
  $tx->content(
             type           => 'VISA',
             action         => 'Normal Authorization',
             invoice_number => '00000001',
             items          => [{'number'   => 0,
                                 'name'     => 'Test 1',
                                 'quantity' => 1,
                                 'unit_price' => '25.00'},
                                  {'number'   => 1,
                                   'name'     => 'Test 2',
                                   'quantity' => 1,
                                   'unit_price' => '50.00'},
                                ],
             first_name     => 'Peter',
             last_name      => 'Bowen',
             address        => '123 Anystreet',
             city           => 'Orem',
             state          => 'UT',
             zip            => '84097',
             country        => 'US',
             email          => 'foo@bar.net',
             card_number    => '4111 1111 1111 1111',
             expiration     => '0906',
             cvv2           => '1234', #optional
             referer        => 'http://valid.referer.url/',
             user           => 'cybesource_user',
             fraud_check    => 'true',
             fraud_threshold => '90',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

  ####
  # Two step transaction, authorization and capture.
  # If you don't need to review order before capture, you can
  # process in one step as above.
  ####

  my $tx = new Business::OnlinePayment("CyberSource",
                                       conf_file => '/path/to/cybs.ini'");
  $tx->content(
             type           => 'VISA',
             action         => 'Authorization Only',
             invoice_number => '00000001',
             items          => [{'number'   => 0,
                                 'name'     => 'iPod Mini',
                                 'quantity' => 1,
                                 'unit_price' => '25.00'},
                                  {'number'   => 1,
                                   'name'     => 'Extended Warranty',
                                   'quantity' => 1,
                                   'unit_price' => '50.00'},
                                ],
             first_name     => 'Peter',
             last_name      => 'Bowen',
             address        => '123 Anystreet',
             city           => 'Orem',
             state          => 'UT',
             zip            => '84097',
             country        => 'US',
             email          => 'foo@bar.net',
             card_number    => '4111 1111 1111 1111',
             expiration     => '0906',
             cvv2           => '1234', #optional
             referer        => 'http://valid.referer.url/',
             user           => 'cybesource_user',
             fraud_check    => 'true',
             fraud_threshold => '90',
  );
  $tx->submit();

  if($tx->is_success()) {
      # get information about authorization
      $authorization = $tx->authorization
      $order_number = $tx->order_number;
      $avs_code = $tx->avs_code; # AVS Response Code
      $cvv2_response = $tx->cvv2_response; # CVV2/CVC2/CID Response Code
      $cavv_response = $tx->cavv_response; # Cardholder Authentication
                                           # Verification Value (CAVV) Response
                                           # Code

      # now capture transaction
      my $capture = new Business::OnlinePayment("CyberSource");

      $capture->content(
          action              => 'Post Authorization',
          order_number        => $order_number,
          merchant_descriptor => 'IPOD MINI',
          amount              => '75.00',
      );

      $capture->submit();

      if($capture->is_success()) { 
          print "Card captured successfully: ".$capture->authorization."\n";
      } else {
          print "Card was rejected: ".$capture->error_message."\n";
      }

  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 Visa, MasterCard, American Express, Discover

Content required: type, login, action, amount, first_name, last_name, card_number, expiration.

TODO - Checks

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

The cybs.ini default home is /etc/cybs.ini - if you would prefer it to 
live someplace else specify that in the new.

A few notes on cybs.ini - most settings can be overwritten by the submit 
call - except for the following exceptions:

  sendToProduction 
  From a systems perspective, this should be hard so that there is NO 
confusion as to which server the request goes against.

You can set the business rules from th ini - the following rules are supported

  businessRules_declineAVSFlags

  businessRules_ignoreAVSResult

  businessRules_ignoreCVResult

Unlike Business::OnlinePayment, Business::OnlinePayment::CyberSource
requires separate first_name and last_name fields.

To settle an authorization-only transaction (where you set action to
'Authorization Only'), submit the request ID code in the field
"order_number" with the action set to "Post Authorization".

You can get the transaction id from the authorization by calling the
order_number method on the object returned from the authorization.
You must also submit the amount field with a value less than or equal
to the amount specified in the original authorization.

=head1 COMPATIBILITY

This module implements the Simple Order API 1.0 from Cybersource.


=head1 AUTHOR

Peter Bowen peter@bowenfamily.org

Based on  L<Business::OnlinePayment::AuthorizeNet>

=head1 THANK YOU

Jason Kohles - For writing BOP - I didn't have to create my own framework.

Ivan Kohler - Tested the first pre-release version and fixed a number of bugs.
              He also encouraged me to add better error reporting for system errors.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=head1 TODO

=over 4

=item Full Documentation

=item Electronic Checks

=item Pay Pal

=item Full support including Level III descriptors

=cut

