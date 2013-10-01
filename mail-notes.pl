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

sub get_old_ids {
	my $yaml = YAML::Tiny->read("downloaded.yml");
	my @old_ids;

	if (defined $yaml) {
		@old_ids = @{ $yaml->[0] };
	}

	return @old_ids;
}

sub cache {
	my ($ids) = @_;

	my $yaml = YAML::Tiny->new();
	$yaml->[0] = $ids;
	$yaml->write("downloaded.yml");
}

# The main thing.
sub main {
	# Load the config file.
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

	# Get the IDs.
	clog("INFO", "Getting email notes");
	$imap->select("Reminders");
	my @ids = @{ $imap->search("ALL") };

	# Get old IDs and remove them from the new ones.
	my @old_ids = get_old_ids();
	my @new_ids = splice(@ids, $#old_ids + 1);
	print Dumper(\@new_ids);

	# Cache
	cache(\@ids);
}

main();
