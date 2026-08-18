#!/usr/bin/perl
#Script to complete input file for OOFEM

my $nNodes;

my $nan, $nodeNumber = 0;
my @x, @y;

my $inputFile = $ARGV[0];
open(FILEIN, "<$inputFile") || die "Could not open file $inputFile. Should be the oofem input file.\n";

while($line = <FILEIN>) { 

    if ($line =~ /ndofman\s+(\d+)/) {
     	$nNodes = $1;
     }

    if ($line =~ /coords\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
	$nodeNumber++;
	($nan, $x[$nodeNumber], $y[$nodeNumber], $nan) = ($1, $2, $3, $4);
    }

}

close(FILEIN);

my $dataFile = $ARGV[1];
open(FILEDAT, "<$dataFile") || die "Could not open file $dataFile. Should be the data file.\n";

my $nLines = 0;
my $i,$k;
my @allDisp;
my @xDisp;
my @yDisp;
while($line = <FILEDAT>) {
    $nLines++;
#    print $line;
    @allDisp = split(/\s+/, $line);
    for ($i=1; $i<=$nNodes;$i++){
	$xDisp[$nLines][$i] = $allDisp[$i];
	$yDisp[$nLines][$i] = $allDisp[$i+$nNodes];
    }
}

close(FILEDAT);

#PrintOutput
#First the undeformed mesh
open(FILEOUT, ">outputStep0.dat") || die "Could not open file outputStep0.dat\n";
for($i=1;$i<=$nNodes;$i++){
     printf FILEOUT "%.5f %.5f\n", $x[$i], $y[$i];    
}
close(FILEOUT);

#Now for the deformations
for($k=1;$k<=$nLines;$k++){
    open(FILEOUT, ">outputStep$k.dat") || die "Could not open file outputStep$k.dat\n";
    for($i=1;$i<=$nNodes;$i++){
	$xNew[$i] = $x[$i] + $xDisp[$k][$i];
	$yNew[$i] = $y[$i] + $yDisp[$k][$i];
    printf FILEOUT "%.5f %.5f\n", $xNew[$i], $yNew[$i];    
    }
    close(FILEOUT);
}
