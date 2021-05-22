#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Encode qw(decode encode);
use JSON qw(to_json);
use Plack::Request;

my %sonastik = (); # 'aakn' => kana kaan ... (kõik võimalikud sõnad nende tähtedega)

open (F, "</opt/anagramm/anagrammisonastik.txt") or die "puudub sonastik!";
binmode (F, ":utf8");
while (<F>) {
    chomp;
    # seal sees on liitsõnapiirid, kustutame
    s/\PL//g;
    my $sig = signatuur($_);
    $sonastik{$sig} .= " $_";
}

sub signatuur {
    my $s = shift;
    my @tahed = split (//, lc($s));
    return join "", sort @tahed;
}

my $app = sub {
  my $env = shift;
  my @vv = ();

  my $request = Plack::Request->new($env);

  my $q = $request->param('Q') || '';
  $q = decode('utf-8', $q);
  # kustutame kõik mittetähed, s.h tühikud
  $q =~ s/\PL//g;
  print "Q tühi\n" unless $q;
  return err ('Q puudub') unless $q;
  my $lcq = lc($q);

  # kasutame ainult neid sonastiku stringe, mis võivad olla osa tulemusest
  # s.t 'kaa' on Q='kana' alamhulk, aga 'ata' ei ole
  my @kandidaadid = ();

  my %qmall = ();
  foreach my $c (split (//, $lcq)) { $qmall{$c}++ };

KEY:
  foreach my $d (keys %sonastik) {
    my %dmall = ();
    foreach my $c (split (//, $d)) {
      # praagime välja kui sõnastikus on täht, mida päringus pole
      next KEY unless $qmall{$c};
      $dmall{$c}++;
      # praagime välja kui sõnastiku tähesagedus on suurem kui päringu vastaval
      next KEY if $dmall{$c} > $qmall{$c};
    }
    push @kandidaadid, $d;
  }

  my $qsig = signatuur($lcq);
  push @vv, "Leidus valmiskujul: ".$sonastik{$qsig}."\n" if $sonastik{$qsig};

  for my $i1 (0 .. $#kandidaadid) {
    for my $i2 ($i1+1 .. $#kandidaadid) {
      if ( signatuur($kandidaadid[$i1].$kandidaadid[$i2]) eq $qsig) {
	push @vv, 'Kahesõnaline: ' . $sonastik{$kandidaadid[$i1]} . ' ++ ' . $sonastik{$kandidaadid[$i2]} . "\n";
      }
    }
  }

  foreach $q (@vv) { $q = encode('utf-8', $q); }

  return [
    200,
    [ 'Content-type', 'application/json' ],
    [ to_json \@vv ]
  ]
};

sub err {
  my $mess = shift;
  return [
    400,
    [ 'Content-type', 'text/html' ],
    [ 
"<html>
  <head>
    <title>anagramm</title>
  </head>
  <body>
    <h1>$mess</h1>
  </body>
</html>"
    ]
  ];
}

