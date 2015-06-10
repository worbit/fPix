/* @pjs preload="charlize.jpg";*/

/*******************************************************
 code by Mathias Bernhard
 bernhard@arch.ethz.ch
 2007 - 2015
 CAAD / ETH Zurich
 and FABLAB Zurich, Yves Ebnoether
 *******************************************************/

PImage pic; //original image
boolean loaded = false;
float sf; //scaling factor of "pic" to fit the sheet
float imgrot;

PGraphics result, tmp; //preview image
boolean fit; //if true, shrink preview to fit canvas
boolean showImg;

int outW, outH; //sheet dimensions
float bitDim; //diameter of milling bit
int type; //type of pattern
float low, high; //level adjustment
float threshold; //minimal drill depth, small dots are skipped, not visible anyway
boolean con; //if false > dots, if true > lines
ArrayList<ArrayList<Dot>> myDots; //lists of calculated drill holes

boolean root = true; //sqareroot of brightness for radius > area linear

boolean targetting = false;
int centerX, centerY;

void setup() {
  size(800, 600);
  imageMode(CENTER);

  //initialize variables
  outW = 600; //width of sheet
  outH = 450; //height of sheet
  bitDim = 12; //milling bit diameter
  type = 0; //pattern type: 0=ortho grid, 1=hexa grid, 2=cocentric
  con = false; //dots connected (lines) or not (dots)
  fit = false; //make preview fit to screen
  showImg = false; //show original image instead of dots / lines
  sf = 1; //scaling factor
  imgrot = 0;
  myDots = new ArrayList<ArrayList<Dot>>();
  low = 0; //level balance
  high = 1; //level balance
  threshold = 0.05; //small dots are skipped, not visible anyway

  centerX = outW/2; //center for radial pattern
  centerY = outH/2; //center for radial pattern

  //load default test image
  loadPicture("charlize.jpg");

  //create empty preview
  result = createGraphics(outW, outH);
  result.beginDraw();
  result.background(255);
  result.endDraw();

  //calcResult();
}

void draw() {
  //dark grey background
  background(51);

  if (!loaded) {
    fitScale();
    loaded = calcResult();
  }
  //display preview
  if (result!=null) {
    if (!fit) {
      image(result, width/2, height/2);
    } else {
      float sft = min(float(width)/outW, float(height)/outH);
      image(result, width/2, height/2, sft*outW, sft*outH);
    }
  }
  if (showImg) {
    if (!fit) {
      image(tmp, width/2, height/2);
    } else {
      float sft = min(float(width)/outW, float(height)/outH);
      image(tmp, width/2, height/2, sft*outW, sft*outH);
    }
  }
}

boolean calcResult() {
  if (pic == null || pic.width<1) return false;
  result=null;
  //sf = max((float)outW/pic.width, (float)outH/pic.height);
  tmp = createGraphics(outW, outH);
  tmp.beginDraw();
  tmp.background(255);
  tmp.imageMode(CENTER);
  tmp.translate(outW/2f, outH/2f);
  tmp.rotate(radians(imgrot));
  tmp.image(pic, 0,0, pic.width*sf, pic.height*sf);
  tmp.endDraw();

  float stp = bitDim*7f/6f;
  myDots.clear();
  switch (type) {
  case 0:
    myDots = getOrthoGrid(tmp, stp);
    break;
  case 1:
    myDots = getHoneyGrid(tmp, stp);
    break;
  case 2:
    myDots = getPolarGrid(tmp, stp);
    break;
  case 3:
    myDots = getSpiralGrid(tmp, stp);
    break;
  }

  result = createPreview(myDots);
  return true;
}
class Dot {
  float x, y, z;
  boolean drilled;

  Dot(float a, float b, float c) {
    this.x = a;
    this.y = b;
    this.z = c;
    this.drilled = false;
  }
}
String generateMachineCode() {
  String out = "";
  int ln = 0;
  float fastH = 20; //fast plane for G0 commands
  float appH = 5; //clearance plane for inbetween dots
  //feedrates: G0 fast, G1 slow
  int feedG0 = 5000;
  int feedG1 = 1000;

  //head of gcode
  out += "N"+(ln++)+" "+"G17 G71 G40 G90" + "\n";
  out += "N"+(ln++)+" "+"T1 M6" + "\n";
  out += "N"+(ln++)+" G0 S20000 M3" + "\n";
  out += "N"+(ln++)+" X0 Y0 Z"+ fastH + "\n";

  
  //the below couple of lines are not necessary
  //it is done by the loop anyway
  
  Dot d = myDots.get(0).get(0);
  float cx = d.x;
  float cy = d.y;

  //body of gcode > point coordinates
  boolean downstate = true;

  //loop through all the sub-lists
  for (int i=0; i<myDots.size(); i++) {
    //get the sub-list number i
    ArrayList<Dot> li = myDots.get(i);
    //get the first dot in the sub-list
    Dot dt = li.get(0);
    out += "N"+(ln++)+" G0 X"+formatNum(dt.x)+" "+
      "Y"+formatNum(outH-dt.y)+" "+
      "Z"+fastH+"\n";

    //loop through all the dots in the sub-list
    for (int j=0; j<li.size(); j++) {
      //get dot number j from list
      Dot dot = li.get(j);
      //dot is drilled, when depth above threshold
      if (dot.drilled) {
        
        //downstate is true if previous dot was drilled
        if (!downstate) {
          //previous dot not drilled, rapid plane > approach
          out += "N"+(ln++)+" G0 X"+formatNum(dot.x)+" "+
            "Y"+formatNum(outH-dot.y)+" "+
            "Z"+fastH+" "+
            "F"+feedG0+"\n";
          out += "N"+(ln++)+" G1 X"+formatNum(dot.x)+" "+
            "Y"+formatNum(outH-dot.y)+" "+
            "Z"+appH+" "+
            "F"+feedG1+"\n";
            downstate = true;
        } else {
//          out += "N"+(ln++)+" G1 Z"+appH+" "+
//            "F"+feedG1+"<br/>";
        }

        //con is true if lines should be milled (con = connected)
        if (!con) {
          // DOTS . . . . . . . . . . . . . . . . . . . .
          
          if (dot.x!=cx) out += "N"+(ln++)+" X"+formatNum(dot.x)+"\n";
          if (dot.y!=cy) out += "N"+(ln++)+" Y"+formatNum(outH-dot.y)+"\n";
          out += "N"+(ln++)+" Z-"+formatNum(ballnoseConversion(dot.z)*bitDim/2.0)+"\n";
          out += "N"+(ln++)+" Z"+appH+"\n";
        } else {
          // LINES --------------------------------------
          // lines don't work!
          out += "N"+(ln++)+" X"+formatNum(dot.x)+" "+
            " Y"+formatNum(outH-dot.y)+" "+
            " Z-"+formatNum(ballnoseConversion(dot.z)*bitDim/2.0)+"\n";
            downstate = true;
        }
      } else { //if dot is not drilled
        //lift tool to rapid plane if dot is not drilled 
        if (downstate) out += "N"+(ln++)+" G0 Z"+fastH+"\n";
        downstate = false;
      }
      cx = dot.x;
      cy = dot.y;
    }
    out += "N"+(ln++)+" G0 Z"+fastH+"\n";
    downstate = false;
  }

  //end of gcode
  out += "N"+(ln++)+" "+"Z"+fastH+"\n";
  out += "N"+(ln++)+" "+"G0 X0 Y0"+"\n";
  out += "N"+(ln++)+" "+"M05 M09"+"\n";
  out += "N"+(ln++)+" "+"M30";

  return out;
}
String generateMachineCodeHTML() {
  String out = "";
  int ln = 0;
  float fastH = 20; //fast plane for G0 commands
  float appH = 5; //clearance plane for inbetween dots
  //feedrates: G0 fast, G1 slow
  int feedG0 = 5000;
  int feedG1 = 1000;

  //html head
  out += "<!DOCTYPE html>";
  out += "<head><style type=\"text/css\">";
  out += "body { background-color: #00f; color: #ff0; font-size: 10px; font-family: Courier, Mono; }";
  out += "</style>";
  out += "<title>SAVE AS *.NC</title>";
  out += "</head><body>";

  //head of gcode
  out += "N"+(ln++)+" "+"G17 G71 G40 G90" + "<br/>";
  out += "N"+(ln++)+" "+"T1 M6" + "<br/>";
  out += "N"+(ln++)+" G0 S20000 M3" + "<br/>";
  out += "N"+(ln++)+" X0 Y0 Z"+ fastH + "<br/>";

  
  //the below couple of lines are not necessary
  //it is done by the loop anyway
  
  Dot d = myDots.get(0).get(0);
  float cx = d.x;
  float cy = d.y;
  /*

  //first go to xy of first point
  out += "N"+(ln++)+" X"+formatNum(d.x)+" "+
    "Y"+formatNum(outH-d.y)+"<br/>";

  //lower to fast plane
  out += "N"+(ln++)+" X"+formatNum(d.x)+" "+
    "Y"+formatNum(outH-d.y)+" "+
    "Z"+fastH+"<br/>";

  //lower to clearance plane
  out += "N"+(ln++)+" X"+formatNum(d.x)+" "+
    "Y"+formatNum(outH-d.y)+" "+
    "Z"+appH+"<br/>";

  out += "N"+(ln++)+" G1 X"+formatNum(d.x)+" "+
    "Y"+formatNum(outH-d.y)+" "+
    "Z"+appH+" "+
    "F"+feedG1+"<br/>";
    */

  //body of gcode > point coordinates
  boolean downstate = true;

  //loop through all the sub-lists
  for (int i=0; i<myDots.size(); i++) {
    //get the sub-list number i
    ArrayList<Dot> li = myDots.get(i);
    //get the first dot in the sub-list
    Dot dt = li.get(0);
    out += "N"+(ln++)+" G0 X"+formatNum(dt.x)+" "+
      "Y"+formatNum(outH-dt.y)+" "+
      "Z"+fastH+"<br/>";

    //loop through all the dots in the sub-list
    for (int j=0; j<li.size(); j++) {
      //get dot number j from list
      Dot dot = li.get(j);
      //dot is drilled, when depth above threshold
      if (dot.drilled) {
        
        //downstate is true if previous dot was drilled
        if (!downstate) {
          //previous dot not drilled, rapid plane > approach
          out += "N"+(ln++)+" G0 X"+formatNum(dot.x)+" "+
            "Y"+formatNum(outH-dot.y)+" "+
            "Z"+fastH+" "+
            "F"+feedG0+"<br/>";
          out += "N"+(ln++)+" G1 X"+formatNum(dot.x)+" "+
            "Y"+formatNum(outH-dot.y)+" "+
            "Z"+appH+" "+
            "F"+feedG1+"<br/>";
            downstate = true;
        } else {
//          out += "N"+(ln++)+" G1 Z"+appH+" "+
//            "F"+feedG1+"<br/>";
        }

        //con is true if lines should be milled (con = connected)
        if (!con) {
          // DOTS . . . . . . . . . . . . . . . . . . . .
          
          if (dot.x!=cx) out += "N"+(ln++)+" X"+formatNum(dot.x)+"<br/>";
          if (dot.y!=cy) out += "N"+(ln++)+" Y"+formatNum(outH-dot.y)+"<br/>";
          out += "N"+(ln++)+" Z-"+formatNum(ballnoseConversion(dot.z)*bitDim/2.0)+"<br/>";
          out += "N"+(ln++)+" Z"+appH+"<br/>";
        } else {
          // LINES --------------------------------------
          // lines don't work!
          out += "N"+(ln++)+" X"+formatNum(dot.x)+" "+
            " Y"+formatNum(outH-dot.y)+" "+
            " Z-"+formatNum(ballnoseConversion(dot.z)*bitDim/2.0)+"<br/>";
            downstate = true;
        }
      } else { //if dot is not drilled
        //lift tool to rapid plane if dot is not drilled 
        if (downstate) out += "N"+(ln++)+" G0 Z"+fastH+"<br/>";
        downstate = false;
      }
      cx = dot.x;
      cy = dot.y;
    }
    out += "N"+(ln++)+" G0 Z"+fastH+"<br/>";
    downstate = false;
  }

  //end of gcode
  out += "N"+(ln++)+" "+"Z"+fastH+"<br/>";
  out += "N"+(ln++)+" "+"G0 X0 Y0"+"<br/>";
  out += "N"+(ln++)+" "+"M05 M09"+"<br/>";
  out += "N"+(ln++)+" "+"M30";

  //end of html
  out += "</body>";

  return out;
}
//for color images: brightness(color) only returns max(red,green,blue)
//weighted factors more accurate
//returns 1 for white and 0 for black
float luminosity(color c) {
  return (red(c)*0.3 + green(c)*0.59 + blue(c)*0.11)/255f;
}

//luminosity of picture patch
float luminosityAverage(PImage p) {
  float out = 0;
  for (int i=0; i<p.pixels.length; i++) {
    color c = p.pixels[i];
    out += luminosity(c);
  }
  return out/p.pixels.length;
}

float fitScale() {
  sf = max((float)outW/pic.width, (float)outH/pic.height);
  calcResult();
  return sf;
}

float level(float v) {
  float out = map(v, low, high, 0, 1);
  if (out>1) out = 1;
  if (out<0) out = 0;
  return out;
}

float ballnoseConversion(float n) {
  // n = fraction of full circle
  // 1 is black
  // 0 is white
  // 0.5 is half the area -> radius is sqrt(area) = 0.707
  // radius is x, x=r*cos(a) -> y = sin(acos(x))
  float x = sqrt(n);
  float a = acos(x);
  float y = sin(a);
  float out = 1-y;
  return out;
}

// format num also used for mm/inch conversion
String formatNum(float f) {
  return nf(f, 1, 4);
}
/*
every pattern must return an ArrayList of ArrayLists of Dots
one List of Dots is one line, the List of Lists is all the lines
every Dot's "drilled" attribute must be set to true, if the depth (d.z)
is above the threshold
*/


//orthogonal grid
// o o o o
// o o o o
// o o o o
ArrayList<ArrayList<Dot>> getOrthoGrid(PGraphics pg, float step) {
  int nx = floor(outW/step);
  int ny = floor(outH/step);
  float offx = (outW-((nx-1)*step))/2f;
  float offy = (outH-((ny-1)*step))/2f;

  ArrayList<ArrayList<Dot>> out = new ArrayList<ArrayList<Dot>>();

  for (int y=0; y<ny; y++) {
    ArrayList<Dot> tmpDts = new ArrayList<Dot>();
    for (int x=0; x<nx; x++) {
      PImage temp = pg.get(round(x*step), round(y*step), round(step), round(step));
      float val = luminosityAverage(temp);
      val = level(val);
      //float dim = (1-val) * bitDim;

      Dot d = new Dot(offx+x*step, offy+y*step, 1-val);
      tmpDts.add(d);
      if (d.z>threshold) d.drilled = true;
    }
    out.add(tmpDts);
  }
  return out;
}

//honeycomb grid
// o o o o
//  o o o
// o o o o
ArrayList<ArrayList<Dot>> getHoneyGrid(PGraphics pg, float step) {
  float rt3 = sqrt(3.0);
  int nx = floor(outW/step);
  int ny = floor(outH/(step/2*rt3));
  // ny = floor(outH/step);

  float offx = (outW-((nx-1)*step))/2f;
  float offy = (outH-((ny-1)*(step/2*rt3)))/2f;
  //offy = offx;

  ArrayList<ArrayList<Dot>> out = new ArrayList<ArrayList<Dot>>();
  boolean pnd = false;
  for (int y=0; y<ny; y++) {
    ArrayList<Dot> tmpDts = new ArrayList<Dot>();
    for (int x=0; x<(pnd?(nx-1):nx); x++) {
      float cx = x*step;
      if (pnd) cx += step/2.0;
      float cy = y*step/2*rt3;

      PImage temp = pg.get(round(cx), round(cy), round(step), round(step));
      float val = luminosityAverage(temp);
      val = level(val);
      //float dim = (1-val) * bitDim;

      Dot d = new Dot(offx+cx, offy+cy, 1-val);
      tmpDts.add(d);
      if (d.z>threshold) d.drilled = true;
    }
    pnd = !pnd;
    out.add(tmpDts);
  }
  return out;
}

//co-centric circles / spiral
ArrayList<ArrayList<Dot>> getPolarGrid(PGraphics pg, float step) {
  float cx = centerX;
  float cy = centerY;
  float dx = max(cx,outW-cx);
  float dy = max(cy,outH-cy);
  int numCirc = round(sqrt(sq(dx)+sq(dy))/step);

  ArrayList<ArrayList<Dot>> out = new ArrayList<ArrayList<Dot>>();
  
  for (int j=0; j<numCirc; j++) {
    float rad = j*step;
    int numRays = max(10,round(rad*TWO_PI/step));
    ArrayList<Dot> tmpDts = new ArrayList<Dot>();
    float a = 0;
    float mrg = step/2.0;
    
    for (int i=0; i<numRays+1; i++) {
      float x = cx + rad * cos(a);
      float y = cy + rad * sin(a);
      if (x>mrg && x<outW-mrg && y>mrg && y<outH-mrg) {
        PImage temp = pg.get(round(x-mrg), round(y-mrg), round(step), round(step));
        float val = luminosityAverage(temp);
        val = level(val);
        Dot d = new Dot(x,y,1-val);
        tmpDts.add(d);
        if (d.z>threshold) d.drilled = true;
      } else {
        if (tmpDts.size()>0) out.add(tmpDts);
        tmpDts = new ArrayList<Dot>();
      }
      a += TWO_PI/numRays;
    }
    
    if (tmpDts.size()>0) out.add(tmpDts);
  }

  return out;
}

//co-centric circles / spiral
ArrayList<ArrayList<Dot>> getSpiralGrid(PGraphics pg, float step) {
  float cx = centerX;
  float cy = centerY;
  float dx = max(cx,outW-cx);
  float dy = max(cy,outH-cy);
  int numCirc = round(sqrt(sq(dx)+sq(dy))/step);

  ArrayList<ArrayList<Dot>> out = new ArrayList<ArrayList<Dot>>();
  
  for (int j=0; j<numCirc; j++) {
    float rad = j*step;
    int numRays = max(10,round(rad*TWO_PI/step));
    ArrayList<Dot> tmpDts = new ArrayList<Dot>();
    float a = 0;
    float mrg = step/2.0;
    
    for (int i=0; i<numRays+1; i++) {
      float delta=float(i)/numRays * step;
      float x = cx + (rad+delta) * cos(a);
      float y = cy + (rad+delta) * sin(a);
      if (x>mrg && x<outW-mrg && y>mrg && y<outH-mrg) {
        PImage temp = pg.get(round(x-mrg), round(y-mrg), round(step), round(step));
        float val = luminosityAverage(temp);
        val = level(val);
        Dot d = new Dot(x,y,1-val);
        tmpDts.add(d);
        if (d.z>threshold) d.drilled = true;
      } else {
        if (tmpDts.size()>0) out.add(tmpDts);
        tmpDts = new ArrayList<Dot>();
      }
      a += TWO_PI/numRays;
    }
    
    if (tmpDts.size()>0) out.add(tmpDts);
  }

  return out;
}

PGraphics createPreview(ArrayList<ArrayList<Dot>> dots) {
  PGraphics out = createGraphics(outW, outH);

  out.beginDraw();
  out.background(255);
  out.noStroke();
  out.fill(0);

  //  for (ArrayList<Dot> li : dots) {
  for (int j=0; j<dots.size(); j++) {
    ArrayList<Dot> li = dots.get(j);
    for (int i=0; i<li.size(); i++) {
      Dot d = li.get(i);
      
      if (!d.drilled) continue;
      
      //draw dots anyway > round caps for lines
      if (root) out.ellipse(d.x, d.y, sqrt(d.z)*bitDim, sqrt(d.z)*bitDim);
      else out.ellipse(d.x, d.y, d.z*bitDim, d.z*bitDim);
      
      if (!con) {
        //special for drawing dots
      } 
      else {
        //draw lines
        if (i<(li.size()-1)) {
          Dot dn = li.get(i+1);

          float ang = HALF_PI+atan2(dn.y-d.y, dn.x-d.x);
          float r1 = sqrt(d.z)*bitDim/2.0;
          float r2 = sqrt(dn.z)*bitDim/2.0;

          out.beginShape();
          out.vertex(d.x+r1*cos(ang), d.y+r1*sin(ang));
          out.vertex(d.x-r1*cos(ang), d.y-r1*sin(ang));
          out.vertex(dn.x-r2*cos(ang), dn.y-r2*sin(ang));
          out.vertex(dn.x+r2*cos(ang), dn.y+r2*sin(ang));
          out.endShape(CLOSE);

        }
      }
    }
  }
  
  if (type==2) {
    out.stroke(255,0,0);
    out.strokeWeight(2);
    out.line(centerX-7,centerY,centerX+7,centerY);
    out.line(centerX,centerY-7,centerX,centerY+7);
  }
  out.endDraw();

  return out;
}
String currentFilename = "";
void loadPicture(String p) {
  String[] temp = split(p,"/");
  currentFilename = split(temp[temp.length-1],".")[0];
  print(currentFilename);
  loaded = false;
  pic = requestImage(p);
  //  pic = loadImage(p);
  //  while (pic.width<1) delay(100);
  //  calcResult();
}

String getFilename() {
  return outW+"x"+outH+"_"+bitDim+"mm_"+currentFilename;
}

void setDim(float d) {
  bitDim = d;
  calcResult();
}

void setWidth(float w) {
  outW = round(w);
  calcResult();
}

void setHeight(float h) {
  outH = round(h);
  calcResult();
}

void setRotation(float r) {
  imgrot = r;
  calcResult();
}

void setScale(float s) {
  sf = s;
  calcResult();
}

void setShowImg(boolean b) {
  showImg = b;
}

void setConnect(boolean b) {
  con = b;
  result = createPreview(myDots);
}

void setType(int t) {
  type = t;
  calcResult();
}

void setLow(float v) {
  low = v;
  calcResult();
}

void setHigh(float v) {
  high = v;
  calcResult();
}

void targetMode() {
  targetting = !targetting;
  if (targetting) cursor(CROSS);
  else cursor(ARROW);
}

void keyPressed() {
  
  switch (key) {
  case '3':
    setDim(3);
    break;
  case '6':
    setDim(6);
    break;
  case '9':
    setDim(9);
    break;
  case '2':
    setDim(12);
    break;
  case 'c':
    con = !con;
    result = createPreview(myDots);
    //calcResult();
    break;
  case 'r':
    root = !root;
    result = createPreview(myDots);
    //calcResult();
    break;
  case 't':
    type = (type+1)%3;
    calcResult();
    break;
  case 'k':
    cursor(CROSS);
    break;
  case 'a':
    cursor(ARROW);
    break;
  case 'g':
    targetting = !targetting;
    if (targetting) cursor(CROSS);
    else cursor(ARROW);
    break;
  case 'f':
    fit = !fit;
    break;
  case 'x':
    setRotation(45);
    break;
  case 'w':
    showImg = !showImg;
    break;
  }
  
}

void mouseClicked() {
  if (!targetting) return;
  
  cursor(CROSS);
  centerX = mouseX- width/2+outW/2;
  centerY = mouseY-height/2+outH/2;
  calcResult();
  cursor(ARROW);
  targetting = false;
}

