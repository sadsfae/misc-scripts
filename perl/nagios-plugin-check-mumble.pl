#! /usr/bin/perl
# Based on weblist.pl distributed with murmur/mumble server
# https://github.com/mumble-voip/mumble/blob/master/scripts/server/dbus/weblist.pl
# Modified from: http://blog.ip.v4.me.uk/mumble-murmur-nagios-plugin/
# Changes: Moved to Monitoring::Plugin to get rid of deprecation warnings
#
# How to Use:
# 1) enable dbus support in murmur
#    e.g. enable "dbus=system" in mumble-server.ini
# 2) add the following DBUS file and restart dbus (reboot perhaps)
#    save this to: /etc/dbus-1/system.d/murmurd.conf
#
#<!DOCTYPE busconfig PUBLIC
# "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
# "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
#<busconfig>
#
#  <policy user="mumble">
#    <allow own="net.sourceforge.mumble.murmur"/>
#  </policy>
#  <policy user="root">
#    <allow own="net.sourceforge.mumble.murmur"/>
#  </policy>
#
#  <policy context="default">
#    <allow send_destination="net.sourceforge.mumble.murmur"/>
#    <allow receive_sender="net.sourceforge.mumble.murmur"/>
#  </policy>
#</busconfig>
# 
# 3) add check to /usr/lib64/nagios/plugins and use via nrpe
#    e.g. command[check_murmur]=/usr/lib64/nagios/plugins/check_murmur

use warnings;
use strict;
use Monitoring::Plugin;
use Net::DBus;
my $np = Monitoring::Plugin->new(  
     usage => "Usage: %s [ -c|--critical=<threshold> ] [ -w|--warning=</threshold><threshold> ]",
);
$np->add_arg(
     spec => 'warning|w=s',
     help => '-w, --warning=INTEGER:INTEGER .  See '
       . 'http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT '
       . 'for the threshold format. ',
   );
$np->add_arg(
     spec => 'critical|c=s',
     help => '-c, --critical=INTEGER:INTEGER .  See '
       . 'http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT '
       . 'for the threshold format. ',
   );
$np->getopts;
my $bus;
my $service;
# First try the system bus
eval {
  $bus=Net::DBus->system();
  $service = $bus->get_service("net.sourceforge.mumble.murmur");
};
# If that failed, the session bus
if (! $service) {
  eval {
    $bus = Net::DBus->session();
    $service = $bus->get_service("net.sourceforge.mumble.murmur");
  }
}
$np->nagios_exit(UNKNOWN, "Murmur service not found in DBUS") if (! $service);
# Fetch handle to remote object
my $object = $service->get_object("/");
# Call a function on the murmur object
my $servers = $object->getBootedServers();
my $params = [];
foreach my $server (@{$servers}) {
  my $name = $object->getConf($server, "registername");
  my $servobj = $service->get_object("/$server");
  my %users;
  # First, get channel names
  my $channels = $servobj->getChannels();
  my %channels;
  foreach my $c (@{$channels}) {
    my @c = @{$c};
    my $id = $c[0];
    my $name = $c[1];
    $channels{$id}=$name;
  }
  # Then, get and print the players
  my $players = $servobj->getPlayers();
  my $_total = 0;
  foreach my $p (@{$players}) {
    my @p = @{$p};
    my $chanid = $p[6];
    my $name = $p[8];
    my $chan = $channels{$chanid};
        $users{$chan} = [] unless $users{$chan};
        push @{$users{$chan}}, $name;
        $_total++;
  }
  my $_channels = [];
  for my $c (sort keys %users) {
        my $_users = [];
                for my $u (sort @{$users{$c}}) {
                        push @{$_users}, {'user' => $u};
                }
        push @{$_channels}, {
                'channel' => $c,
                'users' => $_users
        };
  }
  push @{$params}, {'server' => $server, 'name' => $name, 'total' => $_total, 'channels' => $_channels};
}
$np->add_perfdata( 
     label => "users",
     value => @{$params}[0]->{'total'},
     warning => $np->{'opts'}->{'warning'},
     critical => $np->{'opts'}->{'critical'},
);
my $code = $np->check_threshold(
     check => @{$params}[0]->{'total'},
     warning => $np->{'opts'}->{'warning'},
     critical => $np->{'opts'}->{'critical'},
);
$np->nagios_exit( $code, "" );
</threshold>
