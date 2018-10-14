#run under the working dir
set REstep 2
set output "."

if { ![file exist $output] } {
  file mkdir $output
}

set input "pore-pcwi2-20ns"
#set input "step2/tmp"

if {$REstep==1} {
exec cp pore-pcwi.pdb $input.pdb
exec cp pore-pcwi.psf $input.psf
}

if { ![file exist $output/restraints] } {
  file  mkdir [file join $output restraints]
}

set RepNum 25
set SegIDi {"PROA" "PROB" "PROC" "PROD"}
set ResIDi {"155" "169" "172"}; #P1
#set ResIDi {"185" "186" "188"}; #P2
#set ResIDi {"169" "185" "191"}
#set molid_0 [mol load pdb pore-pcwi.pdb]
#set totNum [expr [llength $SegIDi]*[llength $ResIDi]*$RepNum]
#set molid_1 [mol load pdb ODUM.pdb]
#set seli [atomselect $molid_1 all]
#set reslabeli_unique [lsort -unique -integer [$seli get resid]]
#set reslabeli [$seli get resid]
#set namlabeli [$seli get name]

resetpsf
package require psfgen
topology /home/kinlam2/charmm/toppar/top_all36_prot.rtf
topology /home/kinlam2/charmm/toppar/top_all36_cgenff.rtf
topology /home/kinlam2/charmm/toppar/top_all36_lipid.rtf 
topology  /home/kinlam2/charmm/toppar/top_all36_carb.rtf 
topology  /home/kinlam2/charmm/toppar/toppar_water_ions_namd.str
topology  /home/kinlam2/charmm/toppar/top_all36_na.rtf
topology  /home/kinlam2/charmm/toppar/toppar_all36_label_spin.str
topology  ../dummyON.rtf

readpsf $input.psf
coordpdb $input.pdb



foreach segi $SegIDi {
                set nlabel 0
		foreach idi $ResIDi {   
		    # residue i
		   # set ref1i [atomselect $molid_0 "protein and segid $segi and resid $idi and backbone"]
		   # set com1i [atomselect $molid_1 "protein and backbone"]
		   # puts $idi
	           # puts $segi                    
	           # puts [$ref1i num]
                   # puts [$com1i num]
		   # set sel1i [atomselect $molid_1 "all"]
		   # $sel1i move [measure fit $com1i $ref1i]
                   # set ON [atomselect $molid_1 "name ON"]
                   #set CA [atomselect $molid_0 "protein and segid $segi and resid $idi and name CA"]
                   #set resnamei [$CA get resname]
                   #set chaini [$CA get chain] 	
                   # puts $resnamei
                   # puts $chaini
		   # set pos [$ON get {x y z}]
                   # puts $pos

                   #for {set ri 1} {$ri <= $RepNum} {incr ri} {

			incr nlabel
			#set snlabel [format "%03d" $nlabel]
			set seglabi "${segi}${nlabel}"
                        #puts $seglabi
			segment $seglabi {
			    first NONE
			    last NONE
			    residue $idi ONDS S
			}
                        #puts "$seglabi $idi ON $pos"
			#coord $seglabi $idi "ON" $pos #problem causing
                        patch SDUM $seglabi:$idi $segi:$idi
                        multiply $RepNum $seglabi:$idi:ON
		    #}
                    #$ref1i delete;  $com1i delete;  $sel1i delete; $ON delete 
		}
}

guesscoord
#command out, avoid non parameterized angles etc.
#regenerate angles 
#regenerate dihedrals

writepsf $output/Nav_ON.psf
writepdb $output/Nav_ON.pdb


if { 0 } {
foreach segi $SegIDi {
  foreach idi $ResIDi {   
    for {set i 1} {$i<=$RepNum} {incr i} {
      set seg [ [atomselect top "resid $idi and segname $segi and name CA"] get segname]
      set seglabi "${seg}${i}"
      set ON [atomselect top "resid $idi and segname $segi and beta $i"]
      $ON set segname $seglabi
      $ON delete
    }
  }
}

$all writepdb $output/Nav_ON.pdb
$all writepsf $output/Nav_ON.psf
}

mol load pdb $output/Nav_ON.pdb
set all [atomselect top all]
$all set beta 0
set b 0
foreach segi $SegIDi {
  foreach idi $ResIDi {   
    incr b
    set ON [atomselect top "resid $idi and segname $segi and name ON"]
    $ON set beta $b
    $ON delete
  }
}
$all writepdb $output/restraints/deer-colvar.pdb


source ../set_col_dummy.tcl
cd $output
set_col $SegIDi $ResIDi $RepNum $REstep
file copy ../namdconf/ONeq1.conf .
file copy ../namdconf/ONeq2.conf .
#file copy  ../namdconf/ONeq3.conf .
#file copy  ../namdconf/ONeq4.conf .
file copy  ../namdconf/ONp1.conf .
file copy  ../namdconf/pore-ss.txt ss.dat
exec cp -r ../toppar .
file delete tmp.psf tmp.pdb
cd ..

#mol load psf $output/Nav_ON.psf pdb $output/Nav_ON.pdb


