# Author: Kin Lam
#   Beckman Institute for Advanced Science and Technology
#   University of Illinois, Urbana-Champaign
#   kinlam2@ks.uiuc.edu
#   http://www.ks.uiuc.edu/~kinlam2/
#
# This tool is built based on the original plugin written by Dr. Luis Gracia:
# http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/cluster

# TO DO:
# 0. display the centroid frames
# 1. add rmsd alignment and visualization
# 2. add support to other clustering algorithm
# 3. add Silhouette statistics

package provide clusteringtool 0.1

namespace eval ::clusteringtool:: {
  namespace export clusteringtool
}

# Hook for vmd, start the GUI
proc clusteringtool_tk_cb {} {
  clusteringtool::cluster
  return $clusteringtool::w
}

proc clusteringtool::destroy {} {
  # Delete traces
  # Delete remaining selections

  global vmd_initialize_structure
  trace vdelete vmd_initialize_structure w [namespace code UpdateMolecules]
}

# Main window
proc clusteringtool::cluster {} {
  variable w;   # TK window

  variable webpage "http://https://github.com/alanklam/VMDplugins/clusteringtool0.1"
  variable cluster;              # Array with all levels clustering (set on import)
  variable cluster0;             # Array with current selected level
  variable clust_file;           # File used to load clustering data
  variable clust_mol;            # Molecule use to show clustering
  variable clust_list;           # Listbox with clusters for selected level
  variable level_list;           # Listbox with available clustering levels
  variable conf_list;            # Listbox with conformations for a level
  variable confs;                # Array with reverse lookup for conformations
  variable join_1members      1; # Join single member clusters in a separate cluster
  variable show_centroid      1; # Show only the centroid frame in each cluster
  variable keep_rep	      1; # Update results by keeping current representations on the molecule
  variable bb_def      "C CA N"; # Backbone definition (different from VMD's definition)
  variable bb_only            0; # Selection modifier (only name CA C N)
  variable trace_only         0; # Selection modifier (only name CA)
  variable noh                1; # Selection modifier (no hydrogens)
  variable rep_type  "Licorice"; # Default repsentation type
  variable clust_rep	      0; # Cluster representation start from this number 

  # Variables for measure cluster
  variable calc_num           5; # number of clusters
  variable calc_cutoff      1.0; # cutoff
  variable calc_first         0; # first frame
  variable calc_last         -1; # last frame
  variable calc_step          1; # frame step
  variable calc_distfunc "rmsd"; # distance function
  variable calc_selupdate     0; # selection update
  variable calc_weight   "none"; # weighting factor
  global vmd_initialize_structure

  if {[molinfo num] > 0} {
    set clust_mol [molinfo top get id]
  }

  # If already initialized, just turn on
  if { [winfo exists .clustering] } {
    wm deiconify $w
    return
  }

  # GUI look
  option add *clustering.*borderWidth 1
  option add *clustering.*Button.padY 0
  option add *clustering.*Menubutton.padY 0

  # Main window
  set w [toplevel ".clustering"]
  wm title $w "VMD Clustering Analysis Tool (beta)"
  wm resizable $w 1 1 
  bind $w <Destroy> [namespace current]::destroy

  # Menu
  # -------------
  frame $w.menubar -relief raised -bd 2
  pack $w.menubar -fill x

  # Import menu
  menubutton $w.menubar.import -text "Import" -underline 0 -menu $w.menubar.import.menu
  pack $w.menubar.import -side left
  menu $w.menubar.import.menu -tearoff no
  $w.menubar.import.menu add command -label "NMRcluster..."          -command "[namespace current]::import nmrcluster"
  $w.menubar.import.menu add command -label "Xcluster..."            -command "[namespace current]::import xcluster"
  $w.menubar.import.menu add command -label "Cutree (R)..."          -command "[namespace current]::import cutree"
  $w.menubar.import.menu add command -label "Gromacs (g_cluster)..." -command "[namespace current]::import gcluster"
  $w.menubar.import.menu add command -label "Charmm..." -command "[namespace current]::import charmm"

  # Menubar / Help menu
  menubutton $w.menubar.help -text "Help" -menu $w.menubar.help.menu
  pack $w.menubar.help -side right
  menu $w.menubar.help.menu -tearoff no
  $w.menubar.help.menu add command -label "Help" -command "vmd_open_url $webpage"
  $w.menubar.help.menu add command -label "About" -command [namespace current]::about

  # Use measure cluster
  # -------------
  labelframe $w.calc -text "Use measure cluster (VMD build-in function)" -relief ridge -bd 2
  pack $w.calc -side top -fill x -anchor nw

  frame $w.calc.buttons
  pack $w.calc.buttons -side left -anchor nw -fill y -expand 1

  button $w.calc.buttons.cluster -text "Calculate" -command [namespace code calculate]
  pack $w.calc.buttons.cluster -side top -anchor nw -fill y -expand 1

  frame $w.calc.options
  pack $w.calc.options -side left -anchor nw

  frame $w.calc.options.1
  pack $w.calc.options.1 -side top -anchor nw

  frame $w.calc.options.1.mol
  pack $w.calc.options.1.mol -side left -anchor nw

  label $w.calc.options.1.mol.label -text "Mol:"
  menubutton $w.calc.options.1.mol.value -relief raised -bd 2 -direction flush \
    -textvariable [namespace current]::clust_mol -menu $w.calc.options.1.mol.value.menu
  menu $w.calc.options.1.mol.value.menu -tearoff no
  pack $w.calc.options.1.mol.label $w.calc.options.1.mol.value -side left

  frame $w.calc.options.1.first
  pack $w.calc.options.1.first -side left -anchor nw
  label $w.calc.options.1.first.label -text "First:"
  entry $w.calc.options.1.first.value -width 5 -textvariable [namespace current]::calc_first
  pack $w.calc.options.1.first.label $w.calc.options.1.first.value -side left -anchor nw

  frame $w.calc.options.1.last
  pack $w.calc.options.1.last -side left -anchor nw
  label $w.calc.options.1.last.label -text "Last:"
  entry $w.calc.options.1.last.value -width 5 -textvariable [namespace current]::calc_last
  pack $w.calc.options.1.last.label $w.calc.options.1.last.value -side left -anchor nw

  frame $w.calc.options.1.step
  pack $w.calc.options.1.step -side left -anchor nw
  label $w.calc.options.1.step.label -text "Step:"
  entry $w.calc.options.1.step.value -width 5 -textvariable [namespace current]::calc_step
  pack $w.calc.options.1.step.label $w.calc.options.1.step.value -side left -anchor nw

  frame $w.calc.options.2
  pack $w.calc.options.2 -side top -anchor nw -fill x -expand 1

  frame $w.calc.options.2.ncluster
  pack $w.calc.options.2.ncluster -side left -anchor nw
  label $w.calc.options.2.ncluster.label -text "Num:"
  entry $w.calc.options.2.ncluster.value -width 3 -textvariable [namespace current]::calc_num
  pack $w.calc.options.2.ncluster.label $w.calc.options.2.ncluster.value -side left -anchor nw

  frame $w.calc.options.2.cutoff
  pack $w.calc.options.2.cutoff -side left -anchor nw
  label $w.calc.options.2.cutoff.label -text "Cutoff:"
  entry $w.calc.options.2.cutoff.value -width 5 -textvariable [namespace current]::calc_cutoff
  pack $w.calc.options.2.cutoff.label $w.calc.options.2.cutoff.value -side left -anchor nw

  frame $w.calc.options.2.distfunc
  pack $w.calc.options.2.distfunc -side left -anchor nw -fill x -expand 1
  label $w.calc.options.2.distfunc.label -text "Function:"
  menubutton $w.calc.options.2.distfunc.value -relief raised -bd 2 -direction flush \
    -textvariable [namespace current]::calc_distfunc -menu $w.calc.options.2.distfunc.value.menu
  menu $w.calc.options.2.distfunc.value.menu -tearoff no
  foreach distfunc [list rmsd fitrmsd rgyrd] {
    $w.calc.options.2.distfunc.value.menu add radiobutton -value $distfunc -label $distfunc -variable [namespace current]::calc_distfunc
  }
  pack $w.calc.options.2.distfunc.label -side left
  pack $w.calc.options.2.distfunc.value -side left -fill x -expand 1

  frame $w.calc.options.3
  pack $w.calc.options.3 -side top -anchor nw

  frame $w.calc.options.3.weight
  pack $w.calc.options.3.weight -side left -anchor nw
  label $w.calc.options.3.weight.label -text "Weight:"
  menubutton $w.calc.options.3.weight.value -width 10 -relief raised -bd 2 -direction flush \
    -textvariable [namespace current]::calc_weight -menu $w.calc.options.3.weight.value.menu
  menu $w.calc.options.3.weight.value.menu -tearoff no
  foreach field [list none user user2 user3 user4 radius mass charge beta occupancy] {
    $w.calc.options.3.weight.value.menu add radiobutton -value $field -label $field -variable [namespace current]::calc_weight
  }
  pack $w.calc.options.3.weight.label $w.calc.options.3.weight.value -side left

  checkbutton $w.calc.options.3.selupdate -text "Selupdate" -variable [namespace current]::calc_selupdate
  pack $w.calc.options.3.selupdate -side left

  # Selection frame
  # -------------
  labelframe $w.sel -text "Selection" -relief ridge -bd 2
  pack $w.sel -side top -fill x

  # Selection
  frame $w.sel.left
  pack $w.sel.left -side left -fill both -expand yes

  text $w.sel.left.sel -height 3 -width 25 -highlightthickness 0 -selectborderwidth 0 -exportselection yes -wrap word -relief sunken -bd 1
  pack $w.sel.left.sel -side top -fill both -expand yes
  $w.sel.left.sel insert end "protein"

  # Selections options
  frame $w.sel.right
  pack $w.sel.right -side right

  checkbutton $w.sel.right.bb -text "Backbone" -variable [namespace current]::bb_only -command "[namespace current]::ctrlbb bb"
  checkbutton $w.sel.right.tr -text "Trace" -variable [namespace current]::trace_only -command "[namespace current]::ctrlbb trace"
  checkbutton $w.sel.right.noh -text "noh" -variable [namespace current]::noh -command "[namespace current]::ctrlbb noh"
  pack $w.sel.right.bb $w.sel.right.tr $w.sel.right.noh -side top -anchor nw

  # Results
  # -------------
  labelframe $w.result -text "Results" -relief ridge -bd 2
  pack $w.result -side top -fill both -expand 1

  # Options
  frame $w.result.options
  pack $w.result.options -side top -fill x

  frame $w.result.options.1
  pack $w.result.options.1 -side top -fill x

  button $w.result.options.1.update -text "Update Views" -command [namespace code UpdateSel]
  pack $w.result.options.1.update -side left

  checkbutton $w.result.options.1.join -text "Keep non-cluster representations" -variable clusteringtool::keep_rep -command [namespace code UpdateLevels]  
  pack $w.result.options.1.join -side right

  frame $w.result.options.2
  pack $w.result.options.2 -side top -fill x

  frame $w.result.options.2.rep_type
  pack $w.result.options.2.rep_type -side left -anchor nw
  label $w.result.options.2.rep_type.label -text "Representation:"
  menubutton $w.result.options.2.rep_type.value -width 10 -relief raised -bd 2 -direction flush \
    -textvariable [namespace current]::rep_type -menu $w.result.options.2.rep_type.value.menu
  menu $w.result.options.2.rep_type.value.menu -tearoff no
  foreach field [list Licorice Lines Bonds Points VDW CPK Trace Tube Ribbons NewRibbons Cartoon NewCartoon] {
    $w.result.options.2.rep_type.value.menu add radiobutton -value $field -label $field -variable [namespace current]::rep_type
  }
  pack $w.result.options.2.rep_type.label $w.result.options.2.rep_type.value -side left  

  checkbutton $w.result.options.2.keep -text "Show centroid only" -variable clusteringtool::show_centroid -command [namespace code UpdateLevels]
  pack $w.result.options.2.keep -side right

  frame $w.result.options.3
  pack $w.result.options.3 -side top -fill x

  checkbutton $w.result.options.3.keep -text "Join 1 member clusters" -variable clusteringtool::join_1members -command [namespace code UpdateLevels]
  pack $w.result.options.3.keep -side right

  # Data
  frame $w.result.data
  pack $w.result.data -fill both -expand 1

  # Data / Level
  frame $w.result.data.level
  label $w.result.data.level.label -text "Levels:"
  pack  $w.result.data.level.label -side top -anchor nw
  set level_list [listbox $w.result.data.level.listbox -selectmode single -activestyle dotbox -width 5 -exportselection 0 -yscroll [namespace code {$w.result.data.level.scroll set}] ]
  pack  $level_list -side left -fill both
  scrollbar $w.result.data.level.scroll -command [namespace code {$level_list yview}]
  pack  $w.result.data.level.scroll -side left -fill y
  bind $level_list <<ListboxSelect>> [namespace code UpdateLevels]
  pack $w.result.data.level -side left -fill both -expand 1

  # Data / cluster
  frame $w.result.data.cluster
  pack $w.result.data.cluster -side left -fill both -expand 1

  label $w.result.data.cluster.label -text "Clusters:"
  pack  $w.result.data.cluster.label -side top -anchor nw
  set clust_list [listbox $w.result.data.cluster.listbox -selectmode multiple -activestyle dotbox -width 10 -exportselection 0 -yscroll [namespace code {$w.result.data.cluster.scroll set}] ]
  pack  $clust_list -side left -fill both -expand 1
  scrollbar $w.result.data.cluster.scroll -command [namespace code {$clust_list yview}]
  pack  $w.result.data.cluster.scroll -side left -fill y
  bind $clust_list <<ListboxSelect>> [namespace code UpdateClusters]

  # Data / buttons
  frame $w.result.data.buttons
  pack $w.result.data.buttons -side left

  button $w.result.data.buttons.all -text "All" -command [namespace code {clus_onoff_all 1}]
  button $w.result.data.buttons.none -text "None" -command [namespace code {clus_onoff_all 0}]
  pack $w.result.data.buttons.all $w.result.data.buttons.none -side top

  # Data / confs
  frame $w.result.data.confs
  pack $w.result.data.confs -side left -fill both -expand 1

  label $w.result.data.confs.label -text "Confs:"
  pack  $w.result.data.confs.label -side top -anchor nw
  set conf_list [listbox $w.result.data.confs.listbox -selectmode multiple -activestyle dotbox -width 5 -exportselection 0 -yscroll [namespace code {$w.result.data.confs.scroll set}] ]
  pack $conf_list -side left -fill both -expand 1
  scrollbar $w.result.data.confs.scroll -command [namespace code {$conf_list yview}]
  pack  $w.result.data.confs.scroll -side left -fill y
  bind $conf_list <<ListboxSelect>> [namespace code UpdateConfs]

  # Set up the molecule list
  trace variable vmd_initialize_structure w [namespace current]::UpdateMolecules
  [namespace current]::UpdateMolecules
}


#############################################################################
# Update GUI
# Update GUI with selected level
# v0.1: added option to keep existing representations, added option menu to choose representations
proc clusteringtool::UpdateLevels {} {
  variable level_list
  variable clust_list
  variable conf_list
  variable confs
  variable clust_mol
  variable cluster
  variable cluster0
  variable join_1members
  variable colors
  variable color
  variable show_centroid
  # Reset
  $clust_list delete 0 end
  $conf_list delete 0 end
  if {[info exists confs]} {
    unset confs
  }
  if {[info exists colors]} {
    unset colors
  }
  set color -1
  # delete representations if required
  [namespace current]::del_reps $clust_mol
  

  # Copy cluster/level to cluster0
  set level [$level_list get [$level_list curselection]]
  if {[array exists cluster0]} {unset cluster0}
  foreach key [array names cluster $level:*] {
    regsub "$level:" $key {} name
    set cluster0($name) $cluster($key)
  }

  # Join 1 members if requested
  if {$join_1members} {
    [namespace current]::join_1members
  }

  set nclusters [array size cluster0]
  set names [lsort -dictionary [array names cluster0]]
  #puts "DEBUG: nclusters= $nclusters; names $names"

  # Find number of conformations
  set nconfs 0
  foreach key [array names cluster0] {
    set nconfs [expr {$nconfs + [llength $cluster0($key)]}]
    foreach el $cluster0($key) {
      lappend oconfs $el
    }
  }
  set oconfs [lsort -integer $oconfs]
  #puts "DEBUG: nconfs $nconfs"
  #puts "DEBUG: oconfs $oconfs"

  # Populate list of conformations
  for {set i 0} {$i < [llength $oconfs]} {incr i} {
    set el [lindex $oconfs $i]
    $conf_list insert end $el
    set confs($el) $i
  }
  
  # Populate list of clusters and add representations
  for {set num 0} {$num < $nclusters} {incr num} {
    regsub "$level:" [lindex $names $num] {} name
    [namespace current]::populate $num $name
    [namespace current]::add_rep $num $name
  }

  $clust_list selection set 0 [expr {$nclusters-1}]
  # toggle only centroid/all conformations
  if {$show_centroid} {
    for {set num 0} {$num < $nclusters} {incr num} {
      regsub "$level:" [lindex $names $num] {} name
      $conf_list selection set [lindex $cluster0($name) 0]
    }
  } else {
    $conf_list selection set 0 end
  }
  if {[regexp {^none} [$clust_list get [expr {$nclusters-1}]]]} {
    [namespace current]::clus_onoff 0 [expr {$nclusters-1}]
  }
}

# Populate cluster listbox
# v0.1 support showing centroid
proc clusteringtool::populate {num name} {
  variable clust_list
  variable conf_list
  variable confs
  variable cluster0
  variable show_centroid

  #puts "DEBUG: populate cluster $num ($name): $cluster0($name)"

  # Choose color
  set col [[namespace current]::next_color]
  set rgb [[namespace current]::index2rgb $col]
  set bw [[namespace current]::bw $rgb]

  # Add clusters to list and change conformation color
  $clust_list insert end [[namespace current]::name_add_count $name]
  $clust_list itemconfigure $num -selectbackground $rgb -selectforeground $bw

  foreach conf $cluster0($name) {
    $conf_list itemconfigure $confs($conf) -selectbackground $rgb -selectforeground $bw
  }

}

# Update clusters
proc clusteringtool::UpdateClusters {} {
  variable clust_list
  variable cluster0

  for {set i 0} {$i < [array size cluster0]} {incr i} {
    if {[$clust_list selection includes $i]} {
      [namespace current]::clus_onoff 1 $i
    } else {
      [namespace current]::clus_onoff 0 $i
    }
  }
}

# Update conformations
# v0.1, offset showrep command by the num of current representations
proc clusteringtool::UpdateConfs {} {
  variable clust_mol
  variable conf_list
  variable confs
  variable cluster0
  variable clust_list
  variable clust_rep
  # Create reverse list of clusters belonging to confs
  for {set c 0} {$c < [array size cluster0]} {incr c 1} {
    set name [[namespace current]::name_del_count $c]
    foreach f $cluster0($name) {
      set rconfs($f) $c
    }
  }

  # Create list of selected confs
  for {set i 0} {$i < [$conf_list size]} {incr i} {
    if {[$conf_list selection includes $i]} {
      lappend on [$conf_list get $i]
    }
  }
  
  
  # create new cluster
  if {![info exists on]} {
    for {set c 0} {$c < [array size cluster0]} {incr c} {
      $clust_list selection clear $c
      mol showrep $clust_mol [expr $c+$clust_rep] off
    }
    return
  }
  foreach f $on {
    lappend frames($rconfs($f)) $f
  }

  # apply changes
  # use clust_rep for offset in updating representations
  set names [array names frames]
  for {set c 0} {$c < [array size cluster0]} {incr c} {
    if {[lsearch -exact $names $c] == -1} {
      $clust_list selection clear $c
      mol showrep $clust_mol [expr $c+$clust_rep] off
    } else {
      if {[$clust_list selection includes $c] == 0} {
        $clust_list selection set $c
        mol showrep $clust_mol [expr $c+$clust_rep] on
      }
      mol drawframes $clust_mol [expr $c+$clust_rep] $frames($c)
    }
  }
}

# Update list of molecules
proc clusteringtool::UpdateMolecules {args} {
  # Code adapted from the ramaplot plugin
  variable w
  variable clust_mol
  
  set mollist [molinfo list]

  # Update the molecule browser
  $w.calc.options.1.mol.value.menu delete 0 end
  $w.calc.options.1.mol.value configure -state disabled
  if { [llength $mollist] != 0 } {
    foreach id $mollist {
      if {[molinfo $id get filetype] != "graphics"} {
        $w.calc.options.1.mol.value configure -state normal
        $w.calc.options.1.mol.value.menu add radiobutton -value $id \
          -label "$id [molinfo $id get name]" -variable [namespace current]::clust_mol
      }
    }
  }
}

# Update representations with atomselection and representation (v0.1)
proc clusteringtool::UpdateSel {} {
  variable cluster0
  variable clust_mol
  variable clust_rep
  variable rep_type
  # define offset for updating representations
  #set offset [expr [molinfo $clust_mol get numreps]-[array size cluster0]]

  for {set i $clust_rep} {$i < [molinfo $clust_mol get numreps]} {incr i} {
    mol modselect $i $clust_mol [[namespace current]::set_sel]
    mol modstyle $i $clust_mol $rep_type
  }
}


#############################################################################
# Clusters/Conformations and representations

# v0.1 Add rep for a cluster on top of existing repsentations
# v0.1 Support adding only centroid
proc clusteringtool::add_rep {num name} {
  variable cluster0
  variable clust_mol
  variable clust_list
  variable colors
  variable rep_type
  variable show_centroid
  # puts "LGV: [llength $cluster0($name)]"
  # if {[llength $cluster0($name)] == 0} {
  #   return
  # }

  if {$show_centroid} {
    lappend frames [lindex $cluster0($name) 0]
  } else {
    foreach f $cluster0($name) {
      lappend frames $f
    }
  }
  # offset repnum by the current no. of repsentations
  set repnum [expr [molinfo $clust_mol get numreps]]
  mol rep $rep_type
  mol selection [[namespace current]::set_sel]
  mol addrep $clust_mol
  #puts "DEBUG: repnum = $repnum num= $num"
  mol drawframes $clust_mol $repnum $frames
  set col [lindex $colors $num]
  mol modcolor $repnum $clust_mol ColorID $col
}

# Delete all reps
# v0.1 erase all/ previously calculated clusters depends on choices
proc clusteringtool::del_reps {clust_mol} {
  variable keep_rep
  variable cluster0
  variable clust_rep
  
  if {$keep_rep} {
    set repstart $clust_rep
  } else {
    set restart 0
  }
  set numreps [molinfo $clust_mol get numreps]
  #if { ($keep_rep) && ([array exists cluster0])} {
     #set repstart [expr [molinfo $clust_mol get numreps] - [array size cluster0]]

     #check for exception
  #   if {$repstart<0} { set repstart $numreps}
  #} elseif {$keep_rep} { 
  #   set repstart $numreps
  #}  
  #puts "DEBUG: repstart = $repstart numreps = $numreps"

  for {set r [expr $numreps-1]} {$r >= $repstart} {incr r -1} {
    mol delrep $r $clust_mol
  }
}

# Set on/off one or more clusters
proc clusteringtool::clus_onoff_all {state} {
  variable cluster0

  for {set c 0} {$c < [array size cluster0]} {incr c 1} {
    [namespace current]::clus_onoff $state $c
  }
}

# Set on/off a cluster 
# v0.1 support showing only centroid
proc clusteringtool::clus_onoff {state clus} {
  variable clust_mol
  variable cluster0
  variable clust_list
  variable conf_list
  variable confs
  variable w
  variable show_centroid
  variable clust_rep

  #find no. of non-cluster representation, offset $clus
  #set repnum [expr [molinfo $clust_mol get numreps]-[array size cluster0]+$clus]
  set repnum [expr $clust_rep+$clus]
  set name [[namespace current]::name_del_count $clus]
  #puts "DEBUG: cluster $clus name $name"
   
    
  if { $state == 0 } {
    $clust_list selection clear $clus
  } else {
    $clust_list selection set $clus
  }

  set this $cluster0($name)

  if { $state == 0 } {
    foreach f $this {
      $conf_list selection clear $confs($f)
    }
    mol showrep $clust_mol $repnum off
  } else {
    if {$show_centroid} {
        $conf_list selection set $confs([lindex $this 0])
        lappend frames [lindex $this 0]
    } else {
      foreach f $this {
        $conf_list selection set $confs($f)
        lappend frames $f
      }
    }
    mol drawframes $clust_mol $repnum $frames
    mol showrep $clust_mol $repnum on
  }
}

# Set on one or more clusters
proc clusteringtool::clus_on {clus} {
  [namespace current]::clus_onoff 1 $clus
}

# Set off one or more clusters
proc clusteringtool::clus_off {clus} {
  [namespace current]::clus_onoff 0 $clus
}


#############################################################################
# Other

# Select next available color
proc clusteringtool::next_color {} {
  variable colors
  variable color

  incr color
  #puts "Color $color [lindex [colorinfo colors] $color]"

  # Avoid same color as VMD background
  if {[colorinfo index [colorinfo category Display Background]] == $color} {
    incr color
    #puts "     ...same as bg ... switch to $color"
  }

  # Recycle colors
  if {$color > [colorinfo num]} {
    set color 0
    #puts "     ...over max ... switch to $color"
  }
  #puts "DEBUG: color $color"
  lappend colors $color
  return $color
}

# Convert a VMD color index to rgb
proc clusteringtool::index2rgb {i} {
  set len 2
  lassign [colorinfo rgb $i] r g b
  set r [expr {int($r*255)}]
  set g [expr {int($g*255)}]
  set b [expr {int($b*255)}]
  #puts "$i      $r $g $b"
  return [format "#%.${len}X%.${len}X%.${len}X" $r $g $b]
}

# Select black or white color depending on the brightness of the rgb passed
proc clusteringtool::bw {rgb} {
  set r [scan [string range $rgb 1 2] "%2x"]
  set g [scan [string range $rgb 3 4] "%2x"]
  set b [scan [string range $rgb 5 6] "%2x"]

  set brightness [expr {$r * 0.299 + $g * 0.587 + $b * 0.114}]
  if {$brightness < 186} {
    return "#FFFFFF"
  } else {
    return "#000000"
  }
}

# Parse selection
proc clusteringtool::set_sel {} {
  variable w
  variable bb_only
  variable trace_only
  variable noh
  variable bb_def

  regsub -all "\#.*?\n" [$w.sel.left.sel get 1.0 end] "" temp1
  regsub -all "\n" $temp1 " " temp2
  regsub -all " $" $temp2 "" temp3
  if { $trace_only } {
    append sel "($temp3) and name CA"
  } elseif { $bb_only } {
    append sel "($temp3) and name $bb_def"
  } elseif { $noh} {
    append sel "($temp3) and noh"
  } else {
    append sel $temp3
  }
  return $sel
}

# Join single member clusters in a separate cluster
proc clusteringtool::join_1members {} {
  variable cluster0

  foreach name [array names cluster0] {
    #puts "$name - $cluster0($name)"
    if {[llength $cluster0($name)] == 1} {
      if [info exists cluster0(none)] {
        set cluster0(none) [concat $cluster0(none) $cluster0($name)]
      } else {
        set cluster0(none) $cluster0($name)
      }
      unset cluster0($name)
    }
  }
}

# Decrease all members of a list by 1
proc clusteringtool::decrease_list {data} {
  for {set i 0} {$i < [llength $data]} {incr i} {
    lset data $i [expr {[lindex $data $i] - 1}]
  }
  return $data
}

# Control selection modifiers
proc clusteringtool::ctrlbb { obj } {
  variable w
  variable bb_only
  variable trace_only
  variable noh

  if {$obj == "bb"} {
    set trace_only 0
    set noh 0
  } elseif {$obj == "trace"} {
    set bb_only 0
    set noh 0
  } elseif {$obj == "noh"} {
    set trace_only 0
    set bb_only 0
  }
}

# Add number of conformations to cluster name
proc clusteringtool::name_add_count {name} {
  variable cluster0
  return "$name ([llength $cluster0($name)])"
}

# Remove number of conformations from cluster name
proc clusteringtool::name_del_count {index} {
  variable clust_list
  if { [ regexp {^([0-9]+|none) \(} [$clust_list get $index] dummy name ] } {
    return $name
  }
}

# About
proc clusteringtool::about { {parent .clustering} } {
  variable webpage
  set vn [package present clusteringtool]
  tk_messageBox -title "About VMD Clustering Tool v$vn" -parent $parent -message \
    "VMD Clustering Tool v$vn

VMD Clustering Tool is a VMD plugin tp calculate and visualize clusters of conformations of molecules. Designed based on a previous version by Dr. Luis Gracia.

More information at:
$webpage

Copyright (C) Kin Lam <kinlam2@ks.uiuc.edu>

"
}


#############################################################################
# Import

proc clusteringtool::import {type} {
  variable clust_file
  variable cluster
  variable level_list

  set clust_file [tk_getOpenFile -title "Cluster filename" -filetypes [list {"Cluster files" {.out .log .dat .clg}} {"All Files" *}] ]

  if {[file readable $clust_file]} {
    set fileid [open $clust_file "r"]
    if {[array exists cluster]} {unset cluster}
    $level_list delete 0 end
    [namespace current]::import_$type $fileid
    close $fileid
  }
}

# NMRCLUSTER (http://neon.chem.le.ac.uk/nmrclust, not working)
proc clusteringtool::import_nmrcluster {fileid} {
  variable level_list
  variable cluster

  # Read data
  set i 0
  while {![eof $fileid]} {
    gets $fileid line
    if { [ regexp {^Members:([ 0-9]+)} $line dummy data ] } {
      incr i 1
      set cluster(0:$i) [[namespace current]::decrease_list $data]
    } elseif { [ regexp {^Outliers:([ 0-9]+)} $line dummy data ] } {
      foreach d $data {
        incr i 1
        set cluster(0:$i) [expr {$d - 1}]
      }
    }
  }

  $level_list insert end 0
  $level_list selection set 0

  [namespace current]::UpdateLevels
}

# XCLUSTER (http://www.schrodinger.com)
proc clusteringtool::import_xcluster {fileid} {
  variable level_list
  variable cluster

  # Read data
  while {![eof $fileid]} {
    gets $fileid line
    if { [ regexp {^Starting} $line ] } {
    } elseif { [ regexp {^Clustering ([0-9]+); threshold distance ([0-9.]+); ([0-9]+) cluster} $line dummy level threshold ncluster ] } {
      #puts "DEBUG: clustering $level $threshold $ncluster"
      $level_list insert end $level
    } elseif { [ regexp {^Cluster +([0-9]+); Leading member= +([0-9]+); +([0-9]+) members, sep_rat +([0-9.]+)} $line dummy num clust_leader clust_size clust_sep ] } {
      #puts "DEBUG: cluster $num $clust_leader $clust_size $clust_sep"
    } elseif { [ regexp {^([ 0-9]+)$} $line dummy data ] } {
      append cluster($level:$num) [[namespace current]::decrease_list $data]
      #puts "DEBUG: adding level $level cluster $num data $data"
    }
  }

  $level_list selection set 0

  [namespace current]::UpdateLevels
}

# Output from cutree from R package stats (http://stat.ethz.ch/R-manual/R-patched/library/stats/html/cutree.html)
proc clusteringtool::import_cutree {fileid} {
  variable level_list
  variable cluster

  # Read data
  set sep { }

  # - levels
  gets $fileid line
  set levels [split $line $sep]
  #puts "DEBUG: levels [join $levels {, }]"
  foreach level $levels {
    $level_list insert end $level
  }

  # - membership
  while {![eof $fileid]} {
    gets $fileid line
    if { [regexp {^$} $line dummy] } {
    } elseif { [regexp {^#} $line dummy] } {
    } else {
      set temp [split $line $sep]
      set obj [lindex $temp 0]
      set membership [lrange $temp 1 end]
      #puts "DEBUG: obj $obj; membership [join $membership {, }]"
      for {set i 0} {$i < [llength $membership]} {incr i} {
        set level [lindex $levels $i]
        set num [lindex $membership $i]
        #puts "DEBUG: assign $i - $level - $num"
        lappend cluster($level:$num) [expr {$obj - 1}]
      }
    }
  }
  $level_list selection set 0

  [namespace current]::UpdateLevels
}

# GROMACS, output from g_cluster (http://www.gromacs.org/documentation/reference/online/g_cluster.html)
proc clusteringtool::import_gcluster {fileid} {
  variable level_list
  variable cluster

  set start_reading 0
  # Read data
  while {![eof $fileid]} {
    gets $fileid line
    if { [regexp {^cl\. \|} $line dummy] } {
      #puts "DEBUG: start to read"
      set start_reading 1
    }

    if {$start_reading == 1} {
      if { [regexp {^\s*(\d+)\s+\|\s+([\d.e-]+)\s+([\d.]+)\s+\|\s+([\d.e-]+)\s+([\d.]+)\s+\|([\s\d.e-]+)} $line dummy num size st_rmsd middle mid_rmsd members ] } {
        # start a new cluster
        #puts "DEBUG: cluster $num size $size middle $middle"
        #puts "DEBUG:    -> $members"
        set cluster(0:$num) $members
        append times $members
      } elseif { [regexp {^\s*(\d+)\s+\|\s+([\d.e-]+)\s+\|\s+([\d.e-]+)\s+\|([\s\d.e-]+)} $line dummy num size middle members ] } {
        # start a new cluster with only one conf
        #puts "DEBUG: cluster $num size $size middle $middle"
        #puts "DEBUG:    -> $members"
        set cluster(0:$num) $members
        append times $members
      } elseif { [regexp {^\s+\|\s+\|\s+\|([\s\d.e-]+)} $line dummy members] } {
        # add conformations to a cluster
        #puts "DEBUG:    -> $members"
        append cluster(0:$num) $members
        append times $members
      }
    }
  }

  # Convert time into steps
  set sorted [lsort -real $times]
  for {set i 0} {$i < [llength $sorted]} {incr i} {
    set corr([lindex $sorted $i]) $i
  }
  foreach key [array names cluster] {
    if {[info exists temp2]} {
      unset temp2
    }
    foreach el $cluster($key) {
      lappend temp2 $corr($el)
    }
    set cluster($key) $temp2
  }

  $level_list insert end 0
  $level_list selection set 0

  [namespace current]::UpdateLevels
}

# CHARMM
proc clusteringtool::import_charmm {fileid} {
  variable level_list
  variable cluster

  # Read data
  while {![eof $fileid]} {
    gets $fileid line
    #puts "DEBUG: $line"
    if { [ regexp {^\s+(\d+)\s+(\d+)\s+(\d+)\s+([\d.eE+-]+)} $line dummy num member series distance ] } {
      #puts "DEBUG: $num -> $member -> $series -> $distance"
      lappend cluster(0:$num) [expr {$member - 1}]
    }
  }

  $level_list insert end 0
  $level_list selection set 0

  [namespace current]::UpdateLevels
}


#############################################################################
# Calculate

proc clusteringtool::calculate {} {
  variable cluster
  variable cluster0
  variable level_list
  variable clust_mol
  variable calc_num
  variable calc_cutoff
  variable calc_first
  variable calc_last
  variable calc_step
  variable calc_distfunc
  variable calc_selupdate
  variable calc_weight
  variable clust_rep
  #update cluster representation offset number
  if {[array exists cluster0]} {
    set clust_rep [expr [molinfo $clust_mol get numreps]-[array size cluster0]]
    #if negative, assume all current repsentations will be kept
    if {$clust_rep<0} { set clust_rep [molinfo $clust_mol get numreps]}
  } else {
    set clust_rep [molinfo $clust_mol get numreps]
  }
  #puts "DEBUG: clust_rep = $clust_rep"

  # Get selection
  set seltext [[namespace current]::set_sel]
  if {$seltext == ""} {
    showMessage "Selection is empty selection!"
    return -code return
  }
  set sel [atomselect $clust_mol $seltext]

  # Cluster
  set result [measure cluster $sel num $calc_num cutoff $calc_cutoff \
                first $calc_first last $calc_last step $calc_step \
                distfunc $calc_distfunc selupdate $calc_selupdate weight $calc_weight]

  set nclusters [llength $result]

  if {$nclusters > 0} {
    if {[array exists cluster]} {unset cluster}
    $level_list delete 0 end

    # Add cluster
    for {set num 0} {$num < [expr {$nclusters - 1}]} {incr num} {
      if {[llength [lindex $result $num]] > 0} {
        set cluster(0:$num) [lindex $result $num]
      }
    }

    # Add unclustered frames
    set num [expr {$nclusters - 1}]
    set nocluster [lindex $result $num]
    for {set i 0} {$i < [llength $nocluster]} {incr i} {
      set cluster(0:$num) [lindex $nocluster $i]
      incr num
    }

    $level_list insert end 0
    $level_list selection set 0

    [namespace current]::UpdateLevels
  }
}
