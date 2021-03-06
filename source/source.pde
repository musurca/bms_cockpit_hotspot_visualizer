/*

  BMS Cockpit Hotspot Visualizer v0.2
  by Nicholas Musurca (@Gadfly)
 
  https://github.com/musurca/bms_cockpit_hotspot_visualizer
  Licensed under GPL v3
*/

import java.util.*;

import damkjer.ocd.*;
import controlP5.*;

String VERSION = "0.2";

float DEFAULT_MOVE_AMT = 0.1;
int DEFAULT_SOUND = 122;
int DEFAULT_SIZE = 20;
String SEPARATOR = "                                                                 ";

float moveAmt = DEFAULT_MOVE_AMT;

File lastExportFile = null;

ControlP5 gui;
Group hotspotCtrl;
Group fileCtrl;

boolean fileSelecting = false;
boolean modeSelecting = false;
int hoverIndex = -1;
int selectIndex = -1;

ArrayList<String> hotspotNames;
ArrayList<PVector> hotspotPts;
ArrayList<Integer> hotspotSizes;
ArrayList<Integer> hotspotSounds;
ArrayList<Integer> hotspotBtns;
ArrayList<Boolean> hotspotWheel;
ArrayList<PVector> screenSpots;

Camera viewCamera;

float dist_2d(float x0, float y0, float x1, float y1) {
  float dx = x1-x0;
  float dy = y1-y0;
  return sqrt(dx*dx+dy*dy);
}

PVector convert_pt(PVector pv) {
  return new PVector( pv.x * width/2,
    pv.y * width/2,
    pv.z * width/2 );
}

void makeGUI() {
  gui = new ControlP5(this);

  hotspotCtrl = gui.addGroup("Hotspot Control")
    .setPosition(0, 10)
    .setSize(300, 0)
    .setBackgroundHeight(250)
    .setBackgroundColor(color(255, 90))
    ;

  gui.addTextfield("Hotspot Name")
    .setPosition(10, 10)
    .setSize(200, 20)
    .setAutoClear(false)
    .setColor(color(255, 255, 255))
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("Change Name")
    .setPosition(215, 10)
    .setSize(80, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("-Y") // -X
    .setPosition(60, 90)
    .setSize(25, 20)
    .setGroup(hotspotCtrl)
    ;
  gui.addButton("+Y") // +X
    .setPosition(10, 90)
    .setSize(25, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("+Z") // -Y
    .setPosition(35, 55)
    .setSize(25, 20)
    .setGroup(hotspotCtrl)
    ;
  gui.addButton("-Z") // +Y
    .setPosition(35, 125)
    .setSize(25, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("+X") //+Z
    .setPosition(90, 55)
    .setSize(25, 20)
    .setGroup(hotspotCtrl)
    ;
  gui.addButton("-X") //-Z
    .setPosition(90, 125)
    .setSize(25, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addTextfield("Size")
    .setPosition(185, 50)
    .setSize(25, 20)
    .setAutoClear(false)
    .setColor(color(255, 255, 255))
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("Change Size")
    .setPosition(215, 50)
    .setSize(80, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addTextfield("Sound")
    .setPosition(185, 90)
    .setSize(25, 20)
    .setAutoClear(false)
    .setColor(color(255, 255, 255))
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("Change Sound")
    .setPosition(215, 90)
    .setSize(80, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addTextfield("Nudge Step")
    .setPosition(120, 85)
    .setSize(45, 20)
    .setAutoClear(false)
    .setColor(color(255, 255, 255))
    .setText(String.valueOf(DEFAULT_MOVE_AMT))
    .setGroup(hotspotCtrl)
    ;

  gui.addTextfield("X Pos")
    .setPosition(10, 170)
    .setSize(60, 20)
    .setAutoClear(false)
    .setGroup(hotspotCtrl)
    ;
  gui.addTextfield("Y Pos")
    .setPosition(80, 170)
    .setSize(60, 20)
    .setAutoClear(false)
    .setGroup(hotspotCtrl)
    ;
  gui.addTextfield("Z Pos")
    .setPosition(150, 170)
    .setSize(60, 20)
    .setAutoClear(false)
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("Update")
    .setPosition(215, 170)
    .setSize(80, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("Duplicate")
    .setPosition(10, 220)
    .setSize(100, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addButton("Deselect")
    .setPosition(240, 220)
    .setSize(50, 20)
    .setGroup(hotspotCtrl)
    ;

  gui.addToggle("Scroll Wheel")
    .setPosition(160, 130)
    .setValue(false)
    .setGroup(hotspotCtrl)
    ;

  gui.addScrollableList("Activation")
    .setPosition(225, 130)
    .setSize(70, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(Arrays.asList("Left Click", "Right Click"))
    .setValue(0)
    .setGroup(hotspotCtrl)
    ;

  hotspotCtrl.close();
  hotspotCtrl.hide();

  fileCtrl = gui.addGroup("File")
    .setPosition(width-100, 10)
    .setSize(100, 0)
    .setBackgroundHeight(90)
    .setBackgroundColor(color(255, 90))
    ;

  gui.addButton("Import from File...")
    .setPosition(10, 10)
    .setSize(80, 20)
    .setGroup(fileCtrl)
    ;

  gui.addTextlabel("Import Status")
    .setPosition(20, 35)
    .setText("")
    .setGroup(fileCtrl)
    ;

  gui.addButton("Export to File...")
    .setPosition(10, 50)
    .setSize(80, 20)
    .setGroup(fileCtrl)
    ;

  gui.addTextlabel("Export Status")
    .setPosition(20, 75)
    .setText("")
    .setGroup(fileCtrl)
    ;

  fileCtrl.open();

  gui.addToggle("Toggle Activation Type")
    .setPosition(20, height-40)
    .setValue(false);

  gui.addTextlabel("Help")
    .setPosition(width-165, height-30)
    .setText("LMB:  MOVE FWD/BACK\nMMB: MOVE UP/DOWN/LEFT/RIGHT\nRMB: ROTATE VIEW");
}

void setImportSuccess(boolean state) {
  makeGUI(); // workaround for controlP5 GUI bug
  String stateName = "FAILURE!";
  if (state) {
    stateName = "";
    fileCtrl.close();
  }
  gui.get(Textlabel.class, "Import Status").setText(stateName);
}

void setExportSuccess(boolean state) {
  makeGUI();  // workaround for controlP5 GUI bug
  String stateName = "FAILURE!";
  if (state) {
    stateName = "SUCCESS!";
  }
  gui.get(Textlabel.class, "Export Status").setText(stateName);
}

void initTables() {
  hotspotNames = new ArrayList<String>();
  hotspotPts = new ArrayList<PVector>();
  hotspotSizes = new ArrayList<Integer>();
  hotspotSounds = new ArrayList<Integer>();
  hotspotBtns = new ArrayList<Integer>();
  hotspotWheel = new ArrayList<Boolean>();
  screenSpots = new ArrayList<PVector>();
}


void export(File exportfile) {
  if (exportfile == null) {
    return;
  }

  lastExportFile = exportfile;

  String exportPath = exportfile.getAbsolutePath();
  ArrayList<String> output = new ArrayList<String>();

  output.add("----- Created by BMS Cockpit Hotspot Visualizer v" + VERSION + " -----");
  for (int i = 0; i < hotspotNames.size(); i++) {
    String name = hotspotNames.get(i);
    PVector pt = hotspotPts.get(i);
    int size = hotspotSizes.get(i);
    int snd = hotspotSounds.get(i);
    int btn = hotspotBtns.get(i);
    String wheel = "";
    if (hotspotWheel.get(i)) {
      wheel = "    w";
    }
    String sep = SEPARATOR.substring(name.length());

    // -z x -y
    output.add(
      name + sep +
      String.valueOf(-pt.z) + " "    +
      String.valueOf(pt.x)  + " "    +
      String.valueOf(-pt.y) + "    " +
      String.valueOf(size)  + "  "   +
      String.valueOf(snd)   + "   "  +
      String.valueOf(btn) + wheel
      );
  }

  String [] arr = new String[output.size()];
  arr = output.toArray(arr);
  try {
    saveStrings(exportPath, arr);
  }
  catch(Exception e) {
    setExportSuccess(false);
    return;
  }

  setExportSuccess(true);
}

void importHotspots(File selection) {
  if (selection == null) {
    return;
  }

  // clear any selection
  hoverIndex = -1;
  selectIndex = -1;

  // reinit data
  initTables();

  // Import the hotspots
  String importPath = selection.getAbsolutePath();
  String[] lines;
  try {
    lines = loadStrings(importPath);
  }
  catch(Exception e) {
    setImportSuccess(false);
    return;
  }

  for (int i = 0; i < lines.length; i++) {
    String l = lines[i];
    if (l.contains("//") || l.contains("--")) {
      continue;
    }
    String[] data = l.split("(\\s+)");
    /*
    for (int j = 0; j < data.length; j++) {
     print(data[j] + " ");
     }
     print("\n");
     */
    if (data.length < 7) {
      continue;
    }

    String name;
    float x, y, z;
    int size, sound, btn;
    try {
      name = data[0];

      // -z x -y
      z = -Float.parseFloat(data[1]);
      x = Float.parseFloat(data[2]);
      y = -Float.parseFloat(data[3]);
      size = Integer.parseInt(data[4]);
      sound = Integer.parseInt(data[5]);
      btn = Integer.parseInt(data[6]);
    }
    catch(Exception e) {
      // Skip the line
      continue;
    }

    hotspotNames.add(name);
    hotspotPts.add(new PVector(x, y, z));
    hotspotSizes.add(size);
    hotspotSounds.add(sound);
    hotspotBtns.add(btn);

    boolean hasWheel = false;
    if (data.length >= 8) {
      if (data[7].contains("w")) {
        hasWheel = true;
      }
    }
    hotspotWheel.add(hasWheel);

    screenSpots.add(new PVector());
  }

  setImportSuccess(true);
}

void setup() {
  size(1024, 768, P3D);
  surface.setTitle("BMS Cockpit Hotspot Visualizer - v" + VERSION);
  //surface.setResizable(true);

  makeGUI();

  viewCamera = new Camera(this);
  viewCamera.jump(0, 0, -275);
  textSize(12);
  background(0, 0, 0);
  noStroke();

  initTables();

  //importHotspots();
}

void draw() {
  clear();

  boolean btnType = gui.get(Toggle.class, "Toggle Activation Type").getState();

  hint(ENABLE_DEPTH_TEST);
  // Show hotspot points
  for (int i = 0; i < hotspotNames.size(); i++) {
    int type = hotspotBtns.get(i);
    if ((btnType && type == 2) || (!btnType && type == 1)) {
      PVector pos = hotspotPts.get(i);
      float size = (float)hotspotSizes.get(i);

      viewCamera.feed();

      pushMatrix();
      PVector apos = convert_pt(pos);
      translate(apos.x, apos.y, apos.z);
      if (selectIndex == i) {
        fill(0, 255, 0);
      } else if (hoverIndex == i) {
        fill(255, 255, 255);
      } else {
        fill(190, 190, 190);
      }
      sphere( max(1, size - 15.5) );
      popMatrix();

      float sx = screenX(apos.x, apos.y, apos.z);
      float sy = screenY(apos.x, apos.y, apos.z);
      float sz = screenZ(apos.x, apos.y, apos.z);

      screenSpots.set(i, new PVector(sx, sy, sz));
    } else {
      screenSpots.set(i, new PVector(-99999, -99999, -9999));
    }
  }

  fill(255, 255, 255);

  // Find nearest hotspot to mouse
  hoverIndex = -1;
  float dist = 999999;
  for (int i = 0; i < hotspotNames.size(); i++) {
    int type = hotspotBtns.get(i);
    if ((btnType && type == 2) || (!btnType && type == 1)) {
      int size = hotspotSizes.get(i);
      PVector pos = screenSpots.get(i);
      if (pos.z > 0 && pos.z != -9999) {
        float d = dist_2d(mouseX, mouseY, pos.x, pos.y);
        if (d < dist && d < size/2) {
          dist = d;
          hoverIndex = i;
        }
      }
    }
  }

  camera();

  // Show hotspot name if hovering
  if (hoverIndex != -1) {
    String name = hotspotNames.get(hoverIndex);
    PVector pos = screenSpots.get(hoverIndex);
    float size = (float)hotspotSizes.get(hoverIndex);
    //
    //textMode(MODEL);

    text(
      name,
      pos.x,
      pos.y+(max(1, size))*(pos.z),
      pos.z
      );
  }

  hint(DISABLE_DEPTH_TEST);

  //float [] pos = viewCamera.position();
  //print(pos[0] + "\t" + pos[1] + "\t" + pos[2] + "\n");
}

public void controlEvent(ControlEvent theEvent) {
  String name;
  // Validate move amt
  try {
    name = gui.get(Textfield.class, "Nudge Step").getText().trim().replaceAll("[^0-9.]", "");
    moveAmt = Float.parseFloat(name);
  }
  catch(Exception e) {
    moveAmt = DEFAULT_MOVE_AMT;
  }
  moveAmt = abs(moveAmt);
  gui.get(Textfield.class, "Nudge Step").setText(String.valueOf(moveAmt));

  // Handle events
  int snd;
  int size;
  int btn;
  boolean wheel;

  PVector pt;
  if (selectIndex == -1) {
    pt = new PVector();
  } else {
    pt = hotspotPts.get(selectIndex);
  }

  String evtName = theEvent.getController().getName();
  switch(evtName) {
  case "+Y":
    pt.x += moveAmt;
    selectHotspot(selectIndex);
    break;
  case "-Y":
    pt.x -= moveAmt;
    selectHotspot(selectIndex);
    break;
  case "-Z":
    pt.y += moveAmt;
    selectHotspot(selectIndex);
    break;
  case "+Z":
    pt.y -= moveAmt;
    selectHotspot(selectIndex);
    break;
  case "+X":
    pt.z += moveAmt;
    selectHotspot(selectIndex);
    break;
  case "-X":
    pt.z -= moveAmt;
    selectHotspot(selectIndex);
    break;
  case "Change Name":
    if (selectIndex != -1) {
      name = gui.get(Textfield.class, "Hotspot Name").getText().trim().replaceAll("[^a-zA-Z0-9_]", "");

      if (name.contains("_DEL")) {
        // Delete the hotspot
        hotspotNames.remove(selectIndex);
        hotspotPts.remove(selectIndex);
        hotspotSizes.remove(selectIndex);
        hotspotSounds.remove(selectIndex);
        hotspotBtns.remove(selectIndex);
        hotspotWheel.remove(selectIndex);
        screenSpots.remove(selectIndex);

        selectHotspot(-1);
      } else {
        hotspotNames.set(selectIndex, name);

        // Set our filtered name
        gui.get(Textfield.class, "Hotspot Name").setText(name);
      }
    }
    break;
  case "Change Size":
    if (selectIndex != -1) {
      try {
        name = gui.get(Textfield.class, "Size").getText().trim().replaceAll("[^0-9]", "");
        size = Integer.parseInt(name);
      }
      catch(Exception e) {
        size = DEFAULT_SIZE;
      }
      gui.get(Textfield.class, "Size").setText(String.valueOf(size));
      hotspotSizes.set(selectIndex, size);
    }
    break;
  case "Change Sound":
    if (selectIndex != -1) {
      try {
        name = gui.get(Textfield.class, "Sound").getText().trim().replaceAll("[^0-9]", "");
        snd = Integer.parseInt(name);
      }
      catch(Exception e) {
        snd = DEFAULT_SOUND;
      }
      gui.get(Textfield.class, "Sound").setText(String.valueOf(snd));
      hotspotSounds.set(selectIndex, snd);
    }
    break;
  case "Update":
    if (selectIndex != -1) {
      float x, y, z;
      try {
        z = -Float.parseFloat(gui.get(Textfield.class, "X Pos").getText());
        x = Float.parseFloat(gui.get(Textfield.class, "Y Pos").getText());
        y = -Float.parseFloat(gui.get(Textfield.class, "Z Pos").getText());
      }
      catch(Exception e) {
        selectHotspot(selectIndex);
        break;
      }
      pt.x = x;
      pt.y = y;
      pt.z = z;
      selectHotspot(selectIndex);
    }
    break;
  case "Activation":
    if (selectIndex != -1) {
      btn = ((int)gui.get(ScrollableList.class, "Activation").getValue()) + 1;
      hotspotBtns.set(selectIndex, btn);

      boolean btnType = gui.get(Toggle.class, "Toggle Activation Type").getState();
      if ((btn == 1 && btnType) || (btn == 2 && !btnType)) {
        gui.get(Toggle.class, "Toggle Activation Type").toggle();
      }
    }
    break;

  case "Deselect":
    selectIndex = -1;
    hotspotCtrl.close();
    hotspotCtrl.hide();
    break;
  case "Duplicate":
    if (selectIndex != -1) {
      int newIndex = hotspotNames.size();
      name = hotspotNames.get(selectIndex) + "_NEW";
      PVector oldpos = hotspotPts.get(selectIndex);
      PVector pos = new PVector(oldpos.x, oldpos.y, oldpos.z);
      size = hotspotSizes.get(selectIndex);
      snd = hotspotSounds.get(selectIndex);
      btn = hotspotBtns.get(selectIndex);
      wheel = hotspotWheel.get(selectIndex);

      hotspotNames.add(name);
      hotspotPts.add(pos);
      hotspotSizes.add(size);
      hotspotSounds.add(snd);
      hotspotBtns.add(btn);
      hotspotWheel.add(wheel);
      screenSpots.add(new PVector());

      selectHotspot(newIndex);
    }
    break;
  case "Scroll Wheel":
    if (selectIndex != -1) {
      wheel = gui.get(Toggle.class, "Scroll Wheel").getState();
      hotspotWheel.set(selectIndex, wheel);
    }
    break;
  case "Import from File...":
    if (!fileSelecting) {
      fileSelecting = true;
      selectInput("Select a .dat file to import:", "importHotspots");
      fileSelecting = false;
    }
    break;
  case "Export to File...":
    if (!fileSelecting) {
      fileSelecting = true;
      if (lastExportFile != null) {
        selectOutput("Select a .dat file to export:", "export", lastExportFile);
      } else {
        selectOutput("Select a .dat file to export:", "export");
      }
      fileSelecting = false;
    }
    break;
  }
}

boolean mouseOutsideControl() {
  if (hotspotCtrl.isOpen()) {
    if (mouseX < 300 && mouseY < 260) return false;
  } else if (hotspotCtrl.isMouseOver()) {
    return false;
  }

  if (fileCtrl.isOpen()) {
    if (mouseX >= width-300 && mouseX < width && mouseY < 120) {
      return false;
    }
  } else if (fileCtrl.isMouseOver()) {
    return false;
  }

  // Activation toggle
  if (mouseX <= 100 && mouseY >= height-40) {
    return false;
  }

  return true;
}

void selectHotspot(int index) {
  selectIndex = index;

  if (index == -1) {
    hotspotCtrl.close();
    hotspotCtrl.hide();
    return;
  }

  String name = hotspotNames.get(selectIndex);
  PVector pos = hotspotPts.get(selectIndex);
  int btn = hotspotBtns.get(selectIndex);
  int size = hotspotSizes.get(selectIndex);
  int snd = hotspotSounds.get(selectIndex);
  boolean wheel = hotspotWheel.get(selectIndex);

  gui.get(Textfield.class, "Hotspot Name").setText(name);
  gui.get(ScrollableList.class, "Activation").setValue(btn-1);
  gui.get(Toggle.class, "Scroll Wheel").setValue(wheel);
  gui.get(Textfield.class, "Size").setText(String.valueOf(size));
  gui.get(Textfield.class, "Sound").setText(String.valueOf(snd));

  gui.get(Textfield.class, "X Pos").setText(String.valueOf(-pos.z));
  gui.get(Textfield.class, "Y Pos").setText(String.valueOf(pos.x));
  gui.get(Textfield.class, "Z Pos").setText(String.valueOf(-pos.y));

  hotspotCtrl.show();
  hotspotCtrl.open();
}

void mousePressed() {
  modeSelecting = false;
  if (mouseOutsideControl()) {
    if (hoverIndex != -1) {
      modeSelecting = true;
      selectHotspot(hoverIndex);
    }
  }
}

void mouseReleased() {
  modeSelecting = false;
}

void mouseDragged()
{
  if (hotspotNames.size() > 0) {
    if (mouseOutsideControl()) {
      if (!modeSelecting) {
        if (mouseButton == LEFT) {
          viewCamera.dolly(mouseY - pmouseY);
        }
      }
      if (mouseButton == RIGHT) {
        viewCamera.look(radians(mouseX - pmouseX) / 2.0, radians(mouseY - pmouseY) / 2.0);
      }
      if (mouseButton == CENTER) {
        viewCamera.track(mouseX - pmouseX, mouseY - pmouseY);
      }
    }
  }
}
