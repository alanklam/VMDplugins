# Author: Kin Lam
#   Beckman Institute for Advanced Science and Technology
#   University of Illinois, Urbana-Champaign
#   kinlam2@ks.uiuc.edu
#   http://www.ks.uiuc.edu/~kinlam2/

package provide clusteringtool 0.1

namespace eval ::clusteringtool:: {
  namespace export clusteringtool
}

# Hook for vmd, start the GUI
proc clusteringtool_tk_cb {} {
  clusteringtool::window
  return $clustering::w
}

proc clusteringtool::destroy {} {
  # Delete traces
  # Delete remaining selections

  global vmd_initialize_structure
  trace vdelete vmd_initialize_structure w [namespace code UpdateMolecules]
}

# Main window
proc clusteringtool::window {} {
  variable w;   # TK window

  variable webpage "http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/cluster"
  variable cluster;              # Array with all levels clustering (set on import)
  variable cluster0;             # Array with current selected level
  variable clust_file;           # File used to load clustering data
  variable clust_mol;            # Molecule use to show clustering
  variable clust_list;           # Listbox with clusters for selected level
  variable level_list;           # Listbox with available clustering levels
  variable conf_list;            # Listbox with conformations for a level
  variable confs;                # Array with reverse lookup for conformations
  variable join_1members      1; # Join single member clusters in a separate cluster
  variable bb_def      "C CA N"; # Backbone definition (diferent from VMD's definition)
  variable bb_only            0; # Selection modifier (only name CA C N)
  variable trace_only         0; # Selection modifier (only name CA)
  variable noh                1; # Selection modifier (no hydrogens)

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
  if { [winfo exists .clusteringtool] } {
    wm deiconify $w
    return
  }

  # GUI look
  option add *clusteringtool.*borderWidth 1
  option add *clusteringtool.*Button.padY 0
  option add *clusteringtool.*Menubutton.padY 0

  # Main window
  set w [toplevel ".clusteringtool"]
  wm title $w "VMD Clustering Analysis Tool"
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
  #$w.menubar.help.menu add command -label "Help" -command "vmd_open_url $webpage"
  $w.menubar.help.menu add command -label "About" -command [namespace current]::about

  # Use measure cluster
  # -------------
  labelframe $w.calc -text "Use measure cluster" -relief ridge -bd 2
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

  button $w.result.options.update -text "Update Views" -command [namespace code UpdateSel]
  pack $w.result.options.update -side left

  checkbutton $w.result.options.join -text "Join 1 member clusters" -variable clustering::join_1members -command [namespace code UpdateLevels]
  pack $w.result.options.join -side right

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

proc clusteringtool::cluster {sel {repid 0} {c_num 5} {cutoff 1.0} {func rmsd} {topk 3} {ff 0} {lf -1} {step 1}} {
set selatom [atomselect top $sel]

set clist [measure cluster $selatom num $c_num distfunc $func cutoff $cutoff first $ff last $lf step $step]

for {set i 0} {$i <= $c_num} {incr i} {
    mol addrep top
    mol modstyle $repid top "CPK"
    mol modselect $repid top $sel
    mol modcolor $repid top ColorID $i
    mol drawframes top $repid [lindex $clist $i]
    incr repid
    puts "Cluster $i : [lrange [lindex $clist $i] 0 [expr $topk -1 ]]"
}

}
