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

