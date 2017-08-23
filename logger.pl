#!/usr/bin/perl -w
#perl /volume1/homes/git_repos/AutoHome_data-logger/logger.pl
#nohup /volume1/homes/git_repos/AutoHome_data-logger/logger_EG.pl > /volume1/homes/git_repos/AutoHome_data-logger/data_logger.out&

#eintrag in /etc/crontab
#0 * * * * root  perl /volume1/homes/git_repos/AutoHome_data-logger/logger.pl
#restart crontab
#synoservicecfg --restart crond

#=======================
# supportet ARGV:
# "restart" -> restart all logger prozesses
# "kill" -> kill all logger prozesses
# "check" -> verify if $prozess_name is running
# "dbg"
#
#=======================

use strict;
my $log_file = '/volume1/homes/git_repos/AutoHome_data-logger/logger.log';
my $script_name = "logger.pl";

my $logger_EG = "/volume1/homes/git_repos/AutoHome_data-logger/logger_EG.pl";
my $logger_OG = "/volume1/homes/git_repos/AutoHome_data-logger/logger_OG.pl";

sub start_ps{
  my $prozess_name = shift;
  my $dbg = shift;
  if($dbg){ 
    msg("START ps [$prozess_name] in DBG Mode");
    system($prozess_name . " dbg&"); 
  }
  else{ 
    msg("START ps [$prozess_name] with no ARGV");
    system($prozess_name . "&");
  }
  #`nohup /volume1/homes/git_repos/AutoHome_data-logger/logger_EG.pl > /volume1/homes/git_repos/AutoHome_data-logger/logger_EG.out&`;
  sleep(1); #wartezeit damit subscript zeit für zugriff auf logdatei hat
}

sub kill_ps{
  my $prozess_id = shift;
  if($prozess_id){
    `kill $prozess_id`;
    msg( "killed ps ID: [$prozess_id] ");
  }
  #else{
  #  msg( "kill UNDEFINED ID not possible: [$prozess_id] ");
  #}
}

#verify if $prozess_name is running
sub check_ps{
  my $prozess_name = shift;
  my @prozess = `ps -aux`;
  my $ps_id;
  
  if($prozess_name){
    foreach(@prozess) {
      #msg($_);
      if ($_ =~ /$prozess_name/ ) {
        ($ps_id) = $_ =~ m/(\d+)/;
        msg("found ps [".$prozess_name."] with id: [".$ps_id."] total: ".@prozess);
        return $ps_id;
      }
    }
  }else{#kein name übergeben, deshalb ausgabe prozess anzahl
    msg("found total ps: [" . @prozess . "]");
    return 0;
  }
  msg("ps [$prozess_name] not found...");
  return 0;
}

#print $msg to logfile
sub msg{
  my $msg = shift;
  open (my $fh, '>>', $log_file) or die "Kann Datei $log_file nicht zum Schreiben oeffnen: $!\n";
  print $fh "[" . localtime(time) . "] [" . $script_name . "] $msg\n"; 
  close $fh;
}

##############################################################################
################################## main ######################################
##############################################################################
if($ARGV[0]){ msg( "========= start $script_name [$ARGV[0]] ==========="); 
  if($ARGV[0] eq "restart"){
    kill_ps(check_ps($logger_EG));
    kill_ps(check_ps($logger_OG));
    start_ps($logger_EG);
    start_ps($logger_OG);
    check_ps();
  }elsif($ARGV[0] eq "kill"){
    kill_ps(check_ps($logger_EG));
    kill_ps(check_ps($logger_OG));
    check_ps();
  }elsif($ARGV[0] eq "check"){
    check_ps($logger_EG);
    check_ps($logger_OG);
  }elsif($ARGV[0] eq "dbg"){
    kill_ps(check_ps($logger_EG));
    kill_ps(check_ps($logger_OG));
    start_ps($logger_EG, "dbg");
    start_ps($logger_OG, "dbg");
    check_ps();
  }
  else{msg( "argv is not supportet: " . $ARGV[0] );}
}
else{ msg( "========= start $script_name [no ARGVs]  ==========="); 
  #wenn prozess nicht läuft -> starten; ansonsten nix tun
  unless(check_ps($logger_EG)){ start_ps($logger_EG); }
  unless(check_ps($logger_OG)){ start_ps($logger_OG); }
}
  
msg( "============= EXIT $script_name ===============\n");
