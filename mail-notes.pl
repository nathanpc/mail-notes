#!/usr/bin/perl -w

# mail-notes.pl
#
# A simple script to organize all those emails you send to yourself.

use strict;
use warnings;
use Data::Dumper;

use YAML::Tiny;
use IO::Socket::SSL;
use Net::SSLeay;
use Net::IMAP::Client;

sub clog {
	my ($cat, $msg) = @_;
	print "[$cat] $msg\n";
}

# The main thing.
sub main {
	my $config = YAML::Tiny->read("config.yml")->[0];

	# Connect.
	clog("INFO", "Connecting to " . $config->{"host"} . ":" . $config->{"port"} . "...");
	my $imap = Net::IMAP::Client->new(
		server => $config->{"host"},
		port   => $config->{"port"},
		user   => $config->{"username"},
		pass   => $config->{"password"},
		ssl    => 1
	) or die "Unable to connect to IMAP server";

	# Log in.
	clog("INFO", "Logging in as " . $config->{"username"});
	$imap->login() or die "Failed to login";

	clog("INFO", "Getting email notes");
	my $search = $imap->search({
		FROM => "eeepc904\@gmail.com"
	}, [ "DATE" ]);

	print Dumper($search);
}

main();
