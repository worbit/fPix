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
  case 4:
  	myDots = getHamiltonPath(tmp, stp);
  	break;
  }

  result = createPreview(myDots);
  return true;
}
