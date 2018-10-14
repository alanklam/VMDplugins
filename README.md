# VMDplugins
This repository contains VMD GUI plugins for setting up and analyzing molecular dynamics simulations. Instructions are placed in individual folder.

## Installation
To clone this project into your local path (e.g. */path/to/plugins/directory/VMDplugins*), use the following commands:
```sh
cd /path/to/plugins/directory
git clone https://github.com/alanklam/VMDplugins.git VMDplugins
```

To add the following to *$HOME/.vmdrc* file to allow VMD to find the path, create the file if you don't have one yet:
```tcl
set auto_path [linsert $auto_path 0 {/path/to/plugins/directory/VMDplugins}]
```
