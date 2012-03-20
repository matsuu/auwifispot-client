#!/usr/bin/perl

use strict;
use warnings;

use utf8;

binmode STDOUT, ":utf8";

use Getopt::Long;
use LWP::UserAgent;
use Pod::Usage;
use XML::Simple;

my $user_id;
my $passwd;
GetOptions("u|user_id=s" => \$user_id, "p|passwd=s" => \$passwd) or pod2usage(2);
pod2usage(1) unless $user_id && $passwd;

# for au
my $username = $user_id =~ /@/ ? $user_id : sprintf('%s@au', $user_id);

# Wi-Fi接続ツールがこのアドレスにアクセスしていたが、
# 多分なんでもok
my $certification_url = "http://www.au.kddi.com/au_wifi_spot/certification2/";

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

# request_redirectableが設定されていると
# コンテンツを返しつつ302を返すパターンに対応できないので
$ua->requests_redirectable([]);

my $error_types = {
    "0" => "No error",
   "50" => "Login succeeded (Access ACCEPT)",
  "100" => "Login failed (Access REJECT)",
  "102" => "RADIUS server error/timeout",
  "105" => "Network Administrator Error: Does not have RADIUS enabled",
  "150" => "Logoff succeeded",
  "151" => "Login aborted",
  "200" => "Proxy detection/repeat operation",
  "201" => "Authentication pending",
  "255" => "Access gateway internal error",
};

sub parse_wispr {
  my ($response) = shift;

  # redirectでもcontentが含まれる場合はリダイレクトさせない(au Wi-Fi SPOT対策)
  if($response->is_redirect) {
    if ($response->content_length == 0) {
      # Wi2はLocationが相対パスなので補う
      # LWP::UserAgentから拝借
      my $referral_uri = $response->header('Location');
      {
        local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
        my $base = $response->base;
        $referral_uri = "" unless defined $referral_uri;
        $referral_uri = $HTTP::URI_CLASS->new($referral_uri, $base)->abs($base);
      }
      return parse_wispr($ua->get($referral_uri));
    }
  }
  elsif(!$response->is_success) {
    die $response->status_line;
  }

  my $content = $response->decoded_content;

  # Wi2のWISPrがぶっこわれてるので
  $content =~ s/-->ISPAccessGatewayParam>/<\/WISPAccessGatewayParam>-->/;
  $content =~ s/(xmlns:xsi)=(http:\/\/www.w3.org\/2001\/XMLSchema-instance)/$1="$2"/;

  if($content !~ qr{(<WISPAccessGatewayParam.*</WISPAccessGatewayParam>)}s) {
    die "no WISPr(Already connected?)." 
  }
  return XMLin($1);
}

my ($xml, $reply, $response_code);

$xml = parse_wispr($ua->get($certification_url));
die "No Redirect" unless exists $xml->{Redirect};
$reply = $xml->{Redirect};
$response_code = $reply->{ResponseCode};

#   0: No error
# 105: Network Administrator Error: Does not have RADIUS enabled
# 255: Access Gateway internal error

die $error_types->{$response_code} if $response_code ne '0';
foreach my $name (qw(AccessProcedure AccessLocation LocationName)) {
  printf "%s: %s\n", $name, $reply->{$name} if exists $reply->{$name};
}

my $login_url = $xml->{Redirect}{LoginURL};
my %login_params;
$login_params{UserName} = $username;
$login_params{Password} = $passwd;

$xml = parse_wispr($ua->post($login_url, \%login_params));
die "No AuthenticationReply" unless exists $xml->{AuthenticationReply};
$reply = $xml->{AuthenticationReply};
$response_code = $reply->{ResponseCode};

#  50: Login succeeded (Access ACCEPT)
# 100: Login failed (Access Reject)
# 102: RADUIS server error/timeout
# 201: Authentication pending
# 255: Access Gateway internal error

if($response_code eq '201') {
  my $login_results_url = $reply->{LoginResultsURL};
  while($response_code eq '201') {
    sleep $reply->{Delay} if exists $reply->{Delay};
    $xml = parse_wispr($ua->post($login_results_url));
    die "No AuthenticationPollReply" unless exists $xml->{AuthenticationPollReply};
    $reply = $xml->{AuthenticationPollReply};
    $response_code = $reply->{ResponseCode};
  }
}
printf "%s\n", $error_types->{$response_code} if exists $error_types->{$response_code};
printf "LogoffUrl: %s\n", $reply->{LogoffURL} if exists $reply->{LogoffURL};

__END__

=head1 NAME

auwifi_login.pl - au Wi-Fi SPOT login

=head1 SYNOPSIS

auwifi_login.pl [options]

 Options:
  -u, --user_id=[user_id]    set user_id
  -p, --passwd=[passwd]      set passwd

=head1 OPTIONS

=over 8

=item B<--user_id=[user_id]>

Set user_id.

=item B<--passwd=[passwd]>

Set passwd.

=back

=head1 DESCRIPTION

B<This program> will login to au Wi-Fi SPOT.

=cut
