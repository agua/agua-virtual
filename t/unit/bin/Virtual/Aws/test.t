#!/usr/bin/perl -w

=head2
	
APPLICATION 	test.t

PURPOSE

	Test Virtual::Aws module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		source /my/envars.sh
		
	REQUIRED ENVIRONMENT VARIABLES ARE:
	
		ospassword, osauthurl, ostenantid, ostenantname, osusername

=cut

BEGIN
{
    my $installdir = $ENV{'installdir'} || "/a";
    unshift(@INC, "$installdir/extlib/lib/perl5");
    unshift(@INC, "$installdir/extlib/lib/perl5/x86_64-linux-gnu-thread-multi/");
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/t/common/lib");
    unshift(@INC, "$installdir/t/unit/lib");
}

use Test::More 	tests =>	17;
use Getopt::Long;

use Conf::Yaml;
use FindBin qw($Bin);

BEGIN {
    use_ok('Test::Virtual::Aws');
    #use_ok('Test::Virtual::Aws::Nova');
}
require_ok('Test::Virtual::Aws');
#require_ok('Test::Virtual::Aws::Nova');

#### SET CONF FILE
my $installdir          =   $ENV{'installdir'} || "/a";
my $awssecretaccesskey	=	$ENV{'awssecretaccesskey'};
my $awsaccesskeyid	    =	$ENV{'awsaccesskeyid'};
my $keypair		        =	$ENV{'keypair'};

#### SET $Bin
$Bin =~ s/^.+\/unit\/bin/$installdir\/t\/unit\/bin/;

#### GET OPTIONS
my $logfile 	= "$Bin/outputs/test.log";
my $log     	=   2;
my $printlog    =   5;
my $help;
GetOptions (
    'log=i'     	=> \$log,
    'printlog=i'    => \$printlog,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $configfile	=	"$installdir/conf/config.yml";
my $conf	=	Conf::Yaml->new({
	inputfile	=>	$configfile,
	log			=>	$log,
	printlog	=>	$printlog
});


my $dumpfile	=	"$installdir/bin/sql/dump/agua/create-agua.dump";
my $object = new Test::Virtual::Aws(
	conf		=>	$conf,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
	log			=>	$log,
	printlog    =>  $printlog
);
isa_ok($object, "Test::Virtual::Aws", "object");

#### AUTOMATED

## FIX
# $object->testLaunchNode();
# $object->testDeleteNode();

$object->testParseLaunchOutput();
$object->testParseInstanceList();
$object->testInsertKeyValues();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

