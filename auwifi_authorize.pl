#!/usr/bin/perl

use strict;
use warnings;

binmode STDOUT, ":utf8";

use File::Temp qw(tempfile);
use Getopt::Long;
use HTTP::Cookies;
use JSON;
use LWP::UserAgent;
use Pod::Usage;
use Web::Scraper;

my $au_one_id;
my $au_one_pw;
my $mac_address;
GetOptions("i|id=s" => \$au_one_id, "p|password=s" => \$au_one_pw, "m|macaddress=s" => \$mac_address) or pod2usage(2);
pod2usage(1) unless $au_one_id && $au_one_pw && $mac_address;

my $request_type = "0";
my $manufacturer = "Apple";
my $model = "Mac OS";

my $signup_url = "https://auwifi-signup.auone.jp/su2/";

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
push @{ $ua->requests_redirectable }, 'POST';
my (undef, $cookie_file) = tempfile("cookieXXXXX", OPEN => 0);
$ua->cookie_jar(HTTP::Cookies->new(file => $cookie_file, autosave => 1));

my $request = {
  request_type => $request_type,
  mac_addrs => [$mac_address],
  manufacturer => $manufacturer,
  model => $model,
};
my $json = to_json($request);

my $response = $ua->post($signup_url, Content => $json);
unless($response->is_success) {
  warn $response->as_string;
  die $response->status_line;
}

# scraping
my $scraper = scraper {
  process 'form', 'action' => '@action';
  process 'input', "params[]" => { name => '@name', value => '@value' };
};
my $res = $scraper->scrape($response);
my $login_url = $res->{action};
my %login_params;
$login_params{$_->{name}} = $_->{value} for @{$res->{params}};
$login_params{loginAliasId} = $au_one_id;
$login_params{loginAuonePwd} = $au_one_pw;

my $login_response = $ua->post($login_url, \%login_params);
unless($login_response->is_success) {
  warn $response->as_string;
  die $login_response->status_line;
}
my $content = $login_response->decoded_content;
my $obj = eval { from_json($content) };
if($@) {
  my $errors = scraper {
    process '#errorMessage p', "error" => 'TEXT';
    process '#infoMessage p', "info" => 'TEXT';
  }->scrape($content);
  print "Authentication failed\n";
  printf "error\n%s\n", $errors->{error} if $errors->{error} ne '';
  printf "info\n%s\n", $errors->{info} if $errors->{info} ne '';
}
else {
  if(exists $obj->{user_id} && exists $obj->{passwd}) {
    print "Authentication success\n";
    # WISPrプロトコルで接続する場合は@auが必要。
    $obj->{user_id} .= '@au';
  }
  else {
    print "Authentication failed\n";
  }
  printf "%s: %s\n", $_, $obj->{$_} for keys %$obj;
}
unlink $cookie_file;

__END__

=head1 NAME

auwifi_authorize.pl - au Wi-Fi SPOT authorization

=head1 SYNOPSIS

auwifi_authorize.pl [options]

 Options:
  -i, --id=[id]              set au ID
  -p, --password=[password]  set au ID password
  -m, --macaddress=[mac]     set MAC address (ex. 1234567890AB)

=head1 OPTIONS

=over 8

=item B<--id=[id]>

Set au ID.

=item B<--password=[password]>

Set au ID password.

=item B<--macaddress=[mac]>

Set your MAC address. For example, 1234567890AB

=back

=head1 DESCRIPTION

B<This program> will authorize your machine for au Wi-Fi SPOT.

=cut
