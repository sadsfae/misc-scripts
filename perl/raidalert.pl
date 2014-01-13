#!/usr/bin/perl -w
# this is a simple CGI that will make take form submission
# and then forward it via email
# in it's current form it might be used to quickly generate
# email-to-sms gateway messages using a list of someones number@ISP format:
# https://en.wikipedia.org/wiki/List_of_SMS_gateways
# with a sane sendmail .forwards file it can be easily parsed and email to SMS message can be dispatched
# the usage below might be for an online gaming guild who competes for in-game mobs with others
# twitter functionality via the 1.1 API is also added below to post the CGI text
# to a twitter account, if users are subscribed to it via SMS they will receive it
# the same way that the normal email-to-sms message is sent.

use CGI;

# Create a CGI object
my $query = new CGI;

# Output the HTTP header
print $query->header ( );

# Capture form results
my $email_address = $query->param("email_address");
my $comments = $query->param("comments");

# Filter form results
$email_address = filter_header_field ( $email_address );
$comments = filter_field ( $comments );

# call sendmail (or equivalent) to send the message
# useful if used with a specified local user and ~/.forwards file
# .forwards file can contain sms to email gateway addresses perhaps.. 
open ( MAIL, "| /usr/sbin/sendmail -t -fXXXXXXXXX" );
print MAIL "From: $email_address\n";
print MAIL "To: XXXXXX\@XXXXXX.com\n";
print MAIL "Subject: XXXXX\n\n";
print MAIL "($email_address)\n\n";
print MAIL "$comments\n";
print MAIL "\n.\n";
close ( MAIL );

########### POST TO TWITTER URL ###########
# fill in your twitter account details if you'd like
# to have twitter use/call the same backend system
# this will also post your raid alert on twitter and people
# subscribed to it will receive it (via SMS or other)
use Net::Twitter::Lite::WithAPIv1_1;

my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
  consumer_key        => 'XXXXXXXXXXXXXXXX',
  consumer_secret     => 'XXXXXXXXXXXXXXXX',
  access_token        => 'XXXXXXXXXXXXXXXX',
  access_token_secret => 'XXXXXXXXXXXXXXXX'
);

my $result = eval { $nt->update($comments) };

warn "$@\n" if $@;

########### AUTO GENERATE HTML PAGE WHEN DONE ##########
# compose an HTML page after CGI submission
# example below might be for an onling gaming guild

print <<END_HTML;
<html>
<head></head>
<body>Cry Havoc, and let slip the dogs of war! (raid alert sent)<br>
<br>Legions of able-bodied XXXXXXXX soldiers are forming up for your cause as we speak!</body>
</html>
END_HTML

# Functions for filtering user input

sub filter_field
{
  my $field = shift;
  $field =~ s/From://gi;
  $field =~ s/To://gi;
  $field =~ s/BCC://gi;
  $field =~ s/CC://gi;
  $field =~ s/Subject://gi;
  $field =~ s/Content-Type://gi;
  return $field;
}

sub filter_header_field
{
  my $field = shift;
  $field =~ s/From://gi;
  $field =~ s/To://gi;
  $field =~ s/BCC://gi;
  $field =~ s/CC://gi;
  $field =~ s/Subject://gi;
  $field =~ s/Content-Type://gi;
  $field =~ s/[\0\n\r\|\!\/\<\>\^\$\%\*\&]+/ /g;
  return $field;
}
