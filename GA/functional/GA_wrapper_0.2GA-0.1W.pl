#!/usr/bin/env perl
use warnings;
use strict;

my @dependencies = ("make_cache.pl", "eval script", "0.2_functional GA script", "HMM_Counter.pl", "wig2fa.pl", "FastaFromBed", "HMM template script", "Normalization method");

# 2 modes : Preprocess and GA. Preprocess prompts to normalize, create various .customfa's, and instructs steps to get emissions for initial HMM.
#
# GA will handle everything when it is actually intended to run GA
#
# Preprocess: Have emissions for initial HMM completely figured out
# -> Normalization done!
# -> should have created all .fasta and wig files
#
# Input: Define regions
# -> check that model and test region do not overlap
# -> check that all regions are on 1 chr
#
# Prompt: Generate HMM Template
# -> save a template file
# -> option to load already-created template
# -> prompt for count files in a certain order, input into template file to make an initial HMM file
#
# Given regions and chromosome .fasta
# Make the cache and test wig files, pipe sig_regions / unsig_regions to eval script
# possibly make run-region?
#
# GA modes: State-specific conditionals in mutate(), normal everything can be mutated.
# -> also debug mode, verbose, quiet 
#
# Final output: HMM model file to be used with genome .customfa (wig2fa.pl again) and stochhmm alone
