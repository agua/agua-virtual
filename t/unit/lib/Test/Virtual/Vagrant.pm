use MooseX::Declare;


#### EXTERNAL MODULES

class Test::Virtual::Vagrant extends Virtual::Vagrant with Mock::Base {

use FindBin qw($Bin);
use Test::More;

####////}}}

method BUILD ($args) {
	$self->initialise($args);
}

method testParseInstanceList {
	diag("parseInstanceList");

	my $tests	=	[
		{
			inputfile	=>	"$Bin/inputs/describe-instances.json",
			id			=>	"i-2a067cc5",
			expected	=>	"running",
			configfile	=>	"$Bin/inputs/config.yml"
		}
	];
	
	

    my $basedir         =   $self->conf()->getKey("vagrant", "BASEDIR");
	$self->logDebug("basedir", $basedir);

	foreach my $test ( @$tests ) {
		my $inputfile	=	$test->{inputfile};
		my $expected	=	$test->{expected};
		my $id			=	$test->{id};
		my $configfile	=	$test->{configfile};
		
		#### SET CONFIG FILE
		$self->conf()->inputfile($configfile);
		my $basedir = $self->conf()->getKey("vagrant", "BASEDIR");
		$self->logDebug("basedir", $basedir);
		
		#$self->conf()->memory(1);
		
		$self->conf()->memory(0);
		#$self->conf()->setKey("vagrant", "BOXES", ["u1404", "u1204"]);
		
		$self->conf()->setKey("vagrant:BOXES", "u1404");
		my $boxes = $self->conf()->getKey("vagrant", "BOXES");
		$self->logDebug("boxes", $boxes);
	
$self->logDebug("DEBUG EXIT") and exit;
	
		my $output		=	$self->getFileContents($inputfile);
		#$self->logDebug("output", $output);
		
		my $hash		=	$self->parseInstanceList($output);
		#$self->logDebug("hash", $hash);
	
		my $taskstate		=	$hash->{$id}->{State}->{Name};
		$self->logDebug("taskstate", $taskstate);
	
		ok($taskstate eq $expected, "parsed instance list for instanceid: $id");
	}
}

#method testCreateBootscript {
#	diag("printBootscript");
#	
#	my $tests = [
#		{
#			name			=>	"basic AWS credentials",
#			predatafile		=>	"$Bin/inputs/predata",
#			keys 			=> {
#				AWSSECRETACCESSKEY => "*****MYAWSSECRETACCESSKEY*****",
#				AWSACCESSKEYID => "*****MYACCESSKEYID*****"
#			},
#			expectedfile	=>	"$Bin/inputs/predata-expected"
#		}
#	];
#	
#	foreach my $test ( @$tests ) {
#		my $name			=	$test->{name};
#		my $predatafile		=	$test->{predatafile};
#		my $keys			=	$test->{keys};
#		my $expectedfile	=	$test->{expectedfile};
#
#		#### SET KEYS
#		$self->conf()->memory(1);
#		foreach my $key ( keys %$keys ) {
#			$self->conf()->setKey("aws", $key, $keys->{$key});
#		}
#		
#		#### GET TEMPLATE
#		my $predata = $self->getFileContents($predatafile);
#		$self->logDebug("predata", $predata);
#		
#		#### RUN
#		my $actual = $self->printBootscript($predata);
#		$self->logDebug("actual", $actual);
#		
#		#### GET EXPECTED
#		my $expected = $self->getFileContents($expectedfile);
#		$self->logDebug("expected", $expected);
#		
#		ok($actual eq $expected, $name);
#	}
#}
#
#method testLaunchNode {
#	diag("launchNode");
#
#	my $tests = [
#		{
#			name			=>	"launched instance",
#			amiid			=>	"ami-909e86f8",
#			userdatafile	=>	"$Bin/inputs/userdata.sh",
#			maxnodes 		=>	1,
#			instancename	=>	"testnode-ami-909e86f8",
#			instancetype	=>	"m1.medium"
#		}
#	];
#	
#	foreach my $test ( @$tests ) {
#		
#		my $name			=	$test->{name};
#		my $amiid			=	$test->{amiid};
#		my $maxnodes		=	$test->{maxnodes};
#		my $userdatafile	=	$test->{userdatafile};
#		my $instancename	=	$test->{instancename};
#		my $instancetype	=	$test->{instancetype};
#
#		#### LAUNCH NODE
#		my $instanceid	=	$self->launchNode($amiid, $maxnodes, $instancetype, $userdatafile, $instancename);
#		$self->logDebug("instanceid", $instanceid);
#
#		my $success	=	0;
#		$success	=	1 if defined $instanceid;
#		$success	=	0 if not $instanceid =~ /^[0-9a-z\-]+$/;
#		
#		ok($success, "$name: $instanceid");
#
#		#### CLEAN UP
#		$self->deleteNode($instanceid);
#	}
#}	
#
#method testParseLaunchOutput {
#	diag("parseLaunchOutput");
#	
#	my $tests		=	[
#		{
#			output		=>	qq{{
#    "OwnerId": "033446408444", 
#    "ReservationId": "r-044405d3", 
#    "Groups": [
#        {
#            "GroupName": "default", 
#            "GroupId": "sg-974856fe"
#        }
#    ], 
#    "Instances": [
#        {
#            "Monitoring": {
#                "State": "disabled"
#            }, 
#            "PublicDnsName": "", 
#            "KernelId": "aki-919dcaf8", 
#            "State": {
#                "Code": 0, 
#                "Name": "pending"
#            }, 
#            "EbsOptimized": false, 
#            "LaunchTime": "2015-08-27T21:24:38.000Z", 
#            "ProductCodes": [], 
#            "StateTransitionReason": "", 
#            "InstanceId": "i-ddbbe876", 
#            "ImageId": "ami-909e86f8", 
#            "PrivateDnsName": "", 
#            "KeyName": "bioinfo1", 
#            "SecurityGroups": [
#                {
#                    "GroupName": "default", 
#                    "GroupId": "sg-974856fe"
#                }
#            ], 
#            "ClientToken": "", 
#            "InstanceType": "m1.medium", 
#            "NetworkInterfaces": [], 
#            "Placement": {
#                "Tenancy": "default", 
#                "GroupName": "", 
#                "AvailabilityZone": "us-east-1c"
#            }, 
#            "Hypervisor": "xen", 
#            "BlockDeviceMappings": [], 
#            "Architecture": "x86_64", 
#            "StateReason": {
#                "Message": "pending", 
#                "Code": "pending"
#            }, 
#            "RootDeviceName": "/dev/sda1", 
#            "VirtualizationType": "paravirtual", 
#            "RootDeviceType": "ebs", 
#            "AmiLaunchIndex": 0
#        }
#    ]
#}},
#			expected	=>	"i-ddbbe876"
#		}
#	];
#	
#	foreach my $test ( @$tests ) {
#		my $output		=	$test->{output};
#		my $expected	=	$test->{expected};
#		my $id	=	$self->parseLaunchOutput($output);
#		ok($id eq $expected, "parsed launch output for instanceid: $id");
#	}
#}
#
#method testDeleteNode {
#	diag("deleteNode");
#	
#	use FindBin qw($Bin);
#	use Test::More;
#
#	my $tests = [
#		{
#			name			=>	"deleted instance",
#			amiid			=>	"ami-909e86f8",
#			userdatafile	=>	"$Bin/inputs/userdata.sh",
#			maxnodes 		=>	1,
#			instancename	=>	"testnode-ami-909e86f8",
#			instancetype	=>	"m1.medium"
#		}
#	];
#	
#	foreach my $test ( @$tests ) {
#		
#		my $name			=	$test->{name};
#		my $amiid			=	$test->{amiid};
#		my $maxnodes		=	$test->{maxnodes};
#		my $userdatafile	=	$test->{userdatafile};
#		my $instancename	=	$test->{instancename};
#		my $instancetype	=	$test->{instancetype};
#
#		#### LAUNCH NODE
#		my $instanceid	=	$self->launchNode($amiid, $maxnodes, $instancetype, $userdatafile, $instancename);
#		$self->logDebug("instanceid", $instanceid);
#		
#		sleep($self->sleep());
#		
#		$self->deleteNode($instanceid);
#		my $success = $self->deleteNode($instanceid);
#		$self->logDebug("success", $success);		
#		
#		ok($success, "$name: $instanceid");
#	}
#	
#}
#
#method getFileContents ($file) {
#	$self->logNote("file", $file);
#	open(FILE, $file) or $self->logCritical("Can't open file: $file") and exit;
#	my $temp = $/;
#	$/ = undef;
#	my $contents = 	<FILE>;
#	close(FILE);
#	$/ = $temp;
#
#	return $contents;
#}


method clearInput {
	$self->inputs([]);
}

method clearOutput {
	$self->outputs([]);
}

method returnInput {
	return splice($self->inputs(), 0, 1);
}

method returnOutput {
	return splice($self->outputs(), 0, 1);
}

} #### END


