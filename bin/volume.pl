#!/usr/bin/perl -w

BEGIN {
    my $installdir = $ENV{'installdir'} || "/a";
    unshift(@INC, "$installdir/extlib/lib/perl5");
    unshift(@INC, "$installdir/extlib/lib/perl5/x86_64-linux-gnu-thread-multi/");
    unshift(@INC, "$installdir/lib");
}



=head2

APPLICATION 	volume

PURPOSE

	1. Attach or detach volumes on an instance
	
HISTORY

	v0.01	Basic wrappers around nova and cinder API clients

USAGE

$0 <--mode (attach|detach)> <--size Int> <--type (SSD|HD)>

=cut

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";	
BEGIN {
    my $installdir = $ENV{'installdir'} || "/a";
    unshift(@INC, "$installdir/extlib/lib/perl5");
    unshift(@INC, "$installdir/extlib/lib/perl5/x86_64-linux-gnu-thread-multi/");
    unshift(@INC, "$installdir/lib");
}

use lib "/agua/lib";

#### INTERNAL MODULES
use Conf::Yaml;
use Virtual::Openstack;

my $installdir = $ENV{'installdir'} || "/a";
my $configfile	=	"$installdir/conf/config.yml";

my $instanceid;
my $volumeid;
my $mountpoint	=	"/mnt";
my $type		=	"Standard";
my $size;
my $device;
my $mode;
my $log			=	2;
my $printlog	=	2;
my $logfile		=	"/tmp/pancancer-volume.$$.log";
my $help;
GetOptions (
    'mode=s'		=> \$mode,
    'instanceid=s'	=> \$instanceid,
    'volumeid=s'	=> \$volumeid,
    'mountpoint=s'	=> \$mountpoint,
    'type=s'		=> \$type,
    'size=i'		=> \$size,
    'device=s'		=> \$device,
    'log=i'     	=> \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,

    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
);


my $object = Virtual::Openstack->new({
	conf		=>	$conf,
    log			=>	$log,
    printlog	=>	$printlog,
    logfile     =>  $logfile
});

$mode .= "Volume";

$object->$mode($instanceid, $volumeid, $device, $size, $type, $mountpoint);

exit 0;

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}

