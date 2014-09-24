#!/usr/bin/env perl
use warnings ;
use strict ;
use Cache::FileCache;

# for use with GA stochhmm
# sets cache for the evaluate_report_peaks.pl script
# wig file MUST BE SORTED and MUST be in span=10
# syntax copied from /usr/local/bin/Perl/map_wig_to_bed.pl
# all file names and cache names are HARDCODED because
  # evaluate_report_peaks.pl cannot take in any more args and needs it hardcoded
  # to remind what all the names are

my ($cache_root, $wigfile) = @ARGV;
die "usage: $0 <cache> <wig>\n" unless @ARGV;

my $name = $wigfile =~ /\/{0,1}(.+)$/; # FIXME check regex

my $abs_path = `cd $cache_root ; pwd`; 
chomp $abs_path;
$abs_path .= "/"; # because relative path crashes

#print STDERR "abs_path is [$abs_path]\n";

my $cache = new Cache::FileCache();
$cache -> set_cache_root($abs_path);

my $sig_blocks;
my $unsig_blocks;

open (IN, "<", $wigfile) or die "Could not open $wigfile\n";
my $chr = "INIT";
my $curr_chr = "INIT";
my $span;
my @wig;

while (<IN>) {
  my $line = $_ ;
  chomp $line ;

  if ($line !~ /^\d/) {
    next if $line  !~ /chrom=/;
    ($chr, $span) = $line =~ /chrom=chr(.+) span=(\d+)/i;
    ($chr) = $line =~ /chrom=chr(.+)/i if not defined($chr);
    $span = 1 if not defined($span) or $span == 0;
  if ($chr ne $curr_chr and $curr_chr ne "INIT") {
    print "setting $curr_chr cache at $name\.$curr_chr\.cache\n";
    $cache -> set("$name\.$curr_chr\.cache", \@wig);
    @wig = ();
  }
    $curr_chr = $chr;
  }
  else {
    my ($pos, $val)   = split("\t", $line)    ;
    if ($val > 10) {
      push (@wig, {start => $pos, value=>$val});
      if ($val > 2 * 10) { # NOTE threshold
        $sig_blocks++;
      }
    }
    elsif ($val < 10) {
      $unsig_blocks++;
    }
  }
}
close IN;
print "setting $curr_chr ($chr) cache at $name\.$curr_chr\.cache\n";
$cache -> set("$name\.$curr_chr\.cache", \@wig);

print "$sig_blocks\t$unsig_blocks\n";  
