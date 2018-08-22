use MooseX::Declare;
=head2

	PACKAGE		Virtual::Openstack
	
    VERSION:        0.01

    PURPOSE
  
        1. UTILITY FUNCTIONS TO ACCESS A MYSQL DATABASE

=cut 

use strict;
use warnings;
use Carp;

#### INTERNAL MODULES
use FindBin qw($Bin);
use lib "$Bin/../../";
use DBase::Main;

class Virtual::Openstack with (Util::Logger, Virtual::Openstack::Nova) {

#### EXTERNAL MODULES
use Conf::Yaml;
use Util::Ssh;


# Ints
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 4 );  
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 2 );

# Strings

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'jsonparser'	=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser"	);
has 'ssh'			=> ( isa => 'Util::Ssh', is => 'rw', lazy	=>	1, builder	=>	"setSsh"	);

####////}}}

method BUILD ($args) {
	$self->initialise($args);
}

method initialise ($args) {
	$self->logNote("");
}

method launchNode ($workobject, $instanceobject, $amiid, $maxnodes, $instancetype, $instancename) {
	$self->logDebug("amiid", $amiid);

	my $authfile = $self->printAuthFile();
 	$self->logDebug("authfile", $authfile);
   
    my $userdatafile    =   $self->printUserDataFile($workobject);
    $self->logDebug("userdatafile", $userdatafile);

    my $keypair         =   $self->conf()->getKey("openstack", "KEYPAIR");
    $self->logDebug("keypair", $keypair);
    
	my $command	=	qq{. $authfile && \\
nova boot \\
--image $amiid \\
--flavor $instancetype \\
--key-name $keypair \\
--user-data $userdatafile \\
$instancename};
	$self->logDebug("command", $command);

	my ($out, $err) 	=	$self->runCommand($command);
	$self->logDebug("out", $out);
	$self->logDebug("err", $err);

	my $id	=	$self->parseNovaBoot($out);
	$self->logDebug("id", $id);
	
	return $id;
}

method getInstallDir ($packagename) {
	$self->logDebug("packagename", $packagename);

	my $packages = $self->conf()->getKey("packages:$packagename", undef);
	$self->logDebug("packages", $packages);
	my $version	=	undef;
	foreach my $key ( %$packages ) {
		$version	=	$key;
		last;
	}

	my $installdir	=	$packages->{$version}->{INSTALLDIR};
	$self->logDebug("installdir", $installdir);
	
	return $installdir;
}

method printUserDataFile ($workobject) {
	$self->logDebug("workobject", $workobject);

	my $package			=	$workobject->{package};
	my $version			=	$workobject->{version};
    $self->logDebug("package", $package);
	$self->logDebug("version", $version);
	
	#### GET PACKAGE INSTALLDIR
	my $installdir		=	$self->getInstallDir($package);
	$self->logDebug("installdir", $installdir);

	#### GET PREDATA AND POSTDATA
	my $predata			=	$self->getPreData($installdir, $version);
	my $postdata		=	$self->getPostData($installdir, $version);
	#$self->logDebug("BEFORE INSERT predata", $predata);
	#$self->logDebug("BEFORE INSERT postdata", $postdata);
    $predata = $self->insertKeyValues($predata);
    $postdata = $self->insertKeyValues($postdata);
	$self->logDebug("AFTER INSERT predata", $predata);
	$self->logDebug("AFTER INSERT postdata", $postdata);

    #### GET USERDATA FILE
	my $userdatafile		= 	$self->getUserDataFile($workobject);
    
	#### GET TEMPLATE
	my $templatefile	=	$self->getTemplateFile($installdir, $version);
	$self->logDebug("templatefile", $templatefile);
	my $template		=	$self->getFileContents($templatefile);
	foreach my $key ( keys %$workobject ) {
		my $templatekey	=	uc($key);
		my $value	=	$workobject->{$key};
		#$self->logDebug("substituting key $key value '$value' into template");
		$template	=~ s/<$templatekey>/$value/msg;
	}

	#### ADD PREDATA AND POSTDATA	
	$template	=~ s/<PREDATA>/$predata/msg if defined $predata;
	$template	=~ s/<POSTDATA>/$postdata/msg if defined $postdata;
	
	# PRINT TEMPLATE
	$self->printToFile($userdatafile, $template);
}

method getUserDataFile ($workobject) {
    $self->logDebug("workobject", $workobject);

	my $package			=	$workobject->{package};
	my $username		=	$workobject->{username};
	my $project			=	$workobject->{project};
	my $workflow		=	$workobject->{workflow};

	my $basedir			=	$self->conf()->getKey("agua", "INSTALLDIR");
    my $targetdir	=	"$basedir/conf/.openstack";
    `mkdir -p $targetdir` if not -d $targetdir;
    my $userdatafile		=	"$targetdir/$username.$project.$workflow.sh";
	$self->logDebug("userdatafile", $userdatafile);
    
    return $userdatafile;
}

method getPreData ($installdir, $version) {
	my $predatafile		=	"$installdir/data/sh/predata";
	$self->logDebug("predatafile", $predatafile);
	
	return "" if not -f $predatafile;
	
	my $predata			=	$self->getFileContents($predatafile);

	return $predata;
}

method getPostData ($installdir, $version) {
	my $postdatafile		=	"$installdir/data/sh/postdata";
	$self->logDebug("postdatafile", $postdatafile);
	
	return "" if not -f $postdatafile;
	
	my $postdata			=	$self->getFileContents($postdatafile);

	return $postdata;
}

method getTemplateFile ($installdir, $version) {
	$self->logDebug("installdir", $installdir);
	
	return "$installdir/data/sh/userdata.sh";
}

method insertKeyValues ($template) {
    $self->logDebug("template", $template);
    
    while ( $template =~ m/%([\S]+?)%/g ) {
        my $match = $1;
        my ($key, $subkey) = $match =~ /^(.+?):(.+)$/;
		my $value = $self->conf()->getKey($key, $subkey);
        
        $template =~ s/%$match%/$value/;
	}
    $self->logDebug("FINAL template", $template);
    
    return $template;
}

method printAuthFile {
	#### GET AUTH FILE
	my $authfile		=	$self->getAuthFile();
    $self->logDebug("authfile", $authfile);
    
    if ( -f $authfile and not -z $authfile ) {
        $self->logDebug("authfile found. Returning");
        return ;
    }
    
	#### SET TEMPLATE FILE	
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $templatefile	=	"$installdir/bin/install/resources/openstack/openrc.sh";
	$self->logNote("templatefile", $templatefile);

	my $template		=	$self->getFileContents($templatefile);
	#$self->logNote("template", $template);

    my $openstack = $self->conf()->getKey("openstack", undef);
    
	foreach my $key ( keys %$openstack ) {
		my $templatekey	=	uc($key);
		my $value	=	$openstack->{$key};
		#$self->logNote("substituting key $key value '$value' into template");
		$template	=~ s/<$templatekey>/$value/msg;
	}
	#$self->logNote("template", $template);
	
	$self->printToFile($authfile, $template);

	return $authfile;
}

method getAuthFile {
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $targetdir		=	"$installdir/conf/.openstack";
    $self->logDebug("targetdir", $targetdir);
	`mkdir -p $targetdir` if not -d $targetdir;

	my $authfile		=	"$targetdir/openrc.sh";
	$self->logDebug("authfile", $authfile);

	return	$authfile;
}


method parseNovaBoot ($output) {
	#$self->logDebug("output", $output);
	my ($id)	=	$output	=~ /\n\|\s+id\s+\|\s+(\S+)/ms;
	#$self->logDebug("id", $id);
	
	return $id;
}

method getNovaList ($authfile) {
	#$self->logDebug("authfile", $authfile);
	
	my $command		=	qq{. $authfile && nova list};
	my ($out, $err)	=	$self->runCommand($command);
	#$self->logDebug("out", $out);
	#$self->logDebug("err", $err);
	
	return $self->parseNovaList($out);
}

method parseNovaList ($output) {
	#$self->logDebug("output", $output);
	return if not defined $output or $output eq "";

	my @lines	=	split "\n", $output;
	my $hash		=	{};
	
	my $columns	=	$self->parseOutputColumns($output);
	foreach my $column ( @$columns ) {
		$column	=	lc($column);
		$column	=~	s/\s+//g;
	}
	#$self->logDebug("columns", $columns);
	
	foreach my $line ( @lines ) {
		next if $line =~ /^\+/ or $line	=~	/^\\|\s+ID/;
		
		my $entries	=	$self->splitOutputLine($line);	
		#$self->logDebug("entries", $entries);
		my $record	=	{};
		for ( my $i = 0; $i < @$columns; $i++ ) {
			$record->{$$columns[$i]}	=	$$entries[$i];
		}
		#$self->logDebug("record", $record);
		my $id	=	$$entries[0];
		$hash->{$id}	= $record;	
	}
	
	return $hash;
}

method parseOutputColumns ($output) {
	$self->logDebug("output", $output);
	my ($line)	=	$output	=~ /^.+?(\|\s+ID[^\n]+)/msg;
	$self->logDebug("line", $line);

	return	$self->splitOutputLine($line);
}

method splitOutputLine ($line) {
	#$self->logDebug("line", $line);
	
	my @entries	=	split "\\|", $line;
	shift @entries;
	foreach my $entry ( @entries ) {
		$entry	=~	s/^\s+//;
		$entry	=~	s/\s+$//;
	}
	#$self->logDebug("entries", \@entries);
	
	return \@entries;	
}

method addNode {
	
	my $nodeid;
	
	return $nodeid;
}

method deleteNode ($host) {
    $self->logDebug("host", $host);
	my $authfile = $self->printAuthFile();
	$self->logDebug("authfile", $authfile);

	my $command		=	qq{. $authfile && nova delete $host};
	my ($out, $err)	=	$self->runCommand($command);
	$self->logNote("out", $out);
	$self->logNote("err", $err);
	
	my $novalist =  $self->parseNovaList($out);
	#my $novalist	=	$self->getNovaList($authfile);
	my $taskstate	=	$novalist->{$host}->{taskstate};	
	$self->logDebug("taskstate", $taskstate);
	
	my $success = 0;
	$success = 1 if not defined $taskstate;
	$success = 1 if defined $taskstate and $taskstate eq "deleting";

	return $success;
}

method getQuotas {
    $self->logDebug("");	
    my $authfile = $self->printAuthFile();
    $self->logDebug("authfile", $authfile); 
    
	my $command	=	". $authfile && nova quota-show";
	$self->logNote("command", $command);
	
	return `$command`;
}

method printToFile ($file, $text) {
	$self->logNote("file", $file);
	$self->logNote("substr text", substr($text, 0, 100));

    open(FILE, ">$file") or die "Can't open file: $file\n";
    print FILE $text;    
    close(FILE) or die "Can't close file: $file\n";
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

method runCommand ($command) {
	$self->logDebug("command", $command);
	my $stdoutfile = "/tmp/$$.out";
	my $stderrfile = "/tmp/$$.err";
	my $output = '';
	my $error = '';
	
	#### TAKE REDIRECTS IN THE COMMAND INTO CONSIDERATION
	if ( $command =~ />\s+/ ) {
		#### DO NOTHING, ERROR AND OUTPUT ALREADY REDIRECTED
		if ( $command =~ /\s+&>\s+/
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>\s+/)
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>&1\s+/) ) {
			return `$command`;
		}
		#### STDOUT ALREADY REDIRECTED - REDIRECT STDERR ONLY
		elsif ( $command =~ /\s+1>\s+/ or $command =~ /\s+>\s+/ ) {
			$command .= " 2> $stderrfile";
			$output		= `$command`;
			$error 		= `cat $stderrfile`;
		}
		#### STDERR ALREADY REDIRECTED - REDIRECT STDOUT ONLY
		elsif ( $command =~ /\s+2>\s+/ or $command =~ /\s+2>&1\s+/ ) {
			$command .= " 1> $stdoutfile";
			print `$command`;
			$output = `cat $stdoutfile`;
		}
	}
	else {
		$command .= " 1> $stdoutfile 2> $stderrfile";
		print `$command`;
		$output = `cat $stdoutfile`;
		$error = `cat $stderrfile`;
	}
	
	$self->logNote("output", $output) if $output;
	$self->logNote("error", $error) if $error;
	
	##### CHECK FOR PROCESS ERRORS
	$self->logError("Error with command: $command ... $@") and exit if defined $@ and $@ ne "" and $self->can('warn') and not $self->warn();

	#### CLEAN UP
	`rm -fr $stdoutfile`;
	`rm -fr $stderrfile`;
	chomp($output);
	chomp($error);
	
	return $output, $error;
}


} #### END



#method getAuthFile ($username, $tenant) {
#	#$self->logDebug("username", $username);
#	
#	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
#	my $targetdir		=	"$installdir/conf/.openstack";
#	`mkdir -p $targetdir` if not -d $targetdir;
#	my $tenantname		=	$tenant->{os_tenant_name};
#	#$self->logDebug("tenantname", $tenantname);
#	my $authfile		=	"$targetdir/$tenantname-openrc.sh";
#	#$self->logDebug("authfile", $authfile);
#
#	return	$authfile;
#}
#
#method getTenant ($username) {
#	my $query	=	qq{SELECT *
#FROM tenant
#WHERE username='$username'};
#	#$self->logDebug("query", $query);
#
#	return $self->db()->queryhash($query);
#}
#
#method getKeypair ($workobject) {
#    $self->logDebug("workobject", $workobject);
#    
#    my $username    =   $workobject->{username};
#    my $tenant		=	$self->getTenant($username);
#	$self->logDebug("tenant", $tenant);
#	
#    return $tenant->{keypair};
#}
#
#method getTenant ($username) {
#	my $query	=	qq{SELECT *
#FROM tenant
#WHERE username='$username'};
#	#$self->logDebug("query", $query);
#
#	return $self->db()->queryhash($query);
#}
