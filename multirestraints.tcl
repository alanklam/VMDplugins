#
# Multirestraints patch (VMD/psfgen)
#
# $Id: multirestraints.tcl,v 1.1 2013/12/9 $
#
# Last update: Kin, May7, 2018, v 1.2
# to do: fix salt bridge input format, fix path, put into VMD menu
package require psfgen
package require readcharmmtop 1.1
package provide multirestraints 1.1

namespace eval ::MultiRests:: {
    variable w
    # Input
    variable psfname
    variable pdbname
    variable prefix 
    variable topType
    
    # Add multirestraints    
    # 1) 
    variable mr1flag
    variable mr1Pick1
    variable mr1Pick2
    variable mr1Pick3
    variable mr1SegIDi
    variable mr1ResIDi
    variable mr1SegIDj
    variable mr1ResIDj  
    
    # 2)
    variable mr2flag
    variable mr2Pick1
    variable mr2Pick2
    variable mr2Pick3
    variable mr2SegIDi
    variable mr2ResIDi
    variable mr2SegIDj
    variable mr2ResIDj 
    
    # 3) 
    variable mr3flag
    variable mr3Pick1
    variable mr3Pick2
    variable mr3Pick3
    variable mr3SegIDi
    variable mr3ResIDi
    variable mr3SegIDj
    variable mr3ResIDj  
    
    # 4)
    variable mr4flag
    variable mr4Pick1
    variable mr4Pick2
    variable mr4Pick3
    variable mr4SegIDi
    variable mr4ResIDi
    variable mr4SegIDj
    variable mr4ResIDj 

    # 5) 
    variable mr5flag
    variable mr5Pick1
    variable mr5Pick2
    variable mr5Pick3
    variable mr5SegIDi
    variable mr5ResIDi
    variable mr5SegIDj
    variable mr5ResIDj  
    
    # 6)
    variable mr6flag
    variable mr6Pick1
    variable mr6Pick2
    variable mr6Pick3
    variable mr6SegIDi
    variable mr6ResIDi
    variable mr6SegIDj
    variable mr6ResIDj 
    
    # 7) 
    variable mr7flag
    variable mr7Pick1   
    variable mr7RepNum
    variable mr7SegIDi
    variable mr7ResIDi
 
}

proc multirestraints { args }  { return [eval ::MultiRests::multirestraints $args] }

proc ::MultiRests::multirestraints_usage { } {
    puts "Usage: multirestraints -psf <psffile> -pdb <pdbfile> {-o <prefix>} {-top <topType>} <option1> {<option2> <option3> <option4> <option5> <option6> <option7> <option8> } "
    puts "  <psffile> and <pdbfile> are .psf and .pdb files of the original model"
    puts "  <prefix> is optional output file prefix (default \"multirestraints\")"
    puts "  <topType> is optional and specifies lipid CHARMM topology (\"c27\" or \"c36\", default c36)"
    puts "  option1:"    
    puts "      -mr1 (adding multi-restraint 1)"
    puts "      -mr1pick1 <resname> (resname for dummy residue i; GLU/ASP/CYSN ...)"
    puts "      -mr1pick2 <resname> (resname for dummy residue k; Cd/Mg/Zn)"
    puts "      -mr1pick3 <resname> (resname for dummy residue j; GLU/ASP/CYSN ...)"
    puts "      -mr1rep <number> (copies (replicas) for patched atoms, default 1)"
    puts "      -mr1segi <segid> (segname(s) for targeting residue(s) i)"
    puts "      -mr1resi <resid> (resid(s) for targeting residue(s) i)"
    puts "      -mr1segj <segid> (segname(s) for targeting residue(s) j)"
    puts "      -mr1resj <resid> (resid(s) for targeting residue(s) j)"
    puts ""
    puts "  <prefix>-dummy.pdb: dummy segments"
    puts "  <prefix>_exclu.psf: exclusion list" 
    puts "  extrabonds.dat: extra-bonds restranits"     
    error ""
}

proc ::MultiRests::multirestraints { args } {
    global errorInfo errorCode
    set oldcontext [psfcontext new]  ;# new context
    set errflag [catch { eval multirestraints_core $args } errMsg]
    set savedInfo $errorInfo
    set savedCode $errorCode
    psfcontext $oldcontext delete  ;# revert to old context
    if $errflag { error $errMsg $savedInfo $savedCode }
}

proc ::MultiRests::multirestraints_core { args } {
    
    variable psfname
    variable pdbname
    variable prefix 
    variable topType
    
    # 1) 
    variable mr1flag
    variable mr1Pick1
    variable mr1Pick2
    variable mr1Pick3   
    variable mr1SegIDi
    variable mr1ResIDi
    variable mr1SegIDj
    variable mr1ResIDj  
    
    # 2)
    variable mr2flag
    variable mr2Pick1
    variable mr2Pick2
    variable mr2Pick3
    variable mr2SegIDi
    variable mr2ResIDi
    variable mr2SegIDj
    variable mr2ResIDj 

    # 3) 
    variable mr3flag
    variable mr3Pick1
    variable mr3Pick2
    variable mr3Pick3
    variable mr3SegIDi
    variable mr3ResIDi
    variable mr3SegIDj
    variable mr3ResIDj  
    
    # 4)
    variable mr4flag
    variable mr4Pick1
    variable mr4Pick2
    variable mr4Pick3
    variable mr4SegIDi
    variable mr4ResIDi
    variable mr4SegIDj
    variable mr4ResIDj 

    # 5) 
    variable mr5flag
    variable mr5Pick1
    variable mr5Pick2
    variable mr5Pick3
    variable mr5SegIDi
    variable mr5ResIDi
    variable mr5SegIDj
    variable mr5ResIDj  
    
    # 6)
    variable mr6flag
    variable mr6Pick1
    variable mr6Pick2
    variable mr6Pick3
    variable mr6SegIDi
    variable mr6ResIDi
    variable mr6SegIDj
    variable mr6ResIDj 
    
    # 7) 
    variable mr7flag
    variable mr7Pick1   
    variable mr7RepNum
    variable mr7SegIDi
    variable mr7ResIDi

    # Usage
    set n [llength $args]
    if { $n ==0 } { multirestraints_usage }
    
    # Scan for restraint types
    set argnum 0
    set arglist $args
    foreach i $args {
	if {$i == "-mr1"} {
	    set mr1flag 1
	    set arglist [lreplace $arglist $argnum $argnum]
	    continue
	}	
	if {$i == "-mr2"} {
	    set mr2flag 1
	    set arglist [lreplace $arglist $argnum $argnum]
	    continue
	}	
	if {$i == "-mr3"} {
	    set mr3flag 1
	    set arglist [lreplace $arglist $argnum $argnum]
	    continue
	}
	if {$i == "-mr4"} {
	    set mr4flag 1
	    set arglist [lreplace $arglist $argnum $argnum]
	    continue
	}
	if {$i == "-mr5"} {
	    set mr5flag 1
	    set arglist [lreplace $arglist $argnum $argnum]
	    continue
	}
	if {$i == "-mr6"} {
	    set mr6flag 1
	    set arglist [lreplace $arglist $argnum $argnum]
	    continue
	}
	if {$i == "-mr7"} {
	    set mr7flag 1
	    set arglist [lreplace $arglist $argnum $argnum]
	    continue
	}
	incr argnum
    }	
    
    # Scan for options with one argument
    foreach {i j} $arglist {
	if {$i=="-psf"}   then { set psfname $j; continue }
	if {$i=="-pdb"}   then { set pdbname $j; continue }
	if {$i=="-o"}     then { set prefix  $j; continue }
	if {$i=="-top"}   then { set topType $j; puts $topType; continue }
	
	if {$i=="-mr1pick1"}  then { set mr1Pick1  $j; continue }
	if {$i=="-mr1pick2"}  then { set mr1Pick2  $j; continue }
	if {$i=="-mr1pick3"}  then { set mr1Pick3  $j; continue }
	if {$i=="-mr1segi"}   then { set mr1SegIDi $j; continue }
	if {$i=="-mr1segj"}   then { set mr1SegIDj $j; continue }
	if {$i=="-mr1resi"}   then { set mr1ResIDi $j; continue }
	if {$i=="-mr1resj"}   then { set mr1ResIDj $j; continue }
	
	if {$i=="-mr2pick1"}  then { set mr2Pick1  $j; continue }
	if {$i=="-mr2pick2"}  then { set mr2Pick2  $j; continue }
	if {$i=="-mr2pick3"}  then { set mr2Pick3  $j; continue }
	if {$i=="-mr2segi"}   then { set mr2SegIDi $j; continue }
	if {$i=="-mr2segj"}   then { set mr2SegIDj $j; continue }
	if {$i=="-mr2resi"}   then { set mr2ResIDi $j; continue }
	if {$i=="-mr2resj"}   then { set mr2ResIDj $j; continue }

	if {$i=="-mr3pick1"}  then { set mr3Pick1  $j; continue }
	if {$i=="-mr3pick2"}  then { set mr3Pick2  $j; continue }
	if {$i=="-mr3pick3"}  then { set mr3Pick3  $j; continue }
	if {$i=="-mr3segi"}   then { set mr3SegIDi $j; continue }
	if {$i=="-mr3segj"}   then { set mr3SegIDj $j; continue }
	if {$i=="-mr3resi"}   then { set mr3ResIDi $j; continue }
	if {$i=="-mr3resj"}   then { set mr3ResIDj $j; continue }

	if {$i=="-mr4pick1"}  then { set mr4Pick1  $j; continue }
	if {$i=="-mr4pick2"}  then { set mr4Pick2  $j; continue }
	if {$i=="-mr4pick3"}  then { set mr4Pick3  $j; continue }
	if {$i=="-mr4segi"}   then { set mr4SegIDi $j; continue }
	if {$i=="-mr4segj"}   then { set mr4SegIDj $j; continue }
	if {$i=="-mr4resi"}   then { set mr4ResIDi $j; continue }
	if {$i=="-mr4resj"}   then { set mr4ResIDj $j; continue }

	if {$i=="-mr5pick1"}  then { set mr5Pick1  $j; continue }
	if {$i=="-mr5pick2"}  then { set mr5Pick2  $j; continue }
	if {$i=="-mr5pick3"}  then { set mr5Pick3  $j; continue }
	if {$i=="-mr5segi"}   then { set mr5SegIDi $j; continue }
	if {$i=="-mr5segj"}   then { set mr5SegIDj $j; continue }
	if {$i=="-mr5resi"}   then { set mr5ResIDi $j; continue }
	if {$i=="-mr5resj"}   then { set mr5ResIDj $j; continue }

	if {$i=="-mr6pick1"}  then { set mr6Pick1  $j; continue }
	if {$i=="-mr6pick2"}  then { set mr6Pick2  $j; continue }
	if {$i=="-mr6pick3"}  then { set mr6Pick3  $j; continue }
	if {$i=="-mr6segi"}   then { set mr6SegIDi $j; continue }
	if {$i=="-mr6segj"}   then { set mr6SegIDj $j; continue }
	if {$i=="-mr6resi"}   then { set mr6ResIDi $j; continue }
	if {$i=="-mr6resj"}   then { set mr6ResIDj $j; continue }

	if {$i=="-mr7pick1"}  then { set mr7Pick1  $j; continue }
	if {$i=="-mr7rep"}    then { set mr7RepNum $j; continue }
	if {$i=="-mr7segi"}   then { set mr7SegIDi $j; continue }
	if {$i=="-mr7resi"}   then { set mr7ResIDi $j; continue }
    }

    # reset psfgen
    psfcontext reset
    
    # set package WD and files
    global env 
    #set dircur [file normalize [file dirname [info script]]]
    set dircur /Projects/kinlam2/ReMD/VMD-plugin/
    if { $topType == "c36" } {
	#set topfile [file join $env(CHARMMTOPDIR) top_all36_lipid.rtf]
        set topfile /home/kinlam2/charmm/toppar/top_all36_lipid.rtf
        #set topfile1 [file join [file normalize [file dirname [info script]]] top_all36_prot.rtf]
        set topfile1 /home/kinlam2/charmm/toppar/top_all36_prot.rtf
        topology $topfile
        topology $topfile1 
        topology $dircur/top_CYR1_c36.inp
        topology $dircur/top_CYSN_c36.inp
        topology $dircur/top_HISN_c36.inp
        topology $dircur/top_ONDUM_c36.inp        
        topology $dircur/top_ions.inp
        topology $dircur/dummyON.rtf
    } else {
	set topfile2 [file join $env(CHARMMTOPDIR) top_all27_prot_lipid_na.inp]
        topology $topfile2 
        topology $dircur/top_CYR1_c27.inp
        topology $dircur/top_CYSN_c27.inp
        topology $dircur/top_HISN_c27.inp
        topology $dircur/top_ONDUM_c27.inp 
        topology $dircur/top_ions.inp
        topology $dircur/dummyON.rtf       
    }
    set tempfile temp
    
    resetpsf
    
    set molid_0 [mol load psf $psfname pdb $pdbname]
    set exlist1 {}
    set exlist2 {}
    set exlist3 {}
    set exlist4 {} 
    
    #####################
    # Metal/Salt Bridges
    #####################
    set M "mr1flag mr2flag mr3flag mr4flag mr5flag mr6flag"
    set N "$mr1flag $mr2flag $mr3flag $mr4flag $mr5flag $mr6flag"
    foreach m $M n $N {
	if {$n>0} {
	    if {$m == "mr1flag"} {
		set Pick1    $mr1Pick1;  set Pick2    $mr1Pick2;  set Pick3  $mr1Pick3;
		set SegIDi   $mr1SegIDi; set SegIDj   $mr1SegIDj; set chaID F;
		set ResIDi   $mr1ResIDi; set ResIDj   $mr1ResIDj; set segL F1;  
		set resname1 $mr1Pick1;  set resname2 $mr1Pick2;  set resname3 $mr1Pick3; set tempfile mr1;
	    }
	    if {$m == "mr2flag"} {
		set Pick1    $mr2Pick1;  set Pick2    $mr2Pick2;  set Pick3  $mr2Pick3;
		set SegIDi   $mr2SegIDi; set SegIDj   $mr2SegIDj; set chaID F;
		set ResIDi   $mr2ResIDi; set ResIDj   $mr2ResIDj; set segL F2; 
		set resname1 $mr2Pick1;  set resname2 $mr2Pick2;  set resname3 $mr2Pick3; set tempfile mr2;
	    }
	    if {$m == "mr3flag"} {
		set Pick1    $mr3Pick1;  set Pick2    $mr3Pick2;  set Pick3  $mr3Pick3;
		set SegIDi   $mr3SegIDi; set SegIDj   $mr3SegIDj; set chaID F;
		set ResIDi   $mr3ResIDi; set ResIDj   $mr3ResIDj; set segL F3; 
		set resname1 $mr3Pick1;  set resname2 $mr3Pick2;  set resname3 $mr3Pick3; set tempfile mr3;
	    }
	    if {$m == "mr4flag"} {
		set Pick1    $mr4Pick1;  set Pick2    $mr4Pick2;  set Pick3  $mr4Pick3;
		set SegIDi   $mr4SegIDi; set SegIDj   $mr4SegIDj; set chaID F;
		set ResIDi   $mr4ResIDi; set ResIDj   $mr4ResIDj; set segL F4; 
		set resname1 $mr4Pick1;  set resname2 $mr4Pick2;  set resname3 $mr4Pick3; set tempfile mr4;
	    }
	    if {$m == "mr5flag"} {
		set Pick1    $mr5Pick1;  set Pick2    $mr5Pick2;  set Pick3  $mr5Pick3;
		set SegIDi   $mr5SegIDi; set SegIDj   $mr5SegIDj; set chaID F;
		set ResIDi   $mr5ResIDi; set ResIDj   $mr5ResIDj; set segL F5; 
		set resname1 $mr5Pick1;  set resname2 $mr5Pick2;  set resname3 $mr5Pick3; set tempfile mr5;
	    }
	    if {$m == "mr6flag"} {
		set Pick1    $mr6Pick1;  set Pick2    $mr6Pick2;  set Pick3  $mr6Pick3;
		set SegIDi   $mr6SegIDi; set SegIDj   $mr6SegIDj; set chaID F;
		set ResIDi   $mr6ResIDi; set ResIDj   $mr6ResIDj; set segL F6; 
		set resname1 $mr6Pick1;  set resname2 $mr6Pick2;  set resname3 $mr6Pick3; set tempfile mr6;
	    }
	    
	    #set dircur [file normalize [file dirname [info script]]]
            set dircur /Projects/kinlam2/ReMD/VMD-plugin/

	    resetpsf    

	    set molid_1 [mol load pdb $dircur/$Pick1.pdb]
	    set molid_3 [mol load pdb $dircur/$Pick3.pdb]
	    set seli [atomselect $molid_1 all]
	    set reslabeli_unique [lsort -unique -integer [$seli get resid]]
	    set reslabeli [$seli get resid]
	    set namlabeli [$seli get name]
	    set selj [atomselect $molid_3 all]
	    set reslabelj_unique [lsort -unique -integer [$selj get resid]]
	    set reslabelj [$selj get resid]
	    set namlabelj [$selj get name]
	    
	    set nlabel 0
	    
	    foreach segi $SegIDi resi $ResIDi segj $SegIDj resj $ResIDj  {
		foreach idi $resi idj $resj {
		    
		    incr nlabel
		    
		    # residue i
		    set ref1i [atomselect $molid_0 "protein and segid $segi and resid $idi and backbone"]
		    set com1i [atomselect $molid_1 "protein and backbone"]
		    set sel1i [atomselect $molid_1 "all"]
		    $sel1i move [measure fit $com1i $ref1i]	
		    
		    # set seglab "${segL}1${nlabel}"
		    set seglabi "${segL}${nlabel}1"
		    lappend exlist1 "$segi $idi"
		    lappend exlist2 "$seglabi $idi"
                    if {$resname1=="HISND" || $resname1=="HISNE"} {
			set resname1r HISN
		    } else {
			set resname1r $resname1
		    }
		    segment $seglabi {
			first NONE
			last NONE
			residue $idi $resname1r $chaID 
		    }
		    foreach name $namlabeli pos [$seli get {x y z}] {
			coord $seglabi $idi $name $pos
		    }
		    $ref1i delete;  $com1i delete;  $sel1i delete
		    
		    # residue j  
		    set ref1j [atomselect $molid_0 "protein and segid $segj and resid $idj and backbone"]
		    set com1j [atomselect $molid_3 "protein and backbone"]
		    set sel1j [atomselect $molid_3 "all"]
		    $sel1j move [measure fit $com1j $ref1j]	
    
		    set seglabj "${segL}${nlabel}3"
		    lappend exlist1 "$segj $idj"
		    lappend exlist2 "$seglabj $idj"
                    if {$resname3=="HISND" || $resname3=="HISNE"} {
			set resname3r HISN
		    } else {
			set resname3r $resname3
		    }	
		    segment $seglabj {
			first NONE
			last NONE
			residue $idj $resname3r $chaID
		    }
		    foreach name $namlabelj pos [$selj get {x y z}] {
			coord $seglabj $idj $name $pos
		    }
		    $ref1j delete;  $com1j delete;  $sel1j delete
		    
		    # residue k (ion)
		    
		    if { $Pick2 == "Cd" || $Pick2 == "Mg" || $Pick2 == "Zn"} {
			
			if {$Pick2 == "Cd"} {
			    set resname2 CD2; 
			} elseif {$Pick2 == "Mg"} {
			    set resname2 MG; 
			} elseif {$Pick2 == "Zn"} { 
			    set resname2 ZN2; 
			}
			#		set molid_2 [mol load psf $dircur/$Pick2.psf pdb $dircur/$Pick2.pdb]
			set molid_2 [mol load pdb $dircur/$Pick2.pdb]
			set selk [atomselect $molid_2 "all"]
			set reslabelk [$selk get resid]
			set namlabelk [$selk get name]
			
			set selatoms [atomselect $molid_0 "(segid $segi and resid $idi and name CA) or (segid $segj and resid $idj and name CA)"]
			set center [measure center $selatoms]
#			puts $center
			$selk moveto $center				
			set seglabk "${segL}${nlabel}2"
			segment $seglabk {
			    first NONE
			    last NONE
			    residue $reslabelk $resname2 $chaID
			}
			foreach res $reslabelk name $namlabelk pos [$selk get {x y z}] {
			    coord $seglabk $res $name $pos
			}
			$selatoms delete;  
                        if {$resname1 == "CYSN"} {
			    set aname1 SG
			} elseif {$resname1 == "HISND"} {
			    set aname1 ND1;
			} elseif {$resname1 == "HISNE"} {
			    set aname1 NE2;
			} elseif {$resname1 == "ASP"} {
			    set aname1 OD2
			} elseif {$resname1 == "GLU"} {
			    set aname1 OE2
			} else {
			    set aname1 CA
			}
			if {$resname3 == "CYSN"} {
			    set aname3 SG
			} elseif {$resname3 == "HISND"} {
			    set aname3 ND1;
			} elseif {$resname3 == "HISNE"} {
			    set aname3 NE2;
			} elseif {$resname3 == "ASP"} {
			    set aname3 OD2
			} elseif {$resname3 == "GLU"} {
			    set aname3 OE2
			} else {
			    set aname3 CA
			}
			lappend exlist3 "${segL}${nlabel}1 $aname1 ${segL}${nlabel}2 ${segL}${nlabel}3 $aname3"
			
			$selk delete
			mol delete $molid_2
		    }
		}
	    }
	    
	    # write out temp files
	    writepsf $tempfile.psf
	    writepdb $tempfile.pdb
	    
	    $seli delete;  mol delete $molid_1;  
            $selj delete;  mol delete $molid_3;
	    
	}
    }
    
    #####################
    # Spin Labels
    #####################
    
    set M "mr7flag"
    set N "$mr7flag"
    foreach m $M n $N {
	if {$n>0} {
	    if {$m == "mr7flag"} {
		set Pick1    $mr7Pick1;  
		set SegIDi   $mr7SegIDi; set RepNum $mr7RepNum;
		set ResIDi   $mr7ResIDi; set segL S; set chaID S;
		set resname1 $mr7Pick1;  set tempfile mr7;
	    }
	    
	    #set dircur [file normalize [file dirname [info script]]]
            set dircur /Projects/kinlam2/ReMD/VMD-plugin/
	    resetpsf    
	    
	    set molid_1 [mol load pdb $dircur/$Pick1.pdb]
	    set seli [atomselect $molid_1 all]
	    set reslabeli_unique [lsort -unique -integer [$seli get resid]]
	    set reslabeli [$seli get resid]
	    set namlabeli [$seli get name]
	    
	    set nlabel 0
	    
#Kin: changed to accept the input format segid: A B resid: id1 id2 (no curly brackets) for polymeric systems
#To do: Adopt the implementation CharmmGui, attach ON to Ca
	    foreach segi $SegIDi {
		foreach idi $ResIDi {   
		    # residue i
		    set ref1i [atomselect $molid_0 "protein and segid $segi and resid $idi and backbone"]
		    set com1i [atomselect $molid_1 "protein and backbone"]
		    puts $idi
	            puts $segi                    
	            puts [$ref1i num]
                    puts [$com1i num]
		    set sel1i [atomselect $molid_1 "all"]
		    $sel1i move [measure fit $com1i $ref1i]	
		    
                    for {set ri 1} {$ri <= $RepNum} {incr ri} {
			
			incr nlabel
			set snlabel [format "%03d" $nlabel]
			set seglabi "${segL}${snlabel}"
			
			lappend exlist1 "$segi $idi"
			lappend exlist2 "$seglabi $idi"
			lappend exlist4 "$seglabi $idi"                    
			segment $seglabi {
			    first NONE
			    last NONE
			    residue $idi $resname1 $chaID 
			}
			foreach name $namlabeli pos [$seli get {x y z}] {
			    coord $seglabi $idi $name $pos
			}
		    }
                    $ref1i delete;  $com1i delete;  $sel1i delete 
		}
	    }
	    
	    # write out temp files
	    writepsf $tempfile.psf
	    writepdb $tempfile.pdb
	    
	    $seli delete;  mol delete $molid_1;  	    
	}
    }
    
    mol delete $molid_0    
    
    ## Patching
    #    
    resetpsf
    readpsf  $psfname
    coordpdb $pdbname
    set K "mr1 mr2 mr3 mr4 mr5 mr6 mr7"
    set T "$mr1flag $mr2flag $mr3flag $mr4flag $mr5flag $mr6flag $mr7flag"
    foreach k $K t $T {
	if {$t>0} {
	    readpsf $k.psf
	    coordpdb $k.pdb
	}
    }
    
    writepsf temp-label.psf
    writepdb temp-label.pdb
    
    resetpsf
    readpsf temp-label.psf
    coordpdb temp-label.pdb
   
    
    # write out the resulting files
    writepsf $prefix.psf
    writepdb $prefix.pdb
    
    # clean up
    puts "deleting temporary files"
    
    foreach tempfile { temp-label mr1 mr2 mr3 mr4 mr5 mr6 mr7} {
	if {[file exist $tempfile.psf]} {file delete $tempfile.psf} 
	if {[file exist $tempfile.pdb]} {file delete $tempfile.pdb}   
    }
    
    # update displayed molecule
    mol load psf $prefix.psf pdb $prefix.pdb
    
    # move ions to the center of dummy fragments, e.g. SG-Cd-SG
    set sel [atomselect top all]
    foreach ex3 $exlist3 {
	foreach {seg1 aname1 seg2 seg3 aname3} $ex3 {}	
	set res_13 [atomselect top "segid $seg1 and name $aname1 or segid $seg3 and name $aname3"]
	set res_2 [atomselect top "segid $seg2"]
	set cen_ion [measure center $res_13]
	$res_2 moveto $cen_ion
	$res_13 delete
	$res_2 delete
    }
    $sel writepdb $prefix.pdb
    
    #  
    # Set exclusion list (psffile)/dummy fragment (pdbfile)/extrabonds restraints (dat)
    #    
    set exlist {}
    foreach ex1 $exlist1 ex2 $exlist2 {
	foreach {segex1 idex1} $ex1 {}
	foreach {segex2 idex2} $ex2 {}


	set res_i [atomselect top "segid $segex1 and resid $idex1"]
	set index_i [$res_i get index]
	set res_j [atomselect top "segid $segex2 and resid $idex2"]
	set index_j [$res_j get index]
	foreach i $index_i {
	    foreach j $index_j {
		lappend exlist "$i $j"
	    }
	}
	$res_i delete
	$res_j delete

	set idex11 "[expr $idex1 - 1] [expr $idex1 + 1]"
	set res_i [atomselect top "segid $segex1 and resid $idex11 and not sidechain"]
	set index_i [$res_i get index]
	set res_j [atomselect top "segid $segex2 and resid $idex2 and not sidechain"]
	set index_j [$res_j get index]
	foreach i $index_i {
	    foreach j $index_j {
		lappend exlist "$i $j"
	    }
	}
	$res_i delete
	$res_j delete	
    }

    if { [info exists elist] } {
	unset elist
    } 
    set fil [open ./$prefix.psf r]
    set infile [split [read $fil] \n]
    close $fil
    set outfile [open ./$prefix\_exclu.psf w]
    set resume 1
    foreach x $infile {
	if {[lsearch $x "!NATOM"]==1} {
	    set exclu_a {}
	    set exclu_b {}
	    set cidx 0
	    set Num_atoms [lindex $x 0]
	    for {set i 0} {$i < $Num_atoms} {incr i} {
		set elist($i) {}
	    }
	    foreach idx $exlist {
		set idx_0 [lindex $idx 0]
		set idx_1 [lindex $idx 1]
		if {$idx_0 < $idx_1} {
		    lappend elist($idx_0) $idx_1
		} else {
		    lappend elist($idx_1) $idx_0
		}	
	    }
	    for {set i 0} {$i < $Num_atoms} {incr i} {
		set num_pairs [llength $elist($i)] 
		if {$num_pairs>0} {
		    foreach idx_i $elist($i) {
			lappend exclu_a [expr $idx_i +  1]
		    }
		    set cidx [expr $cidx + $num_pairs]
		}
		lappend exclu_b $cidx
	    }
	}
	if {[lsearch $x "!NNB"]==1} {
	    set resume 0
	    puts $outfile [format "%8d %4s" [llength $exclu_a] "!NNB"]
	    set num_j 0
	    set outline ""
	    foreach j $exclu_a {   
		set outline "$outline [format "%7d" $j]"
		if {[expr $num_j%8+1] == 8} {
		    puts $outfile $outline
		    set outline ""
		}
		incr num_j
	    }
	    puts $outfile $outline
	    puts $outfile ""
	    
	    set num_j 0
	    set outline ""
	    foreach j $exclu_b {   
		set outline "$outline [format "%7d" $j]"
		if {[expr $num_j%8+1] == 8} {
		    puts $outfile $outline
		    set outline ""
		}
		incr num_j
	    }
	    puts $outfile $outline	
	    puts $outfile ""
	}
	
	if {[lsearch $x "!NGRP"]==2} {
	    set resume 1
	}
	if {$resume==1} {
	    puts $outfile $x
	}
    }
    close $outfile
    #  
    # define dummy fragments
    #  
    set sel [atomselect top all]
    $sel set beta 0
    # metal/salt bridges
    set segidX [lsort -unique [$sel get segid]]
    set tagXi {}
    foreach ids {1 2 3 4 5 6} {
	set tagX "F$ids"
	foreach segtag $segidX {
	    if {[string range $segtag 0 1] == $tagX} {
		lappend tagXi [string range $segtag 0 2]
	    }
	}
    }
    set tagXi [lsort -unique $tagXi]
    set nbeta 0
    foreach Xi $tagXi {
	incr nbeta
	set r1 1; set r2 2; set r3 3;
	set dumSeg "$Xi$r1 $Xi$r2 $Xi$r3"
	set selid [atomselect top "segid $dumSeg"]
	$selid set beta $nbeta
	$selid delete
    }

    # spin labels
    foreach Sres $exlist4 {
	foreach {segSi resSi} $Sres {}
	incr nbeta
 	set selid [atomselect top "segid $segSi and resid $resSi"]
	$selid set beta $nbeta
	$selid delete
    }    
    
    $sel writepdb $prefix-dummy.pdb
    $sel delete  
    #  
    # define extrabond interactons
    #  
    set outfile [open $prefix-extrabonds.dat w]
    set ang_ion 180;
    set k_ang 10;
    set k_dis 10; 
    set dis_cd 2.6;
    set dis_mg 2.1;
    set dis_zn 2.1;
    foreach ex3 $exlist3 {
	foreach {seg1 aname1 seg2 seg3 aname3} $ex3 {}
	set res_1 [atomselect top "segid $seg1 and name $aname1"]
	set res_2 [atomselect top "segid $seg2"]
	set res_3 [atomselect top "segid $seg3 and name $aname3"]
	set index_1 [$res_1 get index]
	set index_2 [$res_2 get index]
	set index_3 [$res_3 get index]
	set name_2 [$res_2 get resname]
	if {$name_2 == "CD2"} {
	    set dis_ion $dis_cd
	} elseif {$name_2 == "MG"} {
	    set dis_ion $dis_mg
	} elseif {$name_2 == "ZN2"} {
	    set dis_ion $dis_zn
	}
	if {$name_2 == "ZN2"} {
	    set k_dihe 10;
	    set k_impr 10;
	    set ang_zn_1 127.00;
	    set ang_zn_2 125.50;
	    set dihe_zn 180.00;
	    set impr_zn 0.00;
	    if {$aname1=="ND1"} {
		set res_11 [atomselect top "segid $seg1 and name CB"]
		set res_12 [atomselect top "segid $seg1 and name CE1"]
		set res_13 [atomselect top "segid $seg1 and name CG"]
		set index_11 [$res_11 get index]
		set index_12 [$res_12 get index]
		set index_13 [$res_13 get index]		
	    } elseif {$aname1=="NE2"} {
		set res_11 [atomselect top "segid $seg1 and name CG"]
		set res_12 [atomselect top "segid $seg1 and name CE1"]
		set res_13 [atomselect top "segid $seg1 and name CD2"]
		set index_11 [$res_11 get index]
		set index_12 [$res_12 get index]
		set index_13 [$res_13 get index]
	    }
	    if {$aname3=="ND1"} {
		set res_31 [atomselect top "segid $seg3 and name CB"]
		set res_32 [atomselect top "segid $seg3 and name CE1"]
		set res_33 [atomselect top "segid $seg3 and name CG"]
		set index_31 [$res_31 get index]
		set index_32 [$res_32 get index]  
		set index_33 [$res_33 get index]
	    } elseif {$aname3=="NE2"} {
		set res_31 [atomselect top "segid $seg3 and name CG"]
		set res_32 [atomselect top "segid $seg3 and name CE1"]
		set res_33 [atomselect top "segid $seg3 and name CD2"]
		set index_31 [$res_31 get index]
		set index_32 [$res_32 get index]  
		set index_33 [$res_33 get index]
	    }
	    
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.2f\t%.2f\t" "bond" $index_1 $index_2 $k_dis $dis_ion]
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.2f\t%.2f\t" "bond" $index_3 $index_2 $k_dis $dis_ion]	    
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "angle"  $index_12 $index_1 $index_2 $k_ang $ang_zn_1]
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "angle"  $index_13 $index_1 $index_2 $k_ang $ang_zn_2]
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "angle"  $index_32 $index_3 $index_2 $k_ang $ang_zn_1]
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "angle"  $index_33 $index_3 $index_2 $k_ang $ang_zn_2]
	    puts $outfile [format "%-8s\t%.0f\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "dihedral" $index_11 $index_13 $index_1 $index_2 $k_dihe $dihe_zn]
	    puts $outfile [format "%-8s\t%.0f\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "dihedral" $index_31 $index_33 $index_3 $index_2 $k_dihe $dihe_zn] 
	    puts $outfile [format "%-8s\t%.0f\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "improper" $index_1 $index_12 $index_13 $index_2 $k_impr $impr_zn]
	    puts $outfile [format "%-8s\t%.0f\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "improper" $index_1 $index_13 $index_12 $index_2 $k_impr $impr_zn] 
	    puts $outfile [format "%-8s\t%.0f\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "improper" $index_3 $index_32 $index_33 $index_2 $k_impr $impr_zn]
	    puts $outfile [format "%-8s\t%.0f\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "improper" $index_3 $index_33 $index_32 $index_2 $k_impr $impr_zn] 
	    
	    $res_11 delete
	    $res_12 delete
	    $res_13 delete
	    $res_31 delete
	    $res_32 delete
	    $res_33 delete
	    
	} else {
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.2f\t%.2f\t" "bond" $index_1 $index_2 $k_dis $dis_ion]
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.2f\t%.2f\t" "bond" $index_3 $index_2 $k_dis $dis_ion]
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.0f\t%.2f\t%.2f\t" "angle" $index_1 $index_2 $index_3 $k_ang $ang_ion] 
	}
	
	$res_1 delete
	$res_2 delete
	$res_3 delete
    }
    
    set k_bk 10; # kcal/mol/A2 ; backbone atoms, Kin: changed to 10 following charmmGUI
    foreach ex1 $exlist1 ex2 $exlist2 {
	foreach {segex1 idex1} $ex1 {}
	foreach {segex2 idex2} $ex2 {}
	set res_i [atomselect top "segid $segex1 and resid $idex1 and backbone"]
	set index_i [$res_i get index]
	set res_j [atomselect top "segid $segex2 and resid $idex2 and backbone"]
	set index_j [$res_j get index]	
	foreach indi $index_i indj $index_j {
	    set d_bk 0.0
	    puts $outfile [format "%-5s\t%.0f\t%.0f\t%.2f\t%.2f\t" "bond" $indi $indj $k_bk $d_bk]
	}	
	$res_i delete
	$res_j delete
    }
    close $outfile
}

proc ::MultiRests::multirestraints_gui {} {
    variable w
    variable psfname
    variable pdbname
    variable prefix 
    variable topType
    
    # 1) 
    variable mr1flag
    variable mr1Pick1
    variable mr1Pick2
    variable mr1Pick3
    variable mr1SegIDi
    variable mr1ResIDi
    variable mr1SegIDj
    variable mr1ResIDj  
    
    # 2)
    variable mr2flag
    variable mr2Pick1
    variable mr2Pick2
    variable mr2Pick3
    variable mr2SegIDi
    variable mr2ResIDi
    variable mr2SegIDj
    variable mr2ResIDj 
    
    # 3) 
    variable mr3flag
    variable mr3Pick1
    variable mr3Pick2
    variable mr3Pick3    
    variable mr3SegIDi
    variable mr3ResIDi
    variable mr3SegIDj
    variable mr3ResIDj  
    
    # 4)
    variable mr4flag
    variable mr4Pick1
    variable mr4Pick2
    variable mr4Pick3    
    variable mr4SegIDi
    variable mr4ResIDi
    variable mr4SegIDj
    variable mr4ResIDj 
    
    # 5) 
    variable mr5flag
    variable mr5Pick1
    variable mr5Pick2
    variable mr5Pick3    
    variable mr5SegIDi
    variable mr5ResIDi
    variable mr5SegIDj
    variable mr5ResIDj  
    
    # 6)
    variable mr6flag
    variable mr6Pick1
    variable mr6Pick2
    variable mr6Pick3    
    variable mr6SegIDi
    variable mr6ResIDi
    variable mr6SegIDj
    variable mr6ResIDj 
    
    # 7) 
    variable mr7flag
    variable mr7Pick1   
    variable mr7RepNum
    variable mr7SegIDi
    variable mr7ResIDi
 

 
    if { [winfo exists .multirestraints] } {
        wm deiconify $w
        return
    }
    
    set w [toplevel ".multirestraints"]
    wm title $w "MultiRestraints"
    wm resizable $w yes yes
    set row 0
    
    set ::MultiRests::prefix "multirestraints"
    set ::MultiRests::topType "c36"
    set ::MultiRests::mr7RepNum 1 

    set ::MultiRests::mr1flag 0  
    set ::MultiRests::mr2flag 0
    set ::MultiRests::mr3flag 0
    set ::MultiRests::mr4flag 0
    set ::MultiRests::mr5flag 0
    set ::MultiRests::mr6flag 0
    set ::MultiRests::mr7flag 0
                                                                                             
    #Add a menubar
    frame $w.menubar -relief raised -bd 2
    grid  $w.menubar -padx 1 -column 0 -columnspan 10 -row $row -sticky ew
    menubutton $w.menubar.help -text "Help" -underline 0 \
	-menu $w.menubar.help.menu
    $w.menubar.help config -width 5
    pack $w.menubar.help -side right
    
    ## help menu
    menu $w.menubar.help.menu -tearoff no
    $w.menubar.help.menu add command -label "About" \
	-command {tk_messageBox -type ok -title "About MultiRestraints" \
		      -message "A tool for adding multirestraints to a model."}
    #   $w.menubar.help.menu add command -label "Help..." \
	#  -command "vmd_open_url [string trimright [vmdinfo www] /]/plugins/multirestraints"
    incr row
    
    # Input psf and pdb files
    
    grid [label $w.notelabel1 -text "Input "] \
	-row $row -column 0 -columnspan 2 -sticky w
    incr row
    
    grid [label $w.emptyrow1 -text ""] \
	-row $row -column 0 -columnspan 2 -sticky w
    incr row  
    
    grid [label $w.psflabel -width 6 -text "PSF: "] -row $row -column 0 -columnspan 1 -sticky w
    grid [entry $w.psffile -width 46 -textvar [namespace current]::psfname] -row $row -column 2 -columnspan 7 -sticky w
    frame $w.psfbutton 
    button $w.psfbutton.psfbrowse -text "Browse" -command [ namespace code {
        set filetypes { 
	    {{PSF file} {.psf}}
	    {{All Files} {*}}
        }
        set ::MultiRests::psfname [tk_getOpenFile -filetypes $filetypes]
    }]							   
    pack $w.psfbutton.psfbrowse -side left -fill x 
    grid $w.psfbutton -row $row -column 9 -columnspan 1 -sticky nsew 
    incr row
    
    grid [label $w.pdblabel -width 6 -text "PDB: "] -row $row -column 0 -columnspan 1 -sticky w
    grid [entry $w.pdbfile -width 46 -textvar [namespace current]::pdbname] -row $row -column 2 -columnspan 7 -sticky w
    frame $w.pdbbutton 
    button $w.pdbbutton.pdbbrowse -text "Browse" -command [ namespace code {
        set filetypes { 
	    {{PDB file} {.pdb}}
	    {{All Files} {*}}
        }
        set ::MultiRests::pdbname [tk_getOpenFile -filetypes $filetypes]
    }]
    pack $w.pdbbutton.pdbbrowse -side left -fill x 
    grid $w.pdbbutton -row $row -column 9 -columnspan 1 -sticky nsew 
    incr row

    grid [label $w.prelabel -text "Output Prefix:"] \
	-row $row -column 0 -columnspan 2 -sticky w
    grid [entry $w.prefix -width 46 -textvariable ::MultiRests::prefix] -row $row -column 2 -columnspan 7 -sticky w
    incr row
    
    #Select the topology type
    grid [label $w.toppicklab -text "Topology: "] \
	-row $row -column 0 -columnspan 2 -sticky w
    grid [menubutton $w.toppick -width 45 -textvar ::MultiRests::topType \
	      -menu $w.toppick.menu -relief raised] \
	-row $row -column 2 -columnspan 7 -sticky w
    menu $w.toppick.menu -tearoff no
    $w.toppick.menu add command -label "CHARMM27" \
	-command {set ::MultiRests::topType "c27" }
    $w.toppick.menu add command -label "CHARMM36" \
	-command {set ::MultiRests::topType "c36" }
    incr row
    
    grid [label $w.emptyrow2 -text ""] \
	-row $row -column 0 -columnspan 2 -sticky w
    incr row  
    
    # Select the restraint type

    grid [label $w.notelabel2 -text "Metal/Salt Bridges "] \
	-row $row -column 0 -columnspan 3 -sticky w
    incr row
    
    grid [label $w.emptyrow3 -width 8 -text ""] \
	-row $row -column 0 -columnspan 1 -sticky w
    incr row 
    
    grid [label $w.notelabel3 -width 7 -text "Type   "] \
	-row $row -column 1 -columnspan 1 -sticky w  
    grid [label $w.notelabel4 -width 10 -text "Residue i"] \
	-row $row -column 6 -columnspan 2 -sticky w
    grid [label $w.notelabel5 -width 10 -text "Residue j"] \
	-row $row -column 8 -columnspan 2 -sticky w
    incr row
    
    # MultiRestraint 1
    
    grid [checkbutton $w.mr1 -text " MR: 1 " -width 6 -variable ::MultiRests::mr1flag] \
	-row $row -column 0 -columnspan 1 -sticky w
    
    grid [menubutton $w.mr1pick1 -width 6 -textvar ::MultiRests::mr1Pick1 \
	      -menu $w.mr1pick1.menu -relief raised] \
	-row $row -column 1 -columnspan 1 -sticky w
    menu $w.mr1pick1.menu -tearoff no
    $w.mr1pick1.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr1Pick1 "CYSN" }
    $w.mr1pick1.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr1Pick1 "HISND" }
    $w.mr1pick1.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr1Pick1 "HISNE" }
    $w.mr1pick1.menu add command -label "GLU" \
	-command {set ::MultiRests::mr1Pick1 "GLU" }
    $w.mr1pick1.menu add command -label "ASP" \
	-command {set ::MultiRests::mr1Pick1 "ASP" }
    $w.mr1pick1.menu add command -label "ARG" \
	-command {set ::MultiRests::mr1Pick1 "ARG" }
    $w.mr1pick1.menu add command -label "LYS" \
	-command {set ::MultiRests::mr1Pick1 "LYS" }
    $w.mr1pick1.menu add command -label "TRP" \
	-command {set ::MultiRests::mr1Pick1 "TRP" }
    $w.mr1pick1.menu add command -label "CYS" \
	-command {set ::MultiRests::mr1Pick1 "CYS" }
    
    grid [menubutton $w.mr1pick2 -width 6 -textvar ::MultiRests::mr1Pick2 \
	      -menu $w.mr1pick2.menu -relief raised] \
	-row $row -column 2 -columnspan 1 -sticky w
    menu $w.mr1pick2.menu -tearoff no
    $w.mr1pick2.menu add command -label "Cd2+" \
	-command {set ::MultiRests::mr1Pick2 "Cd" }
    $w.mr1pick2.menu add command -label "Mg2+" \
	-command {set ::MultiRests::mr1Pick2 "Mg" }
    $w.mr1pick2.menu add command -label "Zn2+" \
	-command {set ::MultiRests::mr1Pick2 "Zn" }
    $w.mr1pick2.menu add command -label "-" \
	-command {set ::MultiRests::mr1Pick2 "-" }      
    
    grid [menubutton $w.mr1pick3 -width 6 -textvar ::MultiRests::mr1Pick3 \
	      -menu $w.mr1pick3.menu -relief raised] \
	-row $row -column 3 -columnspan 1 -sticky w
    menu $w.mr1pick3.menu -tearoff no
    $w.mr1pick3.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr1Pick3 "CYSN" }
    $w.mr1pick3.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr1Pick3 "HISND" }
    $w.mr1pick3.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr1Pick3 "HISNE" }    
    $w.mr1pick3.menu add command -label "GLU" \
	-command {set ::MultiRests::mr1Pick3 "GLU" }
    $w.mr1pick3.menu add command -label "ASP" \
	-command {set ::MultiRests::mr1Pick3 "ASP" }   
    $w.mr1pick3.menu add command -label "ARG" \
	-command {set ::MultiRests::mr1Pick3 "ARG" }
    $w.mr1pick3.menu add command -label "LYS" \
	-command {set ::MultiRests::mr1Pick3 "LYS" }   
    $w.mr1pick3.menu add command -label "TRP" \
	-command {set ::MultiRests::mr1Pick3 "TRP" }
    $w.mr1pick3.menu add command -label "CYS" \
	-command {set ::MultiRests::mr1Pick3 "CYS" }   
    
    grid [label $w.mr1seglabel1 -width 1 -text ""] \
	-row $row -column 4 -sticky ew
    grid [label $w.mr1seglabel2 -width 8 -text "SegID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr1Segi -width 8 -textvar ::MultiRests::mr1SegIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr1seglabel3 -width 8 -text "SegID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr1Segj -width 8 -textvar ::MultiRests::mr1SegIDj] -row $row -column 9 -columnspan 1 -sticky w   
    incr row
    
    grid [label $w.mr1reslabel1 -width 8 -text "ResID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr1Resi -width 8 -textvar ::MultiRests::mr1ResIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr1reslabel2 -width 8 -text "ResID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr1Resj -width 8 -textvar ::MultiRests::mr1ResIDj] -row $row -column 9 -columnspan 1 -sticky w 
    incr row    
    
    # MultiRestraint 2
    
    grid [checkbutton $w.mr2 -text " MR: 2 " -width 6 -variable ::MultiRests::mr2flag] \
	-row $row -column 0 -columnspan 1 -sticky w
    
    grid [menubutton $w.mr2pick1 -width 6 -textvar ::MultiRests::mr2Pick1 \
	      -menu $w.mr2pick1.menu -relief raised] \
	-row $row -column 1 -columnspan 1 -sticky w
    menu $w.mr2pick1.menu -tearoff no
    $w.mr2pick1.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr2Pick1 "CYSN" }
    $w.mr2pick1.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr2Pick1 "HISND" }
    $w.mr2pick1.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr2Pick1 "HISNE" }
    $w.mr2pick1.menu add command -label "GLU" \
	-command {set ::MultiRests::mr2Pick1 "GLU" }
    $w.mr2pick1.menu add command -label "ASP" \
	-command {set ::MultiRests::mr2Pick1 "ASP" }
    $w.mr2pick1.menu add command -label "ARG" \
	-command {set ::MultiRests::mr2Pick1 "ARG" }
    $w.mr2pick1.menu add command -label "LYS" \
	-command {set ::MultiRests::mr2Pick1 "LYS" }
    $w.mr2pick1.menu add command -label "TRP" \
	-command {set ::MultiRests::mr2Pick1 "TRP" }
    $w.mr2pick1.menu add command -label "CYS" \
	-command {set ::MultiRests::mr2Pick1 "CYS" }
    
    grid [menubutton $w.mr2pick2 -width 6 -textvar ::MultiRests::mr2Pick2 \
	      -menu $w.mr2pick2.menu -relief raised] \
	-row $row -column 2 -columnspan 1 -sticky w
    menu $w.mr2pick2.menu -tearoff no
    $w.mr2pick2.menu add command -label "Cd2+" \
	-command {set ::MultiRests::mr2Pick2 "Cd" }
    $w.mr2pick2.menu add command -label "Mg2+" \
	-command {set ::MultiRests::mr2Pick2 "Mg" }
    $w.mr2pick2.menu add command -label "Zn2+" \
	-command {set ::MultiRests::mr2Pick2 "Zn" }
    $w.mr2pick2.menu add command -label "-" \
	-command {set ::MultiRests::mr2Pick2 "-" }      
    
    grid [menubutton $w.mr2pick3 -width 6 -textvar ::MultiRests::mr2Pick3 \
	      -menu $w.mr2pick3.menu -relief raised] \
	-row $row -column 3 -columnspan 1 -sticky w
    menu $w.mr2pick3.menu -tearoff no
    $w.mr2pick3.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr2Pick3 "CYSN" }
    $w.mr2pick3.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr2Pick3 "HISND" }
    $w.mr2pick3.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr2Pick3 "HISNE" }    
    $w.mr2pick3.menu add command -label "GLU" \
	-command {set ::MultiRests::mr2Pick3 "GLU" }
    $w.mr2pick3.menu add command -label "ASP" \
	-command {set ::MultiRests::mr2Pick3 "ASP" }   
    $w.mr2pick3.menu add command -label "ARG" \
	-command {set ::MultiRests::mr2Pick3 "ARG" }
    $w.mr2pick3.menu add command -label "LYS" \
	-command {set ::MultiRests::mr2Pick3 "LYS" }   
    $w.mr2pick3.menu add command -label "TRP" \
	-command {set ::MultiRests::mr2Pick3 "TRP" }
    $w.mr2pick3.menu add command -label "CYS" \
	-command {set ::MultiRests::mr2Pick3 "CYS" }   
    
    grid [label $w.mr2seglabel1 -width 1 -text ""] \
	-row $row -column 4 -sticky ew
    grid [label $w.mr2seglabel2 -width 8 -text "SegID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr2Segi -width 8 -textvar ::MultiRests::mr2SegIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr2seglabel3 -width 8 -text "SegID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr2Segj -width 8 -textvar ::MultiRests::mr2SegIDj] -row $row -column 9 -columnspan 1 -sticky w   
    incr row
    
    grid [label $w.mr2reslabel1 -width 8 -text "ResID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr2Resi -width 8 -textvar ::MultiRests::mr2ResIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr2reslabel2 -width 8 -text "ResID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr2Resj -width 8 -textvar ::MultiRests::mr2ResIDj] -row $row -column 9 -columnspan 1 -sticky w 
    incr row    
    
    # MultiRestraint 3
    
    grid [checkbutton $w.mr3 -text " MR: 3 " -width 6 -variable ::MultiRests::mr3flag] \
	-row $row -column 0 -columnspan 1 -sticky w

    grid [menubutton $w.mr3pick1 -width 6 -textvar ::MultiRests::mr3Pick1 \
	      -menu $w.mr3pick1.menu -relief raised] \
	-row $row -column 1 -columnspan 1 -sticky w
    menu $w.mr3pick1.menu -tearoff no
    $w.mr3pick1.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr3Pick1 "CYSN" }
    $w.mr3pick1.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr3Pick1 "HISND" }
    $w.mr3pick1.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr3Pick1 "HISNE" }
    $w.mr3pick1.menu add command -label "GLU" \
	-command {set ::MultiRests::mr3Pick1 "GLU" }
    $w.mr3pick1.menu add command -label "ASP" \
	-command {set ::MultiRests::mr3Pick1 "ASP" }
    $w.mr3pick1.menu add command -label "ARG" \
	-command {set ::MultiRests::mr3Pick1 "ARG" }
    $w.mr3pick1.menu add command -label "LYS" \
	-command {set ::MultiRests::mr3Pick1 "LYS" }
    $w.mr3pick1.menu add command -label "TRP" \
	-command {set ::MultiRests::mr3Pick1 "TRP" }
    $w.mr3pick1.menu add command -label "CYS" \
	-command {set ::MultiRests::mr3Pick1 "CYS" }

    grid [menubutton $w.mr3pick2 -width 6 -textvar ::MultiRests::mr3Pick2 \
	      -menu $w.mr3pick2.menu -relief raised] \
	-row $row -column 2 -columnspan 1 -sticky w
    menu $w.mr3pick2.menu -tearoff no
    $w.mr3pick2.menu add command -label "Cd2+" \
	-command {set ::MultiRests::mr3Pick2 "Cd" }
    $w.mr3pick2.menu add command -label "Mg2+" \
	-command {set ::MultiRests::mr3Pick2 "Mg" }
    $w.mr3pick2.menu add command -label "Zn2+" \
	-command {set ::MultiRests::mr3Pick2 "Zn" }
    $w.mr3pick2.menu add command -label "-" \
	-command {set ::MultiRests::mr3Pick2 "-" }      

    grid [menubutton $w.mr3pick3 -width 6 -textvar ::MultiRests::mr3Pick3 \
	      -menu $w.mr3pick3.menu -relief raised] \
	-row $row -column 3 -columnspan 1 -sticky w
    menu $w.mr3pick3.menu -tearoff no
    $w.mr3pick3.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr3Pick3 "CYSN" }
    $w.mr3pick3.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr3Pick3 "HISND" }
    $w.mr3pick3.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr3Pick3 "HISNE" }   
    $w.mr3pick3.menu add command -label "GLU" \
	-command {set ::MultiRests::mr3Pick3 "GLU" }
    $w.mr3pick3.menu add command -label "ASP" \
	-command {set ::MultiRests::mr3Pick3 "ASP" }   
    $w.mr3pick3.menu add command -label "ARG" \
	-command {set ::MultiRests::mr3Pick3 "ARG" }
    $w.mr3pick3.menu add command -label "LYS" \
	-command {set ::MultiRests::mr3Pick3 "LYS" }   
    $w.mr3pick3.menu add command -label "TRP" \
	-command {set ::MultiRests::mr3Pick3 "TRP" }
    $w.mr3pick3.menu add command -label "CYS" \
	-command {set ::MultiRests::mr3Pick3 "CYS" }   
   
    grid [label $w.mr3seglabel1 -width 1 -text ""] \
	-row $row -column 4 -sticky ew
    grid [label $w.mr3seglabel2 -width 8 -text "SegID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr3Segi -width 8 -textvar ::MultiRests::mr3SegIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr3seglabel3 -width 8 -text "SegID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr3Segj -width 8 -textvar ::MultiRests::mr3SegIDj] -row $row -column 9 -columnspan 1 -sticky w   
    incr row

    grid [label $w.mr3reslabel1 -width 8 -text "ResID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr3Resi -width 8 -textvar ::MultiRests::mr3ResIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr3reslabel2 -width 8 -text "ResID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr3Resj -width 8 -textvar ::MultiRests::mr3ResIDj] -row $row -column 9 -columnspan 1 -sticky w 
    incr row    

    # MultiRestraint 4

    grid [checkbutton $w.mr4 -text " MR: 4 " -width 6 -variable ::MultiRests::mr4flag] \
	-row $row -column 0 -columnspan 1 -sticky w

    grid [menubutton $w.mr4pick1 -width 6 -textvar ::MultiRests::mr4Pick1 \
	      -menu $w.mr4pick1.menu -relief raised] \
	-row $row -column 1 -columnspan 1 -sticky w
    menu $w.mr4pick1.menu -tearoff no
    $w.mr4pick1.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr4Pick1 "CYSN" }
    $w.mr4pick1.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr4Pick1 "HISND" }
    $w.mr4pick1.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr4Pick1 "HISNE" }
    $w.mr4pick1.menu add command -label "GLU" \
	-command {set ::MultiRests::mr4Pick1 "GLU" }
    $w.mr4pick1.menu add command -label "ASP" \
	-command {set ::MultiRests::mr4Pick1 "ASP" }
    $w.mr4pick1.menu add command -label "ARG" \
	-command {set ::MultiRests::mr4Pick1 "ARG" }
    $w.mr4pick1.menu add command -label "LYS" \
	-command {set ::MultiRests::mr4Pick1 "LYS" }
    $w.mr4pick1.menu add command -label "TRP" \
	-command {set ::MultiRests::mr4Pick1 "TRP" }
    $w.mr4pick1.menu add command -label "CYS" \
	-command {set ::MultiRests::mr4Pick1 "CYS" }

    grid [menubutton $w.mr4pick2 -width 6 -textvar ::MultiRests::mr4Pick2 \
	      -menu $w.mr4pick2.menu -relief raised] \
	-row $row -column 2 -columnspan 1 -sticky w
    menu $w.mr4pick2.menu -tearoff no
    $w.mr4pick2.menu add command -label "Cd2+" \
	-command {set ::MultiRests::mr4Pick2 "Cd" }
    $w.mr4pick2.menu add command -label "Mg2+" \
	-command {set ::MultiRests::mr4Pick2 "Mg" }
    $w.mr4pick2.menu add command -label "Zn2+" \
	-command {set ::MultiRests::mr4Pick2 "Zn" }
    $w.mr4pick2.menu add command -label "-" \
	-command {set ::MultiRests::mr4Pick2 "-" }      

    grid [menubutton $w.mr4pick3 -width 6 -textvar ::MultiRests::mr4Pick3 \
	      -menu $w.mr4pick3.menu -relief raised] \
	-row $row -column 3 -columnspan 1 -sticky w
    menu $w.mr4pick3.menu -tearoff no
    $w.mr4pick3.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr4Pick3 "CYSN" }
    $w.mr4pick3.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr4Pick3 "HISND" }
    $w.mr4pick3.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr4Pick3 "HISNE" }    
    $w.mr4pick3.menu add command -label "GLU" \
	-command {set ::MultiRests::mr4Pick3 "GLU" }
    $w.mr4pick3.menu add command -label "ASP" \
	-command {set ::MultiRests::mr4Pick3 "ASP" }   
    $w.mr4pick3.menu add command -label "ARG" \
	-command {set ::MultiRests::mr4Pick3 "ARG" }
    $w.mr4pick3.menu add command -label "LYS" \
	-command {set ::MultiRests::mr4Pick3 "LYS" }   
    $w.mr4pick3.menu add command -label "TRP" \
	-command {set ::MultiRests::mr4Pick3 "TRP" }
    $w.mr4pick3.menu add command -label "CYS" \
	-command {set ::MultiRests::mr4Pick3 "CYS" }   
    
    grid [label $w.mr4seglabel1 -width 1 -text ""] \
	-row $row -column 4 -sticky ew 
    grid [label $w.mr4seglabel2 -width 8 -text "SegID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr4Segi -width 8 -textvar ::MultiRests::mr4SegIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr4seglabel3 -width 8 -text "SegID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr4Segj -width 8 -textvar ::MultiRests::mr4SegIDj] -row $row -column 9 -columnspan 1 -sticky w   
    incr row

    grid [label $w.mr4reslabel1 -width 8 -text "ResID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr4Resi -width 8 -textvar ::MultiRests::mr4ResIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr4reslabel2 -width 8 -text "ResID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr4Resj -width 8 -textvar ::MultiRests::mr4ResIDj] -row $row -column 9 -columnspan 1 -sticky w 
    incr row    

    # MultiRestraint 5
    
    grid [checkbutton $w.mr5 -text " MR: 5 " -width 6 -variable ::MultiRests::mr5flag] \
	-row $row -column 0 -columnspan 1 -sticky w

    grid [menubutton $w.mr5pick1 -width 6 -textvar ::MultiRests::mr5Pick1 \
	      -menu $w.mr5pick1.menu -relief raised] \
	-row $row -column 1 -columnspan 1 -sticky w
    menu $w.mr5pick1.menu -tearoff no
    $w.mr5pick1.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr5Pick1 "CYSN" }
    $w.mr5pick1.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr5Pick1 "HISND" }
    $w.mr5pick1.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr5Pick1 "HISNE" }
    $w.mr5pick1.menu add command -label "GLU" \
	-command {set ::MultiRests::mr5Pick1 "GLU" }
    $w.mr5pick1.menu add command -label "ASP" \
	-command {set ::MultiRests::mr5Pick1 "ASP" }
    $w.mr5pick1.menu add command -label "ARG" \
	-command {set ::MultiRests::mr5Pick1 "ARG" }
    $w.mr5pick1.menu add command -label "LYS" \
	-command {set ::MultiRests::mr5Pick1 "LYS" }
    $w.mr5pick1.menu add command -label "TRP" \
	-command {set ::MultiRests::mr5Pick1 "TRP" }
    $w.mr5pick1.menu add command -label "CYS" \
	-command {set ::MultiRests::mr5Pick1 "CYS" }

    grid [menubutton $w.mr5pick2 -width 6 -textvar ::MultiRests::mr5Pick2 \
	      -menu $w.mr5pick2.menu -relief raised] \
	-row $row -column 2 -columnspan 1 -sticky w
    menu $w.mr5pick2.menu -tearoff no
    $w.mr5pick2.menu add command -label "Cd2+" \
	-command {set ::MultiRests::mr5Pick2 "Cd" }
    $w.mr5pick2.menu add command -label "Mg2+" \
	-command {set ::MultiRests::mr5Pick2 "Mg" }
    $w.mr5pick2.menu add command -label "Zn2+" \
	-command {set ::MultiRests::mr5Pick2 "Zn" }
    $w.mr5pick2.menu add command -label "-" \
	-command {set ::MultiRests::mr5Pick2 "-" }      

    grid [menubutton $w.mr5pick3 -width 6 -textvar ::MultiRests::mr5Pick3 \
	      -menu $w.mr5pick3.menu -relief raised] \
	-row $row -column 3 -columnspan 1 -sticky w
    menu $w.mr5pick3.menu -tearoff no
    $w.mr5pick3.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr5Pick3 "CYSN" }
    $w.mr5pick3.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr5Pick3 "HISND" }
    $w.mr5pick3.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr5Pick3 "HISNE" }    
    $w.mr5pick3.menu add command -label "GLU" \
	-command {set ::MultiRests::mr5Pick3 "GLU" }
    $w.mr5pick3.menu add command -label "ASP" \
	-command {set ::MultiRests::mr5Pick3 "ASP" }   
    $w.mr5pick3.menu add command -label "ARG" \
	-command {set ::MultiRests::mr5Pick3 "ARG" }
    $w.mr5pick3.menu add command -label "LYS" \
	-command {set ::MultiRests::mr5Pick3 "LYS" }   
    $w.mr5pick3.menu add command -label "TRP" \
	-command {set ::MultiRests::mr5Pick3 "TRP" }
    $w.mr5pick3.menu add command -label "CYS" \
	-command {set ::MultiRests::mr5Pick3 "CYS" }   
   
    grid [label $w.mr5seglabel1 -width 1 -text ""] \
	-row $row -column 4 -sticky ew 
    grid [label $w.mr5seglabel2 -width 8 -text "SegID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr5Segi -width 8 -textvar ::MultiRests::mr5SegIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr5seglabel3 -width 8 -text "SegID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr5Segj -width 8 -textvar ::MultiRests::mr5SegIDj] -row $row -column 9 -columnspan 1 -sticky w   
    incr row

    grid [label $w.mr5reslabel1 -width 8 -text "ResID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr5Resi -width 8 -textvar ::MultiRests::mr5ResIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr5reslabel2 -width 8 -text "ResID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr5Resj -width 8 -textvar ::MultiRests::mr5ResIDj] -row $row -column 9 -columnspan 1 -sticky w 
    incr row    

    # MultiRestraint 6

    grid [checkbutton $w.mr6 -text " MR: 6 " -width 6 -variable ::MultiRests::mr6flag] \
	-row $row -column 0 -columnspan 1 -sticky w

    grid [menubutton $w.mr6pick1 -width 6 -textvar ::MultiRests::mr6Pick1 \
	      -menu $w.mr6pick1.menu -relief raised] \
	-row $row -column 1 -columnspan 1 -sticky w
    menu $w.mr6pick1.menu -tearoff no
    $w.mr6pick1.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr6Pick1 "CYSN" }
    $w.mr6pick1.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr6Pick1 "HISND" }
    $w.mr6pick1.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr6Pick1 "HISNE" }
    $w.mr6pick1.menu add command -label "GLU" \
	-command {set ::MultiRests::mr6Pick1 "GLU" }
    $w.mr6pick1.menu add command -label "ASP" \
	-command {set ::MultiRests::mr6Pick1 "ASP" }
    $w.mr6pick1.menu add command -label "ARG" \
	-command {set ::MultiRests::mr6Pick1 "ARG" }
    $w.mr6pick1.menu add command -label "LYS" \
	-command {set ::MultiRests::mr6Pick1 "LYS" }
    $w.mr6pick1.menu add command -label "TRP" \
	-command {set ::MultiRests::mr6Pick1 "TRP" }
    $w.mr6pick1.menu add command -label "CYS" \
	-command {set ::MultiRests::mr6Pick1 "CYS" }

    grid [menubutton $w.mr6pick2 -width 6 -textvar ::MultiRests::mr6Pick2 \
	      -menu $w.mr6pick2.menu -relief raised] \
	-row $row -column 2 -columnspan 1 -sticky w
    menu $w.mr6pick2.menu -tearoff no
    $w.mr6pick2.menu add command -label "Cd2+" \
	-command {set ::MultiRests::mr6Pick2 "Cd" }
    $w.mr6pick2.menu add command -label "Mg2+" \
	-command {set ::MultiRests::mr6Pick2 "Mg" }
    $w.mr6pick2.menu add command -label "Zn2+" \
	-command {set ::MultiRests::mr6Pick2 "Zn" }
    $w.mr6pick2.menu add command -label "-" \
	-command {set ::MultiRests::mr6Pick2 "-" }      

    grid [menubutton $w.mr6pick3 -width 6 -textvar ::MultiRests::mr6Pick3 \
	      -menu $w.mr6pick3.menu -relief raised] \
	-row $row -column 3 -columnspan 1 -sticky w
    menu $w.mr6pick3.menu -tearoff no
    $w.mr6pick3.menu add command -label "CYS(-1)" \
	-command {set ::MultiRests::mr6Pick3 "CYSN" }
    $w.mr6pick3.menu add command -label "HISND(-1)" \
	-command {set ::MultiRests::mr6Pick3 "HISND" }
    $w.mr6pick3.menu add command -label "HISNE(-1)" \
	-command {set ::MultiRests::mr6Pick3 "HISNE" }    
    $w.mr6pick3.menu add command -label "GLU" \
	-command {set ::MultiRests::mr6Pick3 "GLU" }
    $w.mr6pick3.menu add command -label "ASP" \
	-command {set ::MultiRests::mr6Pick3 "ASP" }   
    $w.mr6pick3.menu add command -label "ARG" \
	-command {set ::MultiRests::mr6Pick3 "ARG" }
    $w.mr6pick3.menu add command -label "LYS" \
	-command {set ::MultiRests::mr6Pick3 "LYS" }   
    $w.mr6pick3.menu add command -label "TRP" \
	-command {set ::MultiRests::mr6Pick3 "TRP" }
    $w.mr6pick3.menu add command -label "CYS" \
	-command {set ::MultiRests::mr6Pick3 "CYS" }   
    
    grid [label $w.mr6seglabel1 -width 1 -text ""] \
	-row $row -column 4 -sticky ew 
    grid [label $w.mr6seglabel2 -width 8 -text "SegID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr6Segi -width 8 -textvar ::MultiRests::mr6SegIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr6seglabel3 -width 8 -text "SegID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr6Segj -width 8 -textvar ::MultiRests::mr6SegIDj] -row $row -column 9 -columnspan 1 -sticky w   
    incr row

    grid [label $w.mr6reslabel1 -width 8 -text "ResID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr6Resi -width 8 -textvar ::MultiRests::mr6ResIDi] -row $row -column 7 -columnspan 1 -sticky w 
    grid [label $w.mr6reslabel2 -width 8 -text "ResID: "] \
	-row $row -column 8 -sticky w
    grid [entry $w.mr6Resj -width 8 -textvar ::MultiRests::mr6ResIDj] -row $row -column 9 -columnspan 1 -sticky w 
    incr row    


    # "Spin Labels"   
    grid [label $w.notelabel7 -text "Spin Labels "] \
	-row $row -column 0 -columnspan 3 -sticky w
    incr row
    
    grid [label $w.emptyrow4 -width 6 -text ""] \
	-row $row -column 0 -columnspan 1 -sticky w
    incr row  

    grid [label $w.notelabel8 -width 6 -text "RepNum"] \
	-row $row -column 3 -columnspan 1 -sticky w  
    grid [label $w.notelabel9 -width 10 -text "Residue i"] \
	-row $row -column 6 -columnspan 2 -sticky w
    incr row
    
    # MultiRestraint 7
    
    grid [checkbutton $w.mr7 -text " MR: 7 " -width 6 -variable ::MultiRests::mr7flag] \
	-row $row -column 0 -columnspan 1 -sticky w
    
    grid [menubutton $w.mr7pick1 -width 6 -textvar ::MultiRests::mr7Pick1 \
	      -menu $w.mr7pick1.menu -relief raised] \
	-row $row -column 1 -columnspan 2 -sticky w
    menu $w.mr7pick1.menu -tearoff no
    $w.mr7pick1.menu add command -label " MTSSL" \
	-command {set ::MultiRests::mr7Pick1 "CYR1" }
    $w.mr7pick1.menu add command -label " ONDUM" \
	-command {set ::MultiRests::mr7Pick1 "ODUM" }
    
    grid [entry $w.mr7Rep -width 7 -textvar ::MultiRests::mr7RepNum] \
        -row $row -column 3 -columnspan 1 -sticky w
    
    grid [label $w.mr7seglabel1 -width 1 -text ""] \
	-row $row -column 4 -sticky ew
    
    grid [label $w.mr7seglabel2 -width 8 -text "SegID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr7Segi -width 30 -textvar ::MultiRests::mr7SegIDi] -row $row -column 7 -columnspan 3 -sticky w   
    incr row
    
    grid [label $w.mr7reslabel1 -width 8 -text "ResID: "] \
	-row $row -column 6 -sticky ew
    grid [entry $w.mr7Resi -width 30 -textvar ::MultiRests::mr7ResIDi] -row $row -column 7 -columnspan 3 -sticky w 
    incr row    

    # RUN Button    
    grid [button $w.gobutton -text "Run MultiRestraints" \
	      -command [namespace code {
		  set labels ""
		  if {$mr1flag != 0} {set labels "-mr1 -mr1pick1 $mr1Pick1 -mr1pick2 $mr1Pick2 -mr1pick3 $mr1Pick3 -mr1segi $mr1SegIDi -mr1resi $mr1ResIDi -mr1segj $mr1SegIDj -mr1resj $mr1ResIDj $labels"}
		  if {$mr2flag != 0} {set labels "-mr2 -mr2pick1 $mr2Pick1 -mr2pick2 $mr2Pick2 -mr2pick3 $mr2Pick3 -mr2segi $mr2SegIDi -mr2resi $mr2ResIDi -mr2segj $mr2SegIDj -mr2resj $mr2ResIDj $labels"}
		  if {$mr3flag != 0} {set labels "-mr3 -mr3pick1 $mr3Pick1 -mr3pick2 $mr3Pick2 -mr3pick3 $mr3Pick3 -mr3segi $mr3SegIDi -mr3resi $mr3ResIDi -mr3segj $mr3SegIDj -mr3resj $mr3ResIDj $labels"}
		  if {$mr4flag != 0} {set labels "-mr4 -mr4pick1 $mr4Pick1 -mr4pick2 $mr4Pick2 -mr4pick3 $mr4Pick3 -mr4segi $mr4SegIDi -mr4resi $mr4ResIDi -mr4segj $mr4SegIDj -mr4resj $mr4ResIDj $labels"}
		  if {$mr5flag != 0} {set labels "-mr5 -mr5pick1 $mr5Pick1 -mr5pick2 $mr5Pick2 -mr5pick3 $mr5Pick3 -mr5segi $mr5SegIDi -mr5resi $mr5ResIDi -mr5segj $mr5SegIDj -mr5resj $mr5ResIDj $labels"}
		  if {$mr6flag != 0} {set labels "-mr6 -mr6pick1 $mr6Pick1 -mr6pick2 $mr6Pick2 -mr6pick3 $mr6Pick3 -mr6segi $mr6SegIDi -mr6resi $mr6ResIDi -mr6segj $mr6SegIDj -mr6resj $mr6ResIDj $labels"}
		  if {$mr7flag != 0} {set labels "-mr7 -mr7pick1 $mr7Pick1 -mr7rep $mr7RepNum -mr7segi $mr7SegIDi -mr7resi $mr7ResIDi $labels"}
		  puts "multirestraints_core -psf $psfname -pdb $pdbname -o $prefix -top $topType $labels"
		  multirestraints_core -psf $psfname -pdb $pdbname
	      } ]] -row $row -column 0 -columnspan 10 -sticky nsew
}

proc multirestraints_tk {} {
    ::MultiRests::multirestraints_gui
    return $::MultiRests::w
}


