#!/usr/bin/perl -w

# mail-notes.pl
#
# A simple script to organize all those emails you send to yourself.

use strict;
use warnings;
use Data::Dumper;

use YAML::Tiny;
use Net::IMAP::Simple;

sub clog {
	my ($cat, $msg) = @_;
	print "[$cat] $msg\n";
}

# The main thing.
sub main {
	my $config = YAML::Tiny->read("config.yml")->[0];

	# Connect.
	clog("INFO", "Connecting to " . $config->{"host"} . ":" . $config->{"port"} . "...");
	my $imap = Net::IMAP::Simple->new($config->{"host"},
									  port => $config->{"port"},
									  use_ssl => 1) ||
										  die "Unable to connect: $Net::IMAP::Simple::errstr\n";

	# Log in.
	clog("INFO", "Logging in as " . $config->{"username"});
	if (!$imap->login($config->{"username"}, $config->{"password"})) {
		die "Login failed: $imap->errstr\n";
	}

	clog("INFO", "Getting email notes");
	my @ids = $imap->search("FROM \"eeepc904\@gmail.com\"");
	print Dumper(\@ids);
}

main();
