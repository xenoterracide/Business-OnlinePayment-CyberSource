package Business::OnlinePayment::CyberSource::Error;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.01';

#ERROR MAP
my $error_codes = { '100' => {'Text'   => 'Successful transaction.',
                              'Action' => ''},
                    '101' => {'Text'   => 'The request is missing one or more required fields.',
                              'Action' => 'See the reply fields missingField_0...N for which fields are missing. Resend the request with the complete information.'},
                    '102' => {'Text'   => 'One or more fields in the request contains invalid data.',
                              'Action' => 'See the reply fields invalidField_0...N for which fields are invalid. Resend the request with the correct information.'},
                    '150' => {'Text'   => 'Error: General system failure.',
                              'Action' => 'Wait a few minutes and resend the request.'},
                    '151' => {'Text'   => 'Error: The request was received but there was a server timeout. This error does not include timeouts between the client and the server.',
                              'Action' => 'To avoid duplicating the transaction, do not resend the request until you have reviewed the transaction status in the Support Screens.'},
                    '152' => {'Text'   => 'Error: The request was received, but a service did not finish running in time.',
                              'Action' => 'To avoid duplicating the transaction, do not resend the request until you have reviewed the transaction status in the Support Screens.'},
                    '200' => {'Text'   => 'The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the Address Verification Service (AVS) check.',
                              'Action' => 'You can capture the authorization, but consider reviewing the order for the possibility of fraud.'},
                    '201' => {'Text'   => 'The issuing bank has questions about the request. You do not receive an authorization code programmatically, but you might receive one verbally by calling the processor.',
                              'Action' => 'Call your processor to possibly receive a verbal authorization. For contact phone numbers, refer to your merchant bank information.'},
                    '202' => {'Text'   => 'Expired card.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '203' => {'Text'   => 'General decline of the card. No other information provided by the issuing bank.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '204' => {'Text'   => 'Insufficient funds in the account.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '205' => {'Text'   => 'Stolen or lost card.',
                              'Action' => 'Refer the transaction to your customer support center for manual review.'},
                    '207' => {'Text'   => 'Issuing bank unavailable.',
                              'Action' => 'Wait a few minutes and resend the request.'},
                    '208' => {'Text'   => 'Inactive card or card not authorized for card-not-present transactions.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '209' => {'Text'   => 'American Express Card Identification Digits (CID) did not match.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '210' => {'Text'   => 'The card has reached the credit limit.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '211' => {'Text'   => 'Invalid card verification number.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '221' => {'Text'   => "The customer matched an entry on the processor's negative file.",
                              'Action' => 'Review the order and contact the payment processor.'},
                    '230' => {'Text'   => 'The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the card verification (CV) check.',
                              'Action' => 'You can capture the authorization, but consider reviewing the order for the possibility of fraud.'},
                    '231' => {'Text'   => 'Invalid account number.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '232' => {'Text'   => 'The card type is not accepted by the payment processor.',
                              'Action' => 'Contact your merchant bank to confirm that your account is set up to receive the card in question.'},
                    '233' => {'Text'   => 'General decline by the processor.',
                              'Action' => 'Request a different card or other form of payment.'},
                    '234' => {'Text'   => 'There is a problem with your CyberSource merchant configuration.',
                              'Action' => 'Do not resend the request. Contact Customer Support to correct the configuration problem.'},
                    '235' => {'Text'   => 'The requested amount exceeds the originally authorized amount. Occurs, for example, if you try to capture an amount larger than the original authorization amount.',
                              'Action' => 'Issue a new authorization and capture request for the new amount.'},
                    '236' => {'Text'   => 'Processor failure.',
                              'Action' => 'Wait a few minutes and resend the request.'},
                    '237' => {'Text'   => 'The authorization has already been reversed.',
                              'Action' => 'No action required.'},
                    '238' => {'Text'   => 'The authorization has already been captured.',
                              'Action' => 'No action required.'},
                    '239' => {'Text'   => 'The requested transaction amount must match the previous transaction amount.',
                              'Action' => 'Correct the amount and resend the request.'},
                    '240' => {'Text'   => 'The card type sent is invalid or does not correlate with the credit card number.',
                              'Action' => 'Confirm that the card type correlates with the credit card number specified in the request, then resend the request.'},
                    '241' => {'Text'   => 'The request ID is invalid.',
                              'Action' => 'Request a new authorization, and if successful, proceed with the capture.'},
                    '242' => {'Text'   => 'You requested a capture, but there is no corresponding, unused authorization record. Occurs if there was not a previously successful authorization request or if the previously successful authorization has already been used by another capture request.',
                              'Action' => 'Request a new authorization, and if successful, proceed with the capture.'},
                    '250' => {'Text'   => 'Error: The request was received, but there was a timeout at the payment processor.',
                              'Action' => 'To avoid duplicating the transaction, do not resend the request until you have reviewed the transaction status in the Support Screens.'},
                    '400' => {'Text'   => "The Advanced Fraud Screen score exceeds your threshold.",
                              'Action' => "Review the customer's order."},
                    '510' => {'Text'   => "The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the Smart Authorization check.",
                              'Action' => "Do not capture the authorization without further review. The Smart Authorization codes give you additional information as to why CyberSource refused the request."},
                    '700' => {'Text'   => "The customer is on a list issued by the U.S. government containing entities with whom trade is restricted.",
                              'Action' => "Reject the customer's order."},
                  };

my $afs_codes = { 'A' => "Excessive address change. The customer had two or more billing address changes in the last six months.",
                  'B' => "BIN number mismatch. The customer's Visa or MasterCard credit card was issued in a country different from that specified in the billing address.",
                  'C' => "High count of unique account numbers. The customer used more than six unique credit cards in the last six months.",
                  'D' => "Domain (host) impact. The customer had a risky IP or email address.",
                  'F' => "Fraud list flag. The account number, street address, email address, or IP address for this order appears on the negative list for your CyberSource merchant ID.",
                  'G' => "Geolocation inconsistencies. The customer's email domain, phone number, billing address, shipping address, or IP address is suspicious.",
                  'H' => "Excessive name change. The customer had two or more name changes in the last six months.",
                  'I' => "Internet inconsistencies. The IP address and email domain are inconsistent with the billing address.",
                  'N' => "Nonsensical input. The customer name and address fields contain words or language having no meaning.",
                  'O' => "Obscenities. The customer input contains obscene words.",
                  'Q' => "Phone inconsistencies. The customer phone number is suspicious.",
                  'R' => "Risky transaction. Characteristics in this order display multiple high-risk correlations between the transaction, consumer, and merchant information.",
                  'T' => "Time hedge. The customer is attempting a purchase outside of the expected hours for an item.",
                  'U' => "Unverifiable address. The billing or shipping address cannot be verified.",
                  'V' => "Purchase frequency (Velocity). The account number was used many times in the past 15 minutes.",
                  'W' => "Warning. The billing or shipping address is similar to an address previously marked as suspect.",
                  'Y' => "Gift Order. The street address, city, state, or country of the billing and shipping addresses do not correlate.",
                  'Z' => "Invalid value. The information in the request contains an unusual or unexpected value, and a default value was substituted. Although the transaction can still be processed, examine the request carefully for abnormalities in the order." 
                  };

my $avs_codes = {'A' => "Street address matches, but both 5-digit and 9-digit ZIP code do not match.",
                 'B' => "Street address matches, but postal code not verified. Returned only for non-U.S.-issued Visa cards.",
                 'C' => "Street address and postal code not verified. Returned only for non-U.S.-issued Visa cards.",
                 'D & M' => "Street address and postal code both match. Returned only for non-U.S.-issued Visa cards.",
                 'E' => "AVS data is invalid.",
                 'G' => "Non-U.S. issuing bank does not support AVS.",
                 'I' => "Address not verified. Returned only for non-U.S.-issued Visa cards.",
                 'J' => "Card member's name, billing address, and postal code all match. Shipping information verified and chargeback protection guaranteed through the Fraud Protection Program.",
                 'K' => "Card member's name matches. Both billing address and billing postal code do not match.",
                 'L' => "Card member's name matches. Billing postal code matches, but billing address does not match.",
                 'N' => "Street address, 5-digit ZIP code, and 9-digit ZIP code all do not match.",
                 'O' => "Card member's name matches. Billing address matches, but billing postal code does not match.",
                 'P' => "Postal code matches, but street address not verified. Returned only for non-U.S.-issued Visa cards.",
                 'Q' => "Card member's name, billing address, and postal code all match. Shipping information verified but chargeback protection not guaranteed (Standard program).",
                 'R' => "System unavailable.",
                 'S' => "U.S.-issuing bank does not support AVS.",
                 'U' => "Address information unavailable. Returned if non-U.S. AVS is not available or if the AVS in a U.S. bank is not functioning properly.",
                 'V' => "Card member's name matches. Both billing address and billing postal code match.",
                 'W' => "Street address does not match, but 9-digit ZIP code matches.",
                 'X' => "Street address and 9-digit ZIP code both match.",
                 'Y' => "Street address and 5-digit ZIP code both match.",
                 'Z' => "Street address does not match, but 5-digit ZIP code matches.",
                 '1' => "AVS is not supported for this processor or card type.",
                 '2' => "The processor returned an unrecognized value for the AVS response.",
               };

### Constructor
sub new {
  my $class = shift;
  $class = ref($class) || $class;
  
  my $self = { };
  bless $self, $class;
  
  return $self;
}

sub get_text {
  my ($self, $error_code) = @_;
  return $error_codes->{$error_code}->{'Text'}
}

sub get_action {
  my ($self, $error_code) = @_;
  return $error_codes->{$error_code}->{'Action'}
}

sub get_AVS_Text {
  my ($self, $avs_code) = @_;
    return $avs_codes->{$avs_code};
}

sub get_AFS_codes {
  my ($self, $afs_code) = @_;
  return $afs_codes($afs_code);
}

1;
__END__

=head1 NAME

Business::OnlinePayment::CyberSource::Error - Error Code class for Business::OnlinePayment::CyberSource

=head1 SYNOPSIS
  use Business::OnlinePayment::CyberSource::Error;

  my $error_code = 100;
  my $error_decoder = new Business::OnlinePayment::CyberSource::Error;
  my $error_text = $error_decoder->get_text($error_code);
  my $error_action = $error_decoder->get_action($error_code);

=head1 AUTHOR

Peter Bowen, peter-cybersource@bowenfamily.org

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>. L<Business::OnlinePayment::CyberSource>.

=cut

