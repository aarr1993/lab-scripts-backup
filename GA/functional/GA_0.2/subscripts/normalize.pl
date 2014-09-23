#!/usr/bin/env perl
use warnings;
use strict;

# Shift-wig normalization entirely written in perl
# basically assumes same span -- which is assumed by other GA scripts, so it's okay
# because it better be true

my ($wig, $outfile) = @ARGV;
die "usage: $0 <wigfile> <outfile>\n" unless @ARGV;

open (IN, "<", $wig) or die "Could not open $wig\n";

my @values;

while (<IN>) {
  my $line = $_;
  chomp $line; 

  if ($line =~ /^\d+/) {
    my ($pos, $val) = split(/\t/, $line);
    push (@values, $val);
  }
}

close IN;

my $median = int(@values / 2);
my $quart = int($median / 2);
my $third = $quart * 3;

my @sort = sort {$a<=>$b} @values; # FIXME check syntax
@values = (); # delete values array

my @small = @sort[$third..(@sort - 1)];
@sort = (); # delete sort array

my $third_median = int(@small / 2); 

my $shift = 10/$small[$third_median];
@small = ();

open (IN, "<", $wig);
open (OUT, ">", $outfile) or die "Could not open outfile\n";

while(<IN>) {
  my $line = $_;
  chomp $line;

  if ($line !~ /^\d+/) {
    print OUT "$line\n";
  }
  else {
    my ($pos, $val) = split(/\t/, $line);
    $val *= $shift;
    print OUT "$pos\t$val";
  }
}

close IN;
close OUT;
