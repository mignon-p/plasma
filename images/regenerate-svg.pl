#!/usr/bin/perl -w

use strict;
use FindBin;

my $dir     = $FindBin::Bin;
my $fig_in  = "$dir/libraries.fig";
my $svg_out = "$dir/libraries.svg";

my $output  = "";

open F, "-|", "fig2dev", "-L", "svg", $fig_in or die;

while (<F>) {
    # Fiddle with the font to make it look nicer
    s/font-family="AvantGarde"/font-family="sans-serif"/;
    s/(font-size=")(\d+)(")/$1 . ($2 + 36) . $3/e;

    # Omit the date in order to get reproducible results
    $output .= $_ unless (/-- CreationDate:/);
}

close F;

open F, ">", $svg_out or die;
print F $output;
close F;
