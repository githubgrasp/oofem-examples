#!/usr/bin/perl
use strict;
use warnings;

my $deltaStep     = 1;
my $numberOfSteps = 100;

open(my $out, '>', 'pressure.dat') or die "Cannot open pressure.dat: $!";
print $out "0 0\n";

my $fileBase = "oofem.out.m1.";

for (my $k = 1; $k <= $numberOfSteps / $deltaStep; $k++) {
    my $timeStep = $k * $deltaStep;
    my $fname = "${fileBase}${timeStep}.gp";

    open(my $in, '<', $fname) or die "Could not open $fname: $!";

    # Skip 4 header lines
    <$in> for 1..4;

    my ($sumWA, $totalArea) = (0.0, 0.0);

    while (my $line = <$in>) {
        next if $line =~ /^\s*$/;   # skip empty lines quickly

        # We only need: area (field 5), matFlag (field 11), normalStress (field 13)
        # Limit split so we don't allocate more than needed
        my @f = split ' ', $line, 14;

        my $matFlag = $f[10];
        next unless defined $matFlag && $matFlag == 3;

        my $area = $f[4];
        my $normalStress = $f[12];

        $totalArea += $area;
        $sumWA     += $normalStress * $area;
    }

    my $meanNormalStress = ($totalArea > 0) ? ($sumWA / $totalArea) : 0.0;
    print $out "$timeStep $meanNormalStress\n";
}



# #!/usr/bin/perl
# $deltaStep = 1;
# $numberOfSteps = 1500;

# open(FILEOUT, ">pressure.dat");
# print FILEOUT "0 0\n";

# $fileBase = "oofem.out.m1.";

# for($k = 1;$k<=$numberOfSteps/$deltaStep;$k++){
#     $timeStep = $k*$deltaStep;
#     open(FILEIN,"<$fileBase$timeStep.gp") || die "Could not open $fileName\n";
    
#     for($i = 0;$i<4;$i++){
#  	readline($line =<FILEIN>);
#     }
    
#     $elem=0;
#     $meanNormalStress = 0;
#     $totalArea = 0;
#     while($line = <FILEIN>) {
# 	$elem++;
# 	($junk, $junk, $junk, $junk, $area, $junk, $junk, $junk, $junk, $junk, $matFlag, $junk, $normalStress, $junk)=
# 	    split( /\s+/, $line);
# 	if($matFlag == 4){	
# 	    $totalArea += $area;
# 	    $meanNormalStress += $normalStress*$area;
# 	}	
#     }
#     $meanNormalStress/=$totalArea;
#     print FILEOUT "$timeStep $meanNormalStress\n";    
    
# }

