use MooseX::Declare;


#### EXTERNAL MODULES

class Test::Virtual::Aws extends Virtual::Aws {

####////}}}

use FindBin qw($Bin);
use Test::More;

method BUILD ($args) {
	$self->initialise($args);
}


method testParseLaunchOutput {
	diag("parseLaunchOutput");

	my $tests = [
		{
			name		=>	"IAM-launched",
			expected	=>	"i-f0bc0174",
			outputfile	=>	"inputs/run-instances1.json"
		}
		,
		{
			name		=>	"ID-launched",
			expected	=>	"i-ddbbe876",
			outputfile	=>	"inputs/run-instances2.json"
		}

	];
	
	foreach my $test ( @$tests ) {		
		my $name			=	$test->{name};
		my $expected		=	$test->{expected};
		my $outputfile		=	$test->{outputfile};

		#### GET TEMPLATE
		my $output = $self->getFileContents($outputfile);
		$self->logDebug("outputfile", $outputfile);

		#### SETUP
		my $actual		=	$self->parseLaunchOutput($output);
		$self->logDebug("actual", $actual);
		$self->logDebug("expected", $expected);

		#### TEST
		ok($actual eq $expected, $name);

		#### CLEAN UP
	}
}	



method testInsertKeyValues {
	diag("insertKeyValues");
	
	my $tests = [
		{
			name			=>	"basic AWS credentials",
			predatafile		=>	"$Bin/inputs/predata",
			keys 			=> {
				AWSSECRETACCESSKEY => "*****MYAWSSECRETACCESSKEY*****",
				AWSACCESSKEYID => "*****MYACCESSKEYID*****"
			},
			expectedfile	=>	"$Bin/inputs/predata-expected"
		}
	];
	
	foreach my $test ( @$tests ) {
		my $name			=	$test->{name};
		my $predatafile		=	$test->{predatafile};
		my $keys			=	$test->{keys};
		my $expectedfile	=	$test->{expectedfile};

		#### SET KEYS
		$self->conf()->memory(1);
		foreach my $key ( keys %$keys ) {
			$self->conf()->setKey("aws", $key, $keys->{$key});
		}
		
		#### GET TEMPLATE
		my $predata = $self->getFileContents($predatafile);
		$self->logDebug("predata", $predata);
		
		#### RUN
		my $actual = $self->insertKeyValues($predata);
		$self->logDebug("actual", $actual);
		
		#### GET EXPECTED
		my $expected = $self->getFileContents($expectedfile);
		$self->logDebug("expected", $expected);
		
		ok($actual eq $expected, $name);
	}
}

method testLaunchNode {
	diag("launchNode");

	my $tests = [
		{
			name			=>	"launched instance",
			amiid			=>	"ami-909e86f8",
			userdatafile	=>	"$Bin/inputs/userdata.sh",
			maxnodes 		=>	1,
			instancename	=>	"testnode-ami-909e86f8",
			instancetype	=>	"m1.medium",
			workobject	=>	{ 
				package	=>	"test",
				version =>	"0.0.1"
			},
			instanceobject	=>	{ 
				disk 	=>	1000
			}
		}
	];
	
	foreach my $test ( @$tests ) {

		no warnings;
		*Virtual::Aws::printAuthFile = sub {
			print "OVERRIDE Virtual::Aws::printAuthFile\n";
			return 1;
		};
		*Virtual::Aws::printUserDataFile = sub {
			print "OVERRIDE Virtual::Aws::printUserDataFile\n";
			return 1;
		};
		*Virtual::Aws::printMappingFile = sub {
			print "OVERRIDE Virtual::Aws::printMappingFile\n";
			return 1;
		};
		use warnings;
		
		my $name			=	$test->{name};
		my $amiid			=	$test->{amiid};
		my $maxnodes		=	$test->{maxnodes};
		my $userdatafile	=	$test->{userdatafile};
		my $instancename	=	$test->{instancename};
		my $instancetype	=	$test->{instancetype};
		my $workobject		=	$test->{workobject};
		my $instanceobject	=	$test->{instanceobject};

		#### LAUNCH NODE
		my $instanceid	=	$self->launchNode($workobject, $instanceobject, $amiid, $maxnodes, $instancetype, $instancename);
		$self->logDebug("instanceid", $instanceid);

		my $success	=	0;
		$success	=	1 if defined $instanceid;
		$success	=	0 if not $instanceid =~ /^[0-9a-z\-]+$/;
		
		ok($success, "$name: $instanceid");

		#### CLEAN UP
		$self->deleteNode($instanceid);
	}
}	

# method testParseLaunchOutput {
# 	diag("parseLaunchOutput");
	
# 	my $tests		=	[
# 		{
# 			output		=>	qq{{
#     "OwnerId": "033446408444", 
#     "ReservationId": "r-044405d3", 
#     "Groups": [
#         {
#             "GroupName": "default", 
#             "GroupId": "sg-974856fe"
#         }
#     ], 
#     "Instances": [
#         {
#             "Monitoring": {
#                 "State": "disabled"
#             }, 
#             "PublicDnsName": "", 
#             "KernelId": "aki-919dcaf8", 
#             "State": {
#                 "Code": 0, 
#                 "Name": "pending"
#             }, 
#             "EbsOptimized": false, 
#             "LaunchTime": "2015-08-27T21:24:38.000Z", 
#             "ProductCodes": [], 
#             "StateTransitionReason": "", 
#             "InstanceId": "i-ddbbe876", 
#             "ImageId": "ami-909e86f8", 
#             "PrivateDnsName": "", 
#             "KeyName": "bioinfo1", 
#             "SecurityGroups": [
#                 {
#                     "GroupName": "default", 
#                     "GroupId": "sg-974856fe"
#                 }
#             ], 
#             "ClientToken": "", 
#             "InstanceType": "m1.medium", 
#             "NetworkInterfaces": [], 
#             "Placement": {
#                 "Tenancy": "default", 
#                 "GroupName": "", 
#                 "AvailabilityZone": "us-east-1c"
#             }, 
#             "Hypervisor": "xen", 
#             "BlockDeviceMappings": [], 
#             "Architecture": "x86_64", 
#             "StateReason": {
#                 "Message": "pending", 
#                 "Code": "pending"
#             }, 
#             "RootDeviceName": "/dev/sda1", 
#             "VirtualizationType": "paravirtual", 
#             "RootDeviceType": "ebs", 
#             "AmiLaunchIndex": 0
#         }
#     ]
# }},
# 			expected	=>	"i-ddbbe876"
# 		}
# 	];
	
# 	foreach my $test ( @$tests ) {
# 		my $output		=	$test->{output};
# 		my $expected	=	$test->{expected};
# 		my $id	=	$self->parseLaunchOutput($output);
# 		ok($id eq $expected, "parsed launch output for instanceid: $id");
# 	}
# }

method testParseInstanceList {
	diag("parseInstanceList");

	my $tests	=	[
		{
			inputfile	=>	"$Bin/inputs/describe-instances.json",
			id			=>	"i-2a067cc5",
			expected	=>	"running"
		}
	];

	foreach my $test ( @$tests ) {
		my $inputfile	=	$test->{inputfile};
		my $expected	=	$test->{expected};
		my $id			=	$test->{id};
	
		my $output		=	$self->getFileContents($inputfile);
		#$self->logDebug("output", $output);
		
		my $hash		=	$self->parseInstanceList($output);
		#$self->logDebug("hash", $hash);

		my $taskstate		=	$hash->{$id}->{State}->{Name};
		$self->logDebug("taskstate", $taskstate);

		ok($taskstate eq $expected, "parsed instance list for instanceid: $id");
	}
}

method testDeleteNode {
	diag("deleteNode");
	
	use FindBin qw($Bin);
	use Test::More;

	my $tests = [
		{
			name			=>	"deleted instance",
			amiid			=>	"ami-909e86f8",
			userdatafile	=>	"$Bin/inputs/userdata.sh",
			maxnodes 		=>	1,
			instancename	=>	"testnode-ami-909e86f8",
			instancetype	=>	"m1.medium"
		}
	];
	
	foreach my $test ( @$tests ) {
		
		my $name			=	$test->{name};
		my $amiid			=	$test->{amiid};
		my $maxnodes		=	$test->{maxnodes};
		my $userdatafile	=	$test->{userdatafile};
		my $instancename	=	$test->{instancename};
		my $instancetype	=	$test->{instancetype};

		#### LAUNCH NODE
		my $instanceid	=	$self->launchNode($amiid, $maxnodes, $instancetype, $userdatafile, $instancename);
		$self->logDebug("instanceid", $instanceid);
		
		sleep($self->sleep());
		
		$self->deleteNode($instanceid);
		my $success = $self->deleteNode($instanceid);
		$self->logDebug("success", $success);		
		
		ok($success, "$name: $instanceid");
	}
	
}

method getFileContents ($file) {
	$self->logNote("file", $file);
	open(FILE, $file) or $self->logCritical("Can't open file: $file") and exit;
	my $temp = $/;
	$/ = undef;
	my $contents = 	<FILE>;
	close(FILE);
	$/ = $temp;

	return $contents;
}

} #### END


