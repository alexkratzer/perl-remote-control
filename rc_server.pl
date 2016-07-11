#!/usr/bin/perl -w

#*******************************************************************************
# 
# Version: 	V0.0.1
# Scriptname: rc_server.pl
#
# Skriptbeschreibung:
# Es wird am wlan0 Interface an Port 13000 Anfragen entgegengenommen,
# als paralleler Prozess bearbeitet und die Ausgabe wieder an den
# client zurückgeschickt.
#
# Hinweis:
# zum Autostart einen Eintrag in /etc/rc.local ergänzen z.b.:
# /home/pi/rc_server.pl &
# das Skript muss ausführbar sein:
# sudo chmod 755 rc_server.pl
#
#
# Autor:			Alexander Kratzer
#
#
#*******************************************************************************
#
# Historie:
# Datum:			  Autor:			Version:		Aenderungen:
# 09.12.2014		Kratzer		  0.0.1			  Ersterstellung
#
#*******************************************************************************

use strict;
use IO::Socket::INET;

$| = 1;                     
my ($debug, $socket, $client) = 0; #bei 1 werden debugausgaben in console geschrieben

start_srv(); #server der die anfragen entgegennimmt starten

#signalhaendler für die kind-prozesse
$SIG{'CHLD'} = sub { wait(); };

#hauptprogram
main();

sub main{ 
  while($client = $socket->accept()) #auf neue verbindungsanfrage warten
  {
    #Ausgabe an client umleiten
    open STDOUT, '>&', $client or dbg("can't open STDOUT");
    open STDERR, '>&', $client or dbg("can't open STDERR");
    dbg("client connected: " . $client->peerhost() . ":" . $client->peerport());
  
    
    my $pid=fork();
    if ($pid < 0) { die dbg("error making fork: $!\n"); }
     
    if ($pid == 0) #kindprozess erzeugen   
    {
      while (<$client>) #stream lesen
      {
        chomp; #/n entfernen 
        dbg("received: [$_]");
        system("$_") == 0 or print "Could not execute: [$?]\n"; #ausführen der Anfrage
        last; #stream lesen beenden
      }
      print "kill"; #remote client ende mitteilen
      $client ->close; #network stream schliessen
      exit(0); #thread wieder beenden
    } 
    else
    {
      dbg("new child with PID: $pid ");
      $client ->close; #parent braucht keinen stream
      main(); #rekursion um auf nächste verbindungsanfrage zu warten
    }   
  }
}

################### server starten ################################
#ermitteln der eigenen ip adresse um den server zu starten
sub get_local_ip{
  my $interface = shift;
  my @ifconfig = qx(ifconfig);
  my $if_found=0;
  foreach(@ifconfig) {
    $if_found++ if /^$interface\s/;
    if ($if_found) {
      if ( /inet (Adresse|addr):(\d+)\.(\d+)\.(\d+)\.(\d+)/ ) {
        return "$2.$3.$4.$5";
      }
    }
  } 
}

#server der die anfragen entgegennimmt starten
sub start_srv{
  my $local_port = '13000'; #port muss in client übereinstimmen 
  my $local_ip = get_local_ip("wlan0"); #kommunikation findet über w-lan statt

  $socket = new IO::Socket::INET (
    LocalHost => $local_ip,
    #LocalPort => $port_header . (split(/\./,$local_ip))[3],
    LocalPort => $local_port,
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
  ) or die print "ERROR in srv Socket Creation : $!";
  dbg("start server $local_ip:$local_port");
}

###################### debugausgaben #######################
sub dbg{
  if($debug){
    my ($msg) = @_;  
    open (my $STDOLD, '>&', STDOUT);
    open (STDOUT, '>>', '/dev/tty');
    print $msg."\n";
    open (STDOUT, '>&', $STDOLD);   
  }
}