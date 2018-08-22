#!/usr/bin/perl -w

=head2
	
APPLICATION 	test.t

PURPOSE

	Test module Virtual::Vagrant
		
=cut

BEGIN
{
    my $installdir = $ENV{'installdir'} || "/a";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/t/common/lib");
    unshift(@INC, "$installdir/t/unit/lib");
}

use Test::More 	tests =>	17;
use Getopt::Long;

use Conf::Yaml;
use FindBin qw($Bin);

BEGIN {
    use_ok('Test::Virtual::Vagrant');
}
require_ok('Test::Virtual::Vagrant');

#### SET CONF FILE
my $installdir          =   $ENV{'installdir'} || "/a";

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
my $object = new Test::Virtual::Vagrant(
	conf		=>	$conf,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
	log			=>	$log,
	printlog    =>  $printlog
);
isa_ok($object, "Test::Virtual::Vagrant", "object");

#### AUTOMATED
#$object->testLaunchNode();
#$object->testParseLaunchOutput();
$object->testParseInstanceList();
#$object->testDeleteNode();
#$object->testInsertKeyValues();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

