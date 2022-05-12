# BMS Cockpit Hotspot Visualizer

A tool to add, modify, and delete cockpit hotspots for Falcon BMS.

[**DOWNLOAD LATEST RELEASE (v0.2)**](https://github.com/musurca/bms_cockpit_hotspot_visualizer/releases/download/v0.2/bms_cockpit_hotspot_visualizer_0.2.zip)

![Screenshot](https://raw.githubusercontent.com/musurca/bms_cockpit_hotspot_visualizer/main/img/screenshot.jpg)

## INSTRUCTIONS:

1) Download the latest release and unzip to a new directory.
2) Run BMS Cockpit Hotspot Visualizer.exe.
3) Click on the *FILE* menu (top right corner), and click on **Import from File...*
4) Choose the corresponding `3dButtons.dat` for the cockpit you want to edit. These .dat files can be found in the `Art\CkptArt\<Plane Name>` folder.
5) When you're finished editing the hotspots, click on the *FILE* menu (top right corner), and click on **Export to File...*
*(Make sure you back up the existing .dat file before overwriting!)*

## CONTROLS

To make a new hotspot, select an existing hotspot and click the *Duplicate* button. Your new hotspot will be selected in the same position. Nudge it away from the old hotspot before editing.

To remove a hotspot, add the string "_DEL" to the hotspot name, then click *Change Name.* (This somewhat roundabout process is to ensure that you REALLY want to delete that hotspot.)

Left Mouse Btn (held): Move camera forward and back
Middle Mouse Btn (held): Move camera up/down/left/right
Right Mouse Btn (held): Rotate view

*Toggle Activation Type* will toggle between displaying hotspots that are activated with a left- or right-click.

## BUILD INFORMATION

Built with [Processing 4 (beta 8)](https://processing.org/). Library dependencies are:

* controlP5
* OCD: Obsessive Camera Direction