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

# Simple logging function.
sub clog {
	my ($cat, $msg) = @_;
	print "[$cat] $msg\n";
}

# Get old IDs.
sub get_old_ids {
	my $yaml = YAML::Tiny->read("downloaded.yml");
	my @old_ids;

	if (defined $yaml) {
		@old_ids = @{ $yaml->[0] };
	}

	return @old_ids;
}

# Cache.
sub cache {
	my ($ids) = @_;

	my $yaml = YAML::Tiny->new();
	$yaml->[0] = $ids;
	$yaml->write("downloaded.yml");
}

# Save the note.
sub save_note {
	my ($subject, $body) = @_;
	my $filename = "notes/$subject.md";

	clog("INFO", "Saving note: $subject");

	open(my $file, ">", $filename) or warn "Cannot open $filename: $!";
	print $file "# $subject\n\n$body";
	close($file);
}

# Everything.
sub process {
	my ($imap) = @_;

	# Get the IDs.
	clog("INFO", "Getting notes");
	$imap->select("Reminders");
	my @ids = @{ $imap->search("ALL") };
	my @new_ids = @ids;

	# Get old IDs and remove them from the new ones.
	my @old_ids = get_old_ids();
	@new_ids = splice(@new_ids, $#old_ids + 1);

	clog("INFO", "Getting more info");
	my $summs_ref = $imap->get_summaries([ @new_ids ]);
	if (defined $summs_ref) {
		my @summs = @{ $summs_ref };
		for (my $i = 0; $i < $#summs + 1; $i++) {
			my $email = $summs[$i];
			my $subject = $email->{"subject"};

			# Get and decode the body.
			my $body = ${ $imap->get_part_body($new_ids[$i], "TEXT") };
			$body =~ s/=\r\n//g;

			# Save the email.
			save_note($subject, $body);
			
		}
	} else {
		clog("INFO", "No new messages.");
	}

	# Cache
	cache(\@ids);
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

	# Do it!
	process($imap);
}

main();
