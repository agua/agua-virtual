#!/usr/bin/perl -w

=head2
	
APPLICATION 	test.t

PURPOSE

	Test Virtual::Openstack::Nova module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/agua/location

=cut

use Test::More 	tests => 10;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";	#### PACKAGE MODULES
use lib "$Bin/../../../lib";		#### TEST MODULES
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/a";
    unshift(@INC, "$installdir/extlib/lib/perl5");
    unshift(@INC, "$installdir/extlib/lib/perl5/x86_64-linux-gnu-thread-multi/");
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
	use_ok('Test::Virtual::Openstack::Nova');
	use_ok('Test::Virtual::Openstack::Nova::Ips');
}
require_ok('Test::Virtual::Openstack::Nova');
require_ok('Test::Virtual::Openstack::Nova::Ips');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/a";
my $urlprefix  	=   $ENV{'urlprefix'} || "agua";

#### GET OPTIONS
my $logfile 	= 	"$Bin/outputs/gtfuse.log";
my $log     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object1 = new Test::Virtual::Openstack::Nova(
    logfile     =>  $logfile,
	log			=>	$log,
	printlog    =>  $printlog
);
isa_ok($object1, "Test::Virtual::Openstack::Nova", "object1");

#### TESTS
$object1->testParseLine();
$object1->testParseList();
#$object1->testGetExports();
$object1->testParseVolumeId();

my $object2 = new Test::Virtual::Openstack::Nova::Ips(
    logfile     =>  $logfile,
	log			=>	$log,
	printlog    =>  $printlog
);
isa_ok($object2, "Test::Virtual::Openstack::Nova::Ips", "object2");

#### TESTS
$object2->testGetIps();

#### SATISFY Util::Main::Logger::logError CALL TO EXITLABEL
no warnings;
EXITLABEL : {};
use warnings;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

