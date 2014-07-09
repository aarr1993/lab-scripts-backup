use strict;
use warnings;
#my $orders = 6; # actually 3rd order, but the script use [actual order]+1
my $orders = 4; # actually 3rd order, but the script use [actual order]+1

package Distribution;

sub new{
	my $class = shift;
	my $self = bless {}, $class;
	my $filename;
	if (scalar @_ == 1){
		$filename=shift;
		$self->import($filename);
	}
	return $self;
}

#Return a string of Counts table
#Parameter: wordsize = order of distribution + 1
sub get_counts{
	my ($self,$wordsize)=@_;
	my $string=array2string($self->{COUNTS}->{$wordsize});
#  if (!exists($self->{COUNTS}->{$wordsize})) {
#    print "Not exists!\n";
#  }
	return $string;
}

##Convert the Array of Arrays to String
sub array2string{
	my $array=shift;
	my $string="";

	for(my $i=0;$i<scalar @{$array};$i++){
		for (my $j=0;$j<scalar @{$array->[$i]};$j++){
			$string.= int($array->[$i]->[$j]);
			$string.="\t";
		}
		$string.="\n";
	}
	return $string;
}

# Read HMM model so the counts can be used in distribution
sub read_hmm_model {
	my $hmm = $main::HMM_MODEL;

	open (my $in, "<", $hmm) or die "Cannot read from $hmm: $!\n";
	my $emm;
	my ($name);
	my ($row, $col) = (0,0);
	my $check = 0;
	my $total = 0;
	while (my $line = <$in>) {
		chomp($line);
#    print "$line\n";
#		($name) = $line =~ /NAME:\s(\w+)/ if $line =~ /NAME/; #Aparna modified added \s
    if ($line =~ /NAME/) {
      ($name) = $line =~ /NAME:\s+(\w+)/;
#      print "NAME: $name\n";
    }
		$row = 0 if $line =~ /ORDER/;
		if ($line =~ /^\d+/) {
				$check = 1;
#				my (@arr) = split("\t", $line);
				my (@arr) = split(/\s+/, $line); # aparna modified
#    for (my $r = 0 ; $r < @arr ; $r++) {
#        print "$arr[$r]\n";
#    }
#    die;
# what is the next line for?
#				$total += $arr[0] + $arr[1] + $arr[2] + $arr[3]; $total = 1 if $total == 0;
				$total += $arr[0] + $arr[1] + $arr[2] + $arr[3] + $arr[4] + $arr[5]; $total = 1 if $total == 0;
				for (my $i = 0; $i < @arr; $i++) {
        # Where is the $orders variable coming from -- ANS it's a global = 4
					$emm->{$name}->{COUNTS}->{$orders}->[$row]->[$i] = $arr[$i];
				}
#        print "my row is $row\n"; # all rows are read
				$row++;
 		}
		if ($check == 1 and $line =~ /\#\#\#\#\#/) {
#			for (my $i = 0; $i < 4**($orders-1); $i++) {
			for (my $i = 0; $i < 6**($orders-1); $i++) {
#         print "my i is $i"; # I have no idea what is going on with order or i, get very strange results from this print out
#				for (my $j = 0; $j < 4; $j++) { # why is j 4 at max???
				for (my $j = 0; $j < 6; $j++) { # why is j 4 at max???
#          print "$total\n";
          # where $i equals $row and $j is what was previously $i
#         my $debug = $emm->{$name}->{COUNTS}->{$orders}->[$i]->[$j];
#         print "$debug\n";
#          die;
#          print "$orders\t$name\n" if $i == 215 and $j == 0;
					$emm->{$name}->{PERCENT}->{$orders}->[$i]->[$j] = $emm->{$name}->{COUNTS}->{$orders}->[$i]->[$j] / $total;
#        print "i is $i and j is $j\n"; # here's the error! i only goes up to 63. Number of rows in incorrect emission table in testout/0.hmm? 63.
				}
			}
			$check = 0;
		}


	}
	close $in;
	return($emm);
}

#Import count table (not used)
sub import{
	my ($self, $file) = @_;
	open (my $in, "<", $file) or die "Couldn't open file $file: $!\n";

	my $name;
	
	while (my $line = <$in>){
		chomp ($line);
		if ($line =~ /^>(\d)/){
			$name=$1;
		}
		else{
			my @line = split ("\t", $line);
			
			for(my $i = 0; $i < @line; $i++) {
				$line[$i]++;
			}
			
			push (@{$self->{COUNTS}->{$name}}, \@line);
		}
	}
	$self->convert_to_percentages();
	return $self;
}

#Create percentage table using counts table (not used)
sub convert_to_percentages{
  print "convert_to_percentages is used!\n";
	my $self=shift;
	if (exists $self->{PERCENT}){
		return $self;
	}
	else{
		foreach my $dist (sort keys %{$self->{COUNTS}}){
			my $sum=0;
			my $rows=scalar @{$self->{COUNTS}->{$dist}};
			for(my $i=0;$i<$rows;$i++){
				for(my $j=0;$j<4;$j++){
					$sum+=$self->{COUNTS}->{$dist}->[$i]->[$j];
				}
			}
			
			for(my $i=0;$i<$rows;$i++){
				my @row=(0,0,0,0);
				push @{$self->{PERCENT}->{$dist}}, \@row;
			}
			
			for(my $i=0;$i<4**($orders-3);$i++){
				for(my $j=0;$j<4;$j++){
					die "$i\n" unless defined($self->{COUNTS}->{$dist}->[$i]->[$j]);
					my $percent=($self->{COUNTS}->{$dist}->[$i]->[$j])/$sum;
					$self->{PERCENT}->{$dist}->[$i]->[$j]=$percent;
				}
			}
		}
	}
	return $self;
}

package Population;
require Cwd;
require threads;
require Thread::Queue;
require Storable;


##Create a population ~10% from given counts and 90% random
##See generate() function
sub new{
	my ($class,$skew_file) = @_;
	
	my $self = bless {}, $class;
	my $skew=Distribution->new($skew_file);
	
	$self->generate($skew);

	return $self;
}


##Create a population base upon completely random distributions
sub new_random{ # NOTE used
	my ($class)=shift; # NOTE shifts array by one and returns first value, removing it. Class Population
	my $self=bless{}, $class; # makes whatever is ref'd by $self to be a Population object
	$self->generate_random(); # now that we have a Population object, generate it
}


## Generate a random distribution based on hmm model file
sub generate_random{ # NOTE used
	my ($self)=@_; #NOTE somehow gets self
	
	for(my $i=0;$i<$main::POPULATION_SIZE;$i++){ # makes POP_SIZE number of Individuals for Population

		my $individual = Individual->new(); # makes new Individual
		my $emm = Distribution::read_hmm_model(); # get the dist from HMM
		$individual->{DIST} = $emm; # put it in the new Individual
#    print "$emm\n";
#					$emm->{$name}->{PERCENT}->{$orders}->[$i]->[$j] = $emm->{$name}->{COUNTS}->{$orders}->[$i]->[$j] / $total;
#    my $debug = $emm->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    die "$debug\n";
		$individual->mutate(); # mutate individial
#    my $debug = $individual->{DIST}->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    die "$debug\n";
		push @{$self->{INDIVIDUALS}}, $individual; # Add the individual to the Population
#    my $debug = $self->{INDIVIDUALS}->[0]->{DIST}->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    my $debug2 = $individual->{DIST}->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    print "$debug\t$debug2\n";
	}
#    my $x = $self->{INDIVIDUALS}->[1]->{DIST}->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    print "print x $x\n";
	return $self; # return the full Population
}

## Save the Population to a file

sub store{
        my ($self,$file)=@_;
        Storable::store($self,$file);
}

#Purge 80% of population
sub purge{
	
	my $parent_size;
	#if (not defined($main::KILLED_POP) or $main::KILLED_POP == 0) {
		$parent_size = 1- $main::PARENT_SIZE; # NOTE what?
	#}
	#else {
	#	$parent_size = $main::KILLED_POP/$main::POPULATION_SIZE > 1 - $main::PARENT_SIZE ? $main::KILLED_POP/$main::POPULATION_SIZE : 1 - $main::PARENT_SIZE;
	#}
	

	#Each Row

	my $self=shift;
	my $size=(int($main::POPULATION_SIZE * $parent_size))-1;
	
	my $end=(scalar @{$self->{INDIVIDUALS}}) -1;
	
	#Sorts the individual by score in ascending order
	$self->sort_scores();
	
	#Delete the first N of the population according to parent size
	delete @{$self->{INDIVIDUALS}}[0..$size]; # NOTE delete the lowest scoring?

	#Shift individuals to top of list # NOTE no idea how this works or exactly what it does
	my @array=@{$self->{INDIVIDUALS}};
	@array=@array[($size+1)..$end];
	$self->{INDIVIDUALS}=\@array;
}


# Sort fitness scores
sub sort_scores{
	my $self=shift;
	my @array=sort {$a->{SCORE} <=> $b->{SCORE}} @{$self->{INDIVIDUALS}};
	$self->{INDIVIDUALS}=\@array;
	return $self;
}


#Mate indivduals to generate new offspring
#Probability of mating is based on the fitness score.   Higher fitness have
#higher chance of mating
sub mate{  
	my $self=shift;
	
	my $fitness_sum=0;
	my @scores;
	
	#Compute the sum of fitness scores
	foreach my $individual (@{$self->{INDIVIDUALS}}){
		push @scores,$individual->{SCORE};
		$fitness_sum+=$individual->{SCORE};
	}
	
	while(scalar @{$self->{INDIVIDUALS}}<$main::POPULATION_SIZE){
		#Select mate pairs
		my $father=int(rand($fitness_sum));
		my $mother=int(rand($fitness_sum));
		my $father_iter=-1;
		my $mother_iter=-1;
		
		my $running_sum=0;
		for(my $i=0;$i<scalar @scores;$i++){
			$running_sum+=$scores[$i];
			if ($father<$running_sum){
				$father_iter=$i;
			}
			
			if ($mother<$running_sum){
				$mother_iter=$i;
			}
			
			if ($mother_iter!=-1 && $father_iter!=-1){
				last;
			}
		}
		
		#Crossover
		if (rand(1)<$main::CROSSOVER_RATE){
			my $ind= Individual->new();
			$ind->crossover($self->{INDIVIDUALS}->[$father_iter], $self->{INDIVIDUALS}->[$mother_iter]);

			$ind->mutate();
			push @{$self->{INDIVIDUALS}},$ind;
		}
		else{
			my $ind= Individual->new();
			$ind->mate($self->{INDIVIDUALS}->[$father_iter], $self->{INDIVIDUALS}->[$mother_iter]);
			$ind->mutate();
			push @{$self->{INDIVIDUALS}},$ind;
		}
	}
	return $self;
}

#Evalute the new individuals in the population
#Outputs models for each individual
#Runs StochHMM
#Evaluates the Predictions
sub evaluate{
	my ($self)=@_; # takes in the population
#  print "$self\n";
#    my $x = $self->{INDIVIDUALS}->[1]->{DIST}->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    die "print x $x\n";
	my $file_name=0;
	my @files;
	my $start_dir=Cwd::getcwd(); # current working dir
#print "beginning of evaluate\n";
	
	unless (-d $main::OUTPUT_DIR){
		mkdir $main::OUTPUT_DIR or die;
	}
	
	chdir $main::OUTPUT_DIR or die "Couldn't change to working directory $main::OUTPUT_DIR\n";
## move around to output dir
	
	foreach my $indi (sort {$b->{SCORE} <=> $a->{SCORE}} @{$self->{INDIVIDUALS}}){ # not sorted ?
		# Not yet scored	
#    print "In foreach\n";	
		if ($indi->{SCORE}==-1){
#      print "in if\n";
			my $file=$file_name;
			push @files,[$file,$indi];
			$indi->output_model($file_name); # undefined somewhere from this call
#    my $x = $self->{INDIVIDUALS}->[1]->{DIST}->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    die "print x $x\n";
			$file_name++;
		}
		else { # this is the same as above ...
#      print "in else\n";
			my $file=$file_name;
			push @files,[$file,$indi];
#    my $x = $self->{INDIVIDUALS}->[1]->{DIST}->{BROAD_PEAK}->{COUNTS}->{4}->[215]->[5];
#    die "print x $x\n";
			$indi->output_model($file_name);
			$file_name++;
		}
#    print "end of foreach loop\n";
	}
#  print "before run_stochHMM\n"; 
	run_stochHMM(SEQ=>$main::SEQFILE,
			MODELS=>\@files, # array of Individual models
			POSTERIOR => 1, # use posterior
			 );
#  print "before evaluate_models\n";
	evaluate_models(\@files);
	chdir $start_dir or die "Failed to change directory\n";
#  print "End of evaluate()\n"; 
}

# Evaluate each model
# Report file is in .report
# Utilize evaluate_report.pl in OUTPUT_FOLDER file
sub evaluate_models{
	my ($hmm, $start_add, $end_add)=@_;
	my $eval = $main::EVALFILE;
	my $threshold = $main::THRESHOLD;
	my @totalQ;
	for (my $i = 0; $i < @{$hmm}; $i++) {
		my $model = $hmm->[$i]->[0] . ".hmm"; # NOTE how are these different??
		my $res = $hmm->[$i]->[0]. ".report"; #
#    print "$model\n";
#    my $var = $hmm->[$i];
#    print "$var\n";
#    my $testvar = $hmm->[$i]->[1];
#    print "$testvar\n";
#    foreach my $element (keys %{$hmm->[$i]->[1]}) {
#      print "$element\n";
#    }
		my $comm = "DRIPc_small_currenteval.pl $res $threshold"; # NOTE FIXME need this script!
		push(@totalQ, $comm);
	}
	# Evaluate each report file using Thread Queue
	print "\tEvaluating models\n";
	my %result;
	for (my $i = 0; $i < int(@totalQ / $main::THREAD_NUM)+1;  $i++) {
		my $Q = new Thread::Queue;
		my $remaining = $i * $main::THREAD_NUM + $main::THREAD_NUM >= @totalQ ? @totalQ : $i * $main::THREAD_NUM + $main::THREAD_NUM;
		my $totalQ = @totalQ;
		for (my $j = $i*$main::THREAD_NUM; $j < $remaining; $j++) {
			$Q->enqueue($totalQ[$j]);
		}
		$Q->end();
		my $lastj = 0;
		my @threads;
	        for (my $j=0;$j<$main::THREAD_NUM;$j++){
	                $threads[$j] = threads->create(\&worker, $j, $Q);
			$lastj = $j+1;
			my $remainingQ = $Q->pending();
			last if not defined($remainingQ) or $remainingQ == 0;
			printf STDERR "\t%.2f %% Complete\r", 100 * (@totalQ - $remainingQ) / @totalQ;
	        }
	        for (my $j=0;$j<$lastj;$j++){
			#print "$j\n";
	                my @results = @{$threads[$j]->join()};
			foreach my $result (@results) {
				#print "$result\n";
				my ($hmm_number,$tp, $tn, $fp, $fn) = split(",", $result);
				die "died at $result\n" if not defined($tp);
				$result{$hmm_number}{tp} = $tp;
				$result{$hmm_number}{fp} = $fp;
				$result{$hmm_number}{tn} = $tn;
				$result{$hmm_number}{fn} = $fn;
			}
	        }
	}
	print "Done\n";
	my $check = 0 if not defined($main::LOWEST_FP);
	$check = 1 if defined($main::LOWEST_FP);
	printf "CURRENT HIGHEST FP = %d\n", $main::LOWEST_FP if defined($main::LOWEST_FP);
	for (my $i = 0; $i < @{$hmm}; $i++) {
		my $rpt = $hmm->[$i];
		my $hmm_number = $rpt->[0];
		my $tp = $result{$hmm_number}{tp};
		my $fp = $result{$hmm_number}{fp};
		my $tn = $result{$hmm_number}{tn};
  	my $fn = $result{$hmm_number}{fn};
    $fn = $fn * 10; # adding more weight
		my $sen = ($tp + $fn) == 0 ? 0 : $tp / ($tp + $fn);
		my $spe = ($tn + $fp) == 0 ? 0 : $tn / ($tn + $fp);
		my $pre = ($tp + $fp) == 0 ? 0 : $tp / ($tp + $fp);
		my $rec = ($tp + $fn) == 0 ? 0 : $tp / ($tp + $fn);
		#my $f = $pre;#($tp / ($tp + $fp)) * (0-$fn);#($tp + $fp + $fn + $tn);
		my $f = ($pre + $rec) == 0 ? 0 : (2 * $pre * $rec) / ($rec + $pre);
#    my $f = ($pre + $rec) == 0 ? 0 : $rec / ($rec + $pre); 
#		my $acc = ($tp + $fn + $tn + $fn) == 0 ? 0 : ($tp + $tn) / ($tp + $fp + $tn + $fn);
#		my $f = $acc;
		#if ($check == 0) {
		#	$main::LOWEST_FP = $fp if not defined($main::LOWEST_FP);
		#	$main::LOWEST_FP = $fp if $fp < $main::LOWEST_FP;
		#}
		#else {
		#	$main::LOWEST_FP = $fp if ($i == 0);
		#	$f = $f**2 if $main::LOWEST_FP < $fp and $i != 0;
		#	#$main::KILLED_POP ++ if $main::LOWEST_FP > $tp and $i != 0;
		#}
		$rpt->[1]->{SCORE} = $f;
#		$rpt->[1]->{SCORE} = $sen;
		printf STDERR "\thmmfile $hmm_number\.hmm:\tf: %.4f\ttp $tp\ttn $tn\tfp $fp\tfn $fn\n", $f;
	}
	return;

}

#Run stochHMM on $main::THREAD_NUM threads
sub run_stochHMM{
	my %default=(MODELS=>[],
			 SEQ=>"",
			 REPORT=>0,
			 THRESHOLD=>0,
			 REP=>10,
			 RPT=>0,
			 PATH=>0,
			 LABEL=>0,
			 POSTERIOR=>0,
			 GFF=>0,
			 VITERBI=>0,
			 NBEST=>0,
			 THREADS=>$main::THREAD_NUM);

	my %arg=(%default,@_);
	my $seq = $main::SEQFILE;
	my @totalQ;
#	my $command="StochHMM -model MODEL -seq \"$seq\" ";
	my $command="stochhmm -model MODEL -seq \"$seq\" ";

	if (exists $arg{STOCH}){
		$command .= "-stochastic $arg{STOCH} -repetitions $arg{REP} ";
	}
	
	if (scalar @{$arg{MODELS}}<8){
		$arg{THREADS}=scalar @{$arg{MODELS}};
	}
	
	if ($arg{VITERBI}==1){
		$command.="-viterbi ";
	}
	if ($arg{POSTERIOR}==1){
		$command.="-posterior ";
	}	
	
	if ($arg{NBEST}>0){
		$command.="-nbest $arg{NBEST} ";
	}
	
	if ($arg{PATH}==1){
		$command.="-path ";
	}
	if ($arg{LABEL}==1){
		$command.="-label ";
	}
#	if ($arg{GFF}==1){
		$command.="-gff ";
#	}
	
	if ($arg{REPORT}>0){ # NOTE nothing happens ...
		#$command.="-report OUTFILE ";
	}
			
	if ($arg{THRESHOLD}>0){
		$command.="-threshold " . $arg{THRESHOLD} . " ";
	}
	foreach my $mod (@{$arg{MODELS}}){
		my $comm = $command;
		my $hmm_file=$mod->[0];
		my $out_file= $mod->[0];
		$out_file.= ".report";
		$hmm_file.= ".hmm";
		$comm=~s/OUTFILE/$out_file/; # NOTE but where is this defined in command?
		$comm=~s/MODEL/$hmm_file/;
		$comm .= "> $out_file" ;#if $arg{GFF} == 0;
		push(@totalQ, $comm);
	}
	

	print "\tRunning StochHMM\n";
	my $count = 0;
	for (my $i = 0; $i < int(@totalQ / $main::THREAD_NUM)+1;  $i++) {
		my $Q = new Thread::Queue;
		my $remaining = $i * $main::THREAD_NUM + $main::THREAD_NUM >= @totalQ ? @totalQ : $i * $main::THREAD_NUM + $main::THREAD_NUM;
		my $totalQ = @totalQ;
		for (my $j = $i*$main::THREAD_NUM; $j < $remaining; $j++) {
			$Q->enqueue($totalQ[$j]);
		}
		$Q->end();
	        my @threads;
	
		my $lastj = 0;
	        for (my $j=0;$j<$main::THREAD_NUM;$j++){
	                $threads[$j] = threads->create(\&worker, $j, $Q);
			$lastj = $j+1;
			my $remainingQ = $Q->pending();
			last if not defined($remainingQ) or $remainingQ == 0;
			printf STDERR "\t%.2f %% Complete\r", 100 * (@totalQ - $remainingQ) / @totalQ;
	        }
	        for (my $j=0;$j<$lastj;$j++){
	                $threads[$j]->join();
	        }
	}
	print "\nDone\n";
	return;
}

#worker subroutine for run_stochhmm
sub worker {
	my ($thread, $queue) = @_;
	my $tid = threads->tid;
	my @results;
	while ($queue->pending) {
		my $command = $queue->dequeue;
		next if not defined($command);
		my $results = `$command`;

		push(@results, $results);
	}
	return(\@results);
}

#Gets the maximum score from the population
sub max{ # NOTE no idea how this works
	my $self=shift;
	my $max=0;
	my $count = 0;
	my $max_indiv = 0;
	my $maxcount = int(@{$self->{INDIVIDUALS}} * 0.2) == 0 ? 1 : int(@{$self->{INDIVIDUALS}} * 0.2);

	foreach my $indiv (sort {$b->{SCORE} <=> $a->{SCORE}} @{$self->{INDIVIDUALS}}){
		$count++;
		$max_indiv = $indiv->{SCORE} if $max_indiv < $indiv->{SCORE};
		$max += $indiv->{SCORE} / $maxcount if $count <= $maxcount
	}
	return ($max, $max_indiv);
}


package Individual; 
use vars qw($MUTATION_RATE $MAX_MUTATION_CHANGE $CROSSOVER_RATE $POPULATION_SIZE);
my $Genomic;

#Individual is composed of a single 3rd order distibution and a fitness score.
#If unevaluated the fitness score = -1
sub new{
	my ($class,$dist) = @_; # get class (pop? Individual?) and emm
	
	my $self = bless {"DIST"=>$dist,"SCORE"=>-1}, $class; # make the object
	return $self; # return it
}


#Mutate an individuals distribution
sub mutate{
	my $self = shift; # gets the Individual
	
	#Each Row
	my $distribution = $self->{DIST}; # gets the Distribution

	foreach my $types (keys %{$distribution}) { # NOTE Types?
#		for(my $i=0;$i< 4**($orders-1) ;$i++){
#NOTE MORE HARDCODING
# changing all 4s to 6s because more emission
#		for(my $i=0;$i< 4**($orders-1) ;$i++){
		for(my $i=0;$i< 6**($orders-1) ;$i++){
			#Each entry in row
#			for(my $j=0;$j<4;$j++){ # FIXME this does not mutate unless rand is < mutation rate max!
			for(my $j=0;$j<6;$j++){ # FIXME this does not mutate unless rand is < mutation rate max!
        my $mut = 0;
#        if ($types =~ /NOISY/) {
        if ($types =~ /NOISY/ && $types !~ /INTERPEAK/) {
          if (rand(1)<$main::MUTATION_RATE) {
            $mut = 1;
          }
        }
#        else {
#          if (rand(1)<0.075) {
#            $mut = 1;
#          }
#        }
        
#				if (rand(1)<$main::MUTATION_RATE){
				if ($mut){
					my $difference = rand($main::MAX_MUTATION_CHANGE);
					my $value = $self->{DIST}->{$types}->{COUNTS}->{$orders}->[$i]->[$j];
					die "died at $orders $i $j\n" if not defined($value);
#          print "mutate $types\n";
					#determine whether to add or delete value
					if (rand(1)<0.5){ # randomly
						$value+=$difference*$value; ## Changes value by adding or 
#            $value=int($value)+1; # matching ceiling function
					}                             ## subtracting a random amnt
					else{
						$value-=$difference*$value;
#            $value=int($value)+1; # ensures min value is always 1
            if ($value < 1) {
              $value = 1;
            }
					}
					
					#assign mutated new value
					$self->{DIST}->{$types}->{COUNTS}->{$orders}->[$i]->[$j]=$value;
          # assigns the new changed value
				}
			}
		}
	}
	return $self; # return the Individual now fully mutated
}


#Mate two individuals
#Simple mating entails adding the two values together.
#Note:  Changed to average of two individuals instead of adding together 
sub mate{
	my ($self,$ind1,$ind2)=@_;

	#Each Row
	my %dis1 = %{$ind1->{DIST}};
	my %dis2 = %{$ind2->{DIST}};

	foreach my $dis (keys %dis1) {
		my $val1 = $dis1{$dis};
		my $val2 = $dis2{$dis};
#    print "in mate";
# NOTE HARDCODING
#		for(my $i=0;$i<4**($orders-1);$i++){
		for(my $i=0;$i<6**($orders-1);$i++){
#			for(my $j=0;$j<4;$j++){
			for(my $j=0;$j<6;$j++){
				$self->{DIST}->{$dis}->{COUNTS}->{$orders}->[$i]->[$j]=($val1->{COUNTS}->{$orders}->[$i]->[$j]+$val2->{COUNTS}->{$orders}->[$i]->[$j])/2;
			}
		}
	}
	return $self;
}


##Crossover
## At crossover point the rows and values of two tables are swapped
sub crossover{
	my ($self,$ind1,$ind2)=@_;
#  print "crossover\n";	
	#Determine row of crossover
	my $crossover_point=int(rand(64))-1;
	
	#Determine column of crossover
	my $point=int(rand(4))-1;

	#Each Row
	my %dis1 = %{$ind1->{DIST}};
	my %dis2 = %{$ind2->{DIST}};

	foreach my $dis (keys %dis1) {
		my $val1 = $dis1{$dis};
		my $val2 = $dis2{$dis};
	
# NOTE HARDCODING
#		for(my $i=0; $i<4**($orders-1); $i++) {
		for(my $i=0; $i<6**($orders-1); $i++) {

			if ($crossover_point<$i){
				my @line1=@{$val1->{COUNTS}->{$orders}->[$i]};
				push @{$self->{DIST}->{$dis}->{COUNTS}->{$orders}->[$i]}, @line1;
			}
			elsif ($crossover_point==$i){
				my @line1=@{$val1->{COUNTS}->{$orders}->[$i]};
				my @line2=@{$val2->{COUNTS}->{$orders}->[$i]};
	
#				for(my $j=0;$j<4;$j++){
				for(my $j=0;$j<6;$j++){
					if ($i<$point){
						$self->{DIST}->{$dis}->{COUNTS}->{$orders}->[$i]->[$j]=$line1[$j];
					}
					else{
						$self->{DIST}->{$dis}->{COUNTS}->{$orders}->[$i]->[$j]=$line2[$j];
					}
				}
			}
			else{
				my @line2=@{$val2->{COUNTS}->{$orders}->[$i]};
				push @{$self->{DIST}->{$dis}->{COUNTS}->{$orders}->[$i]}, @line2;
			}
		}
	}
	return $self;
}

# FIXME undefined value somewhere in this function
#Print the model the the file
sub output_model{
	my ($self,$file)=@_;
	$file.=".hmm";
	
	#Transition probabilities are coded here
	#EMISSION=>ORDER of distribution to use
	my %Peak_mod=(	OUTPUT_FILE=>$file,
                        I_ORDER => 3,
                        M_ORDER => 3,
                        B_ORDER => 3,
                        G_ORDER => 3,
                        E_ORDER => 3,
                        S_ORDER => 3,
                        N_ORDER => 3,

                        I2I => 0.9999048,
                        I2M => 0.00004761905,
                        I2B => 0.00004761905,

                        M2I =>  0.0001025641,
                        M2M =>  0.9998462,
                        M2G =>  0.00005128205,
    
                        B2I =>  0.0001333333,
                        B2B =>  0.9998,
                        B2G =>  0.00006666667,

                        G2M =>  0.0000001351351, 
                        G2B =>  0.0000001351351, 
                        G2G =>  0.9999995, 
                        G2S =>  0.0000001351351, 
                        G2N =>  0.0000001351351, 

                        E2G =>  0.00005128205,                        
                        E2E =>  0.9998462,                        
                        E2N =>  0.0001025641,    

                        S2G => 0.0000952381,
                        S2S => 0.9997143,
                        S2N => 0.0001904762,

                        N2E => 0.00003125,
                        N2S => 0.00003125,
                        N2N => 0.9999375,

			                  I_EMM => 0,
			                  M_EMM => 0,
			                  B_EMM => 0,
			                  G_EMM => 0,
			                  E_EMM => 0,
                        S_EMM => 0,
                        N_EMM => 0
			);
#print "before array2string calls\n"; #FIXME next line is the undefined error
#  if (!exists($self->{DIST}->{PEAK})) {
#    print "!exists1\n";
#  }  
#  if (!exists($self->{DIST}->{PEAK}->{COUNTS}->{$orders}))
#  {
#    print "!exists hmm $file\n";
#  }
#	my $debug = $self->{DIST}->{BROAD_PEAK}->{COUNTS}->{$orders}->[215]->[5];
#  die "$debug\n";
	$Peak_mod{I_EMM}=array2string($self->{DIST}->{NOISY_INTERPEAK}->{COUNTS}->{$orders});
	$Peak_mod{M_EMM}=array2string($self->{DIST}->{NOISY_MEDPEAK}->{COUNTS}->{$orders});
	$Peak_mod{B_EMM}=array2string($self->{DIST}->{NOISY_BROADPEAK}->{COUNTS}->{$orders});
	$Peak_mod{G_EMM}=array2string($self->{DIST}->{GENOMIC_INTERPEAK}->{COUNTS}->{$orders});
	$Peak_mod{E_EMM}=array2string($self->{DIST}->{SPARSE_MEDPEAK}->{COUNTS}->{$orders});
	$Peak_mod{S_EMM}=array2string($self->{DIST}->{SPARSE_SHARPPEAK}->{COUNTS}->{$orders});
	$Peak_mod{N_EMM}=array2string($self->{DIST}->{SPARSE_INTERPEAK}->{COUNTS}->{$orders});
#	my $debug = $self->{DIST}->{BROAD_PEAK}->{COUNTS}->{$orders}->[215]->[5];
#  die "$debug\n";
#  print "Peakmod debug\n$Peak_mod{R_EMM}\n";
#  print "after array2string calls\n";
#	$GC_mod{N_EMM}=array2string($self->{DIST}->{N}->{COUNTS}->{$orders});
	_output_model(%Peak_mod);
}


#Takes values created by output_model and prints the file
sub _output_model{
	my %default=(	OUTPUT_FILE=>"Peaks.hmm",
                        I_ORDER => 3,
                        M_ORDER => 3,
                        B_ORDER => 3,
                        G_ORDER => 3,
                        E_ORDER => 3,
                        S_ORDER => 3,
                        N_ORDER => 3,

                        I2I => 0,
                        I2M => 0,
                        I2B => 0,

                        M2I =>  0,
                        M2M =>  0,
                        M2G =>  0,
    
                        B2I =>  0,
                        B2B =>  0,
                        B2G =>  0,

                        G2M =>  0, 
                        G2B =>  0, 
                        G2G =>  0, 
                        G2S =>  0, 
                        G2N =>  0, 

                        E2G =>  0,                        
                        E2E =>  0,                        
                        E2N =>  0,    

                        S2G => 0,
                        S2S => 0,
                        S2N => 0,

                        N2E => 0,
                        N2S => 0,
                        N2N => 0,

			                  I_EMM => 0,
			                  M_EMM => 0,
			                  B_EMM => 0,
			                  G_EMM => 0,
			                  E_EMM => 0,
                        S_EMM => 0,
                        N_EMM => 0
			 );
	my %arg=(%default,@_); # NOTE how does this work

	my $file=$arg{OUTPUT_FILE};
	open OUT, "> $file" or die "Can't open file for writing";

	my ($sec, $min, $hour, $day, $month, $yr19) = localtime(time);
	my $date = ($month+1) . "\/$day\/" . ($yr19+1900);
	
	print OUT "\#STOCHHMM MODEL FILE
MODEL INFORMATION
======================================================
MODEL_NAME:     PEAK CALLING MODEL DRIP
MODEL_DESCRIPTION:      To call peaks on the DRIP dataset
MODEL_CREATION_DATE:    $date

TRACK SYMBOL DEFINITIONS
======================================================
SCORE:  N,L,O,M,H,S\n\n";

my %state;
$state{INIT} = "STATE DEFINITIONS
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
STATE:
        NAME: INIT
TRANSITION: STANDARD: P(X)
        NOISY_INTERPEAK: 0.14285714285714
        NOISY_MEDPEAK:   0.14285714285714
        NOISY_BROADPEAK: 0.14285714285714
        GENOMIC_INTERPEAK:       0.14285714285714
        SPARSE_MEDPEAK:  0.14285714285714
        SPARSE_SHARPPEAK:        0.14285714285714
        SPARSE_INTERPEAK:        0.14285714285714
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";


# TODO: Need to create loop so it automatically create each state instead of defining one by one
$state{I} = "STATE:
        NAME:   NOISY_INTERPEAK
        PATH_LABEL:     I
TRANSITION:     STANDARD:       P(X)
        NOISY_INTERPEAK:        0.9999048
        NOISY_MEDPEAK:  0.00004761905
        NOISY_BROADPEAK:        0.00004761905
        GENOMIC_INTERPEAK:      0
        SPARSE_MEDPEAK: 0
        SPARSE_SHARPPEAK:       0
        SPARSE_INTERPEAK:       0
        END:    1
EMISSION:       SCORE   COUNTS
        ORDER: $arg{I_ORDER}	
$arg{I_EMM}\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";
$state{M} = "STATE:
        NAME:   NOISY_MEDPEAK
        PATH_LABEL:     M
        GFF_DESC:       Noisy_MedPeak
TRANSITION:     STANDARD:       P(X)
        NOISY_INTERPEAK:        0.0001025641
        NOISY_MEDPEAK:  0.9998462
        NOISY_BROADPEAK:        0
        GENOMIC_INTERPEAK:      0.00005128205
        SPARSE_MEDPEAK: 0
        SPARSE_SHARPPEAK:       0
        SPARSE_INTERPEAK:       0
        END:    1
EMISSION:       SCORE   COUNTS
        ORDER: $arg{M_ORDER}	
$arg{M_EMM}\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";
$state{B} = "STATE:
        NAME:   NOISY_BROADPEAK
        PATH_LABEL:     B
        GFF_DESC:       Noisy_BroadPeak
TRANSITION:     STANDARD:       P(X)
        NOISY_INTERPEAK:        0.0001333333
        NOISY_MEDPEAK:  0
        NOISY_BROADPEAK:        0.9998
        GENOMIC_INTERPEAK:      0.00006666667
        SPARSE_MEDPEAK: 0
        SPARSE_SHARPPEAK:       0
        SPARSE_INTERPEAK:       0
        END:    1
EMISSION:       SCORE   COUNTS
        ORDER: $arg{B_ORDER}	
$arg{B_EMM}\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";
$state{G} = "STATE:
        NAME:   GENOMIC_INTERPEAK
        PATH_LABEL:     G
TRANSITION:     STANDARD:       P(X)
        NOISY_INTERPEAK:        0
        NOISY_MEDPEAK:  0.0000001351351
        NOISY_BROADPEAK:        0.0000001351351
        GENOMIC_INTERPEAK:      0.9999995
        SPARSE_MEDPEAK: 0.0000001351351
        SPARSE_SHARPPEAK:       0.0000001351351
        SPARSE_INTERPEAK:       0
        END:    1
EMISSION:       SCORE   COUNTS
        ORDER: $arg{G_ORDER}	
$arg{G_EMM}\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";
$state{E} = "STATE:
        NAME:   SPARSE_MEDPEAK
        PATH_LABEL:     E
        GFF_DESC:       Sparse_MedPeak
TRANSITION:     STANDARD:       P(X)
        NOISY_INTERPEAK:        0
        NOISY_MEDPEAK:  0
        NOISY_BROADPEAK:        0
        GENOMIC_INTERPEAK:      0.00005128205
        SPARSE_MEDPEAK: 0.9998462
        SPARSE_SHARPPEAK:       0
        SPARSE_INTERPEAK:       0.0001025641
        END:    1
EMISSION:       SCORE   COUNTS
        ORDER: $arg{E_ORDER}	
$arg{E_EMM}\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";
$state{S} = "STATE:
        NAME:   SPARSE_SHARPPEAK
        PATH_LABEL:     S
        GFF_DESC:       Sparse_SharpPeak
TRANSITION:     STANDARD:       P(X)
        NOISY_INTERPEAK:        0
        NOISY_MEDPEAK:  0
        NOISY_BROADPEAK:        0
        GENOMIC_INTERPEAK:      0.0000952381
        SPARSE_MEDPEAK: 0
        SPARSE_SHARPPEAK:       0.9997143
        SPARSE_INTERPEAK:       0.0001904762
        END:    1
EMISSION:       SCORE   COUNTS
        ORDER: $arg{S_ORDER}	
$arg{S_EMM}\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";
$state{N} = "STATE:
        NAME:   SPARSE_INTERPEAK
        PATH_LABEL:     N
TRANSITION:     STANDARD:       P(X)
        NOISY_INTERPEAK:        0
        NOISY_MEDPEAK:  0
        NOISY_BROADPEAK:        0
        GENOMIC_INTERPEAK:      0
        SPARSE_MEDPEAK: 0.00003125
        SPARSE_SHARPPEAK:       0.00003125
        SPARSE_INTERPEAK:       0.9999375
        END:    1
EMISSION:       SCORE   COUNTS
        ORDER: $arg{N_ORDER}	
$arg{N_EMM}\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#";

	print OUT "$state{INIT}\n";
	print OUT "$state{E}\n";
	print OUT "$state{S}\n";
	print OUT "$state{N}\n";
	print OUT "$state{I}\n";
	print OUT "$state{M}\n";
	print OUT "$state{B}\n";
	print OUT "$state{G}\n";
	print OUT "//END\n";
	close OUT;
}

##Convert array to string
sub array2string{
	my ($array,$value)=@_;
	
	if (!defined $value){
		$value=1;
	}
	my $string="";
#my $debug = $array->[1]; # 0 1 unintialized
#print "$debug";
	for(my $i=0;$i<6**($orders-1);$i++){
		for (my $j=0;$j< @{$array->[$i]};$j++){ # aparna modified removed scalar before @{}

    	$string.= int($array->[$i]->[$j] * $value);
			$string.="\t";
		}
		$string.="\n";
	}
	return $string;
}

1;  
__END__
