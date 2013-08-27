#!/usr/local/bin/perl
# ldap script to bind to LDAP and autocomplete
# users address and names

use strict;
use Net::LDAP;

use constant HOST => 'ldap.you.example.com';
use constant BASE => 'ou=users, dc=example, dc=com';
use constant VERSION => 3;
use constant SCOPE => 'sub';
  
my $name;
my @attributes = qw( dn givenName sn mail );
{
    print "Searching directory... ";
    $name = shift || die "Usage: $0 filter\n";
    my $filter = "(|(sn=$name*)(givenName=$name*))";
    my $ldap = Net::LDAP->new( HOST, onerror => 'die' )
            || die "Cannot connect: $@";

    $ldap->bind(version => VERSION) or die "Cannot bind: $@";

    my $result = $ldap->search( base => BASE,
                            scope => SCOPE,
                            attrs => \@attributes,
                            filter => $filter
                            );

    my @entries = $result->entries;

    $ldap->unbind();

    print scalar @entries, " entries found.\n";

    foreach my $entry ( @entries ) {
        my @emailAddr = $entry->get_value('mail');
        foreach my $addr (@emailAddr) {
            print $addr , "\t";
            print $entry->get_value('givenName'), " ";
            print $entry->get_value('sn'), "\n";
        }
    }
}
