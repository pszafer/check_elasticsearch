#!/usr/bin/perl -w
############################## check_elasticsearch ##############
# Short description : Check Elasticsearch health for Icinga2/Nagios
# Version : 0.0.1
# Date :  June 2017
# Author  : Pawel Szafer ( pszafer@gmail.com )
# Help : http://github.com/pszafer/
# Licence : GPL
#################################################################
#
# help : ./check_elasticsearch -h


use Getopt::Long;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Headers;
use JSON;
use URI;
my $json  = JSON->new->utf8;
use Time::Local;
my $mon_dir = "/usr/lib/monitoring-plugins";
if (-d $mon_dir){
	use lib "/usr/lib/monitoring-plugins";
}
else {
	use lib "/usr/lib/nagios/plugins";
}
use utils qw(%ERRORS $TIMEOUT);


my $name = "check_elasticsearch";
my $version = "0.0.1";

sub print_version {
	print "$name version : $version\n";
}

sub print_usage {
	print "Usage: $name [-v] [-h] -H <elasticsearch host> [-P <port>] [-t <timeout>] [-s]\n";
}

sub help {
	print_usage();
	print <<EOT;
	This plugin is intended to use with NRPE - Nagios/Icinga to check Elasticsearch cluster status.
	Required parameters:
		-H target host/computer FQDN to check. 
		-P port of elasticsearch API, default 9200
		-s indicate that this is single node, so yellow status for you is still good health of elasticsearch.
EOT
}

my %OPTION = (
	'help' => undef,
	'verbose' => -1,
	'elasticsearch' => undef,
	'port' => 9200,
	'singlenode' => undef
);

sub check_options {
	Getopt::Long::Configure("bundling");
	GetOptions(
		'v' => \$OPTION{verbose},	'verbose'	=> \$OPTION{verbose},
		'h' => \$OPTION{help},		'help'		=> \$OPTION{help},
		'V' => \$OPTION{version},	'version'	=> \$OPTION{version},
		's' => \$OPTION{singlenode},	'single'	=> \$OPTION{singlenode},
		'H:s' => \$OPTION{host},	'host:s'	=> \$OPTION{host},
		'P:i'	=> \$OPTION{port},	'port:i'	=> \$OPTION{port},
	);

	if (defined($OPTION{help})){ print "help";
	      print $OPTION{help};	
		help();
		exit $ERRORS{"UNKNOWN"};
	}
	if (defined($OPTION{version})) {
		print_version();
		exit $ERRORS{"UNKNOWN"};
	}
	my $print_usage = 0;
	if (
		(!defined($OPTION{host}))
	   )
	{
		$print_usage = 1;
	}
	if ($print_usage) {
		print "Not all options are defined\n";
		print_usage();
		exit $ERRORS{"UNKNOWN"};
	}
	
}

check_options();
my $elasticsearch_health_url = 'http://'.$OPTION{host}.":".$OPTION{port}."/_cluster/health";
my $request = HTTP::Request->new('GET', $elasticsearch_health_url);
my $ua = LWP::UserAgent->new;
my $response = $ua->request($request);
$response->is_success or die($response->status_line);


my $cluster_state = $json->decode($response->decoded_content);
my $status = $cluster_state->{status};
if (uc $status eq 'GREEN'){
	print "Elasticsearch cluster $cluster_state->{cluster_name} is OK, status $status\n";
	exit $ERRORS{"OK"};
}
elsif (uc $status eq 'YELLOW') {
	if (defined $OPTION{singlenode}) {
		print "Elasticsearch cluster $cluster_state->{cluster_name} is OK, status $status, but it is normal for single node\n";
		exit $ERRORS{'OK'};
	}
	else {
		print "Elasticsearch cluster $cluster_state->{cluster_name} is WARNING, status $status\n";
		exit $ERRORS{'WARNING'};
	}
}
elsif (uc $status eq 'RED') {
	print "Elasticsearch cluster $cluster_state->{cluster_name} is CRITICAL, status $status\n";
	exit $ERRORS{'CRTICAL'};
}
else {
	print "Elasticsearch cluster $cluster_state->{cluster_name} is UNKNOWN, status read is $status\n";
	exit $ERRORS{'UNKNOWN'};
}
