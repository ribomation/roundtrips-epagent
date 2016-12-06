#!/usr/bin/env perl
use strict;

my $epaDir       = '.';
my $agentsFile   = "$epaDir/agents.csv";
my $paramsFile   = "$epaDir/parameters.conf";
my $templateFile = "$epaDir/lib/agent.properties";
my $runDir       = "$epaDir/run";

my %params   = loadParams($paramsFile);
my $apmHost  = $params{'apm.host'};
my $apmPort  = $params{'apm.port'};
my $heapSize = $params{'heap.size'};

init();

open AGENTS, $agentsFile or die "cannot open $agentsFile\n";
while (<AGENTS>) {
  next if /^#/;
  chomp;
  my ($name, $dir, $pattern) = split /\s+/;
  
  my $cfgFile = "$runDir/$name.conf";
  my $pidFile = "$runDir/$name.pid";  
  my $cfg     = populate(load($templateFile), $name, $dir, $pattern); 
  store($cfgFile, $cfg);
  
  my $cmd = 'nohup java ' . epaArgs($cfgFile) . '> /dev/null 2>&1  & echo $! > ' . $pidFile;
  system $cmd;
  
  my $pid = `cat $pidFile`; chomp $pid;
  print "Started Roundtrip EPA $name [$pid]\n";
}
close AGENTS;


# -------------------------------------------
sub populate {
  my ($txt, $name, $dir, $pattern) = @_;
  
  $txt =~ s/\{\{NAME\}\}/$name/g;
  $txt =~ s/\{\{WEB_LOG_DIR\}\}/$dir/g;
  $txt =~ s/\{\{WEB_LOG_PATTERN\}\}/$pattern/g;
  $txt =~ s/\{\{APM_HOST\}\}/$apmHost/g;
  $txt =~ s/\{\{APM_PORT\}\}/$apmPort/g;
  $txt =~ s/\{\{EPA_DIR\}\}/$epaDir/g;

  return $txt;
}

sub epaArgs {
  my ($file) = @_;
  my @args = (
    "-Xms${heapSize}",
    "-Xmx${heapSize}",
    "-classpath $epaDir/lib/EPAgent.jar",
    "-Dcom.wily.introscope.epagent.properties=$file",
    "com.wily.introscope.api.IntroscopeEPAgent"
  );
  return join ' ', @args;
}

sub load {
  my ($filename) = @_;
  open FH, $filename or die "cannot open $filename: $!\n";
  my @txt = <FH>;
  close FH;
  return "@txt";
}

sub loadParams {
    my ($file) = @_;
    my %data;
    open FH, $file or die "cannot open $file: $!\n";
    while (<FH>) {
        chomp;
        my ($key, $value) = split /\s*=\s*/;
        $data{$key} = $value;
    }
    close FH;
    return %data;
}

sub store {
  my ($filename, $txt)  = @_;
  open FH, ">$filename" or die "cannot open $filename: $!\n";
  print FH $txt;
  close FH;
}

sub init {
  my @pids = `ls $runDir/*.pid 2> /dev/null`;
  die "Might be running EP Agents that must be stopped first:\n@pids\n" if @pids;

  my $javaExe = `which java`; chomp $javaExe;
  die "Missing java exe" unless -x $javaExe;
  
  my $nohupExe = `which nohup`; chomp $nohupExe;
  die "Missing nohup exe" unless -x $nohupExe;
  
  `mkdir -p $runDir/ext`;
}
