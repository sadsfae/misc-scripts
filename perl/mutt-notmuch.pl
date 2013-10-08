#!/usr/bin/perl -w
#
# mutt-notmuch - notmuch (of a) helper for Mutt
#
# Copyright: © 2011 Stefano Zacchiroli <zack@upsilon.cc> 
# License: GNU General Public License (GPL), version 3 or above
#
# See the bottom of this file for more documentation.
# A manpage can be obtained by running "pod2man mutt-notmuch > mutt-notmuch.1"

use strict;
use warnings;

use File::Path;
use Getopt::Long;
use Mail::Internet;
use Mail::Box::Maildir;
use Pod::Usage;


# create an empty maildir (if missing) or empty an existing maildir"
sub empty_maildir($) {
    my ($maildir) = (@_);
    rmtree($maildir) if (-d $maildir);
    my $folder = new Mail::Box::Maildir(folder => $maildir,
					create => 1);
    $folder->close();
}

# search($maildir, $query)
# search mails according to $query with notmuch; store results in $maildir
sub search($$) {
    my ($maildir, $query) = @_;

    empty_maildir($maildir);
    system("notmuch search --output=files $query"
	   . " | xargs --no-run-if-empty ln -s -t $maildir/cur/");
}

sub search_action($$@) {
    my ($interactive, $results_dir, @params) = @_;

    if (! $interactive) {
	search($results_dir, join(' ', @params));
    } else {
	my $query = "";
	my $done = 0;
	while (! $done) {
	    print "search ('?' for man): ";
	    chomp($query = <STDIN>);
	    if ($query eq "?") {
		system("man notmuch");
	    } elsif ($query eq "") {
		$done = 1;	# quit doing nothing
	    } else {
		search($results_dir, $query);
		$done = 1;
	    }
	}
    }
}

sub thread_action(@) {
    my ($results_dir, @params) = @_;

    my $mail = Mail::Internet->new(\*STDIN);
    $mail->head->get('message-id') =~ /^<(.*)>$/;	# get message-id
    my $mid = $1;
    my $tid = `notmuch search --output=threads id:$mid`;# get thread id
    chomp($tid);

    search($results_dir, $tid);
}

sub die_usage() {
    my %podflags = ( "verbose" => 1,
		    "exitval" => 2 );
    pod2usage(%podflags);
}

sub main() {
    my $results_dir = "$ENV{HOME}/.cache/mutt_results";
    my $interactive = 0;
    my $help_needed = 0;

    my $getopt = GetOptions(
	"h|help" => \$help_needed,
	"o|output-dir=s" => \$results_dir,
	"p|prompt" => \$interactive);
    if (! $getopt || $#ARGV < 0) { die_usage() };
    my ($action, @params) = ($ARGV[0], @ARGV[1..$#ARGV]);

    if ($help_needed) {
	die_usage();
    } elsif ($action eq "search" && $#ARGV == 0 && ! $interactive) {
	print STDERR "Error: no search term provided\n\n";
	die_usage();
    } elsif ($action eq "search") {
	search_action($interactive, $results_dir, @params);
    } elsif ($action eq "thread") {
	thread_action($results_dir, @params);
    } else {
	die_usage();
    }
}

main();

__END__

=head1 NAME

mutt-notmuch - notmuch (of a) helper for Mutt

=head1 SYNOPSIS

=over

=item B<mutt-notmuch> [I<OPTION>]... search [I<SEARCH-TERM>]...

=item B<mutt-notmuch> [I<OPTION>]... thread < I<MAIL>

=back

=head1 DESCRIPTION

mutt-notmuch is a frontend to the notmuch mail indexer capable of populating
maildir with search results.

=head1 OPTIONS

=over 4

=item -o DIR

=item --output-dir DIR

Store search results as (symlink) messages under maildir DIR. Beware: DIR will
be overwritten. (Default: F<~/.cache/mutt_results/>)

=item -p

=item --prompt

Instead of using command line search terms, prompt the user for them (only for
"search").

=item -h

=item --help

Show usage information and exit.

=back

=head1 INTEGRATION WITH MUTT

mutt-notmuch can be used to integrate notmuch with the Mutt mail user agent
(unsurprisingly, given the name). To that end, you should define the following
macros in your F<~/.muttrc> (replacing F<~/bin/mutt-notmuch> for the actual
location of mutt-notmuch on your system):

    macro index <F8> \
          "<enter-command>unset wait_key<enter><shell-escape>~/bin/mutt-notmuch --prompt search<enter><change-folder-readonly>~/.cache/mutt_results<enter>" \
          "search mail (using notmuch)"
    macro index <F9> \
          "<enter-command>unset wait_key<enter><pipe-message>~/bin/mutt-notmuch thread<enter><change-folder-readonly>~/.cache/mutt_results<enter><enter-command>set wait_key<enter>" \
          "search and reconstruct owning thread (using notmuch)"

The first macro (activated by <F8>) will prompt the user for notmuch search
terms and then jump to a temporary maildir showing search results. The second
macro (activated by <F9>) will reconstruct the thread corresponding to the
current mail and show it as search results.

To keep notmuch index current you should then periodically run C<notmuch
new>. Depending on your local mail setup, you might want to do that via cron,
as a hook triggered by mail retrieval, etc.

=head1 SEE ALSO

mutt(1), notmuch(1)

=head1 AUTHOR

Copyright: (C) 2011 Stefano Zacchiroli <zack@upsilon.cc>

License: GNU General Public License (GPL), version 3 or higher

=cut

