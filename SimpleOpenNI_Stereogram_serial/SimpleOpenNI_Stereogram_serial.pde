/* --------------------------------------------------------------------------
 * SimpleOpenNI DepthImage Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / zhdk / http://iad.zhdk.ch/
 * date:  02/16/2011 (m/d/y)
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;
import processing.serial.*;


SimpleOpenNI  context;
Serial myPort;

int pixelMult = 2;
int REPEAT = 200;
int S_HEIGHT = 384;
PImage depthBuffer;
PImage magicTexture;
PGraphics receiptImage;
PGraphics tempDepth;

int BACKGROUND_DEPTH = 20;
int MAX_DEPTH = 10;
float MIN_DEPTH_FILTER = 100;

int PRINT_SECTION = 255;
int currPrintIndex = 0;
boolean printReceipt = false;
boolean printerReady = true;

void setup()
{
  setupCamera();
  myPort = new Serial(this, Serial.list()[0], 9600);
 
  magicTexture = genTexture();
  depthBuffer = createImage(S_HEIGHT*4/3, S_HEIGHT, RGB);
  tempDepth = createGraphics(depthBuffer.width, depthBuffer.height);
  size(REPEAT+depthBuffer.width, depthBuffer.height);
  receiptImage = createGraphics(height, width);
}

void setupCamera(){
  context = new SimpleOpenNI(this);
   
  // mirror is by default enabled
  context.setMirror(true);
  
  // enable depthMap generation 
  if(context.enableDepth() == false)
  {
     println("Can't open the depthMap, maybe the camera is not connected!"); 
     exit();
     return;
  }
  /*
  // enable ir generation
  //context.enableRGB(640,480,30);
  //context.enableRGB(1280,1024,15);  
  if(context.enableRGB() == false)
  {
     println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!"); 
     exit();
     return;
  }*/
}

PImage genTexture(){
  PImage temp = createImage(REPEAT/pixelMult, S_HEIGHT/pixelMult, RGB);
  
  for(int i = 0; i < temp.width; i++){
    for(int j = 0; j < temp.height; j++){
      //float randomNum = noise(i,j);
      float randomNum = random(1);
      temp.pixels[i+j*temp.width] = (randomNum >= .5 ? Integer.MAX_VALUE : 0);
    }
  }
  PImage img = createImage(REPEAT, S_HEIGHT, RGB);
  img.copy(temp, 0, 0, temp.width, temp.height, 0, 0, img.width, img.height);
  return img;
}

void draw()
{
  if (printReceipt){
    handlePrinting();
    return;
  }
  // update the cam
  context.update();
  tempDepth.copy(context.depthImage(), 0, 0, context.depthWidth(), context.depthHeight(), 0, 0, tempDepth.width, tempDepth.height);
  tempDepth.tint(255,0);
  depthBuffer.blend(tempDepth, 0, 0, tempDepth.width, tempDepth.height, 0, 0, depthBuffer.width, depthBuffer.height, BLEND);
  
  //draw autostereogram
  drawAutostereogram(magicTexture, depthBuffer, this.g, 0, 0, true);
  
  //text(MIN_DEPTH_FILTER, width - 100, 100);
}

void updateReceiptImage(){
  receiptImage.beginDraw();
  receiptImage.pushMatrix();
  receiptImage.translate(receiptImage.width, 0);
  receiptImage.rotate(PI/2);
  receiptImage.image(g.get(), 0, 0);
  receiptImage.popMatrix();
  receiptImage.endDraw();
  receiptImage.loadPixels();
}

void handlePrinting(){
  if (!printerReady){
    return;
  }
  if (currPrintIndex == 0){
    updateReceiptImage();
  }
  int imageBits = S_HEIGHT*PRINT_SECTION;
  byte[] bytes = new byte[imageBits/8];
  
  //for each pixel, convert it to a bitmap
  byte currByte = 0;
  int i = 0;
  int stopPrintIndex = currPrintIndex + imageBits;
  println(currPrintIndex + " -> " + stopPrintIndex + " : " + (stopPrintIndex - currPrintIndex));
  for(; currPrintIndex < stopPrintIndex; currPrintIndex++){
    currByte <<= 1;
    if (currPrintIndex < receiptImage.pixels.length){
      currByte |= (red(receiptImage.pixels[currPrintIndex]) > 120 ? 0 : 1);
    }
    if (currPrintIndex%8 == 7){
      //we have filled a character, so lets store it and reset
      bytes[i++] = currByte;
      currByte = 0;
    } else if (currPrintIndex == stopPrintIndex - 1){
      //this is the last iteration of the loop, so we should save the current character
      bytes[i++] = currByte;
    }
  }
  
  myPort.write(bytes);
  if (currPrintIndex >= receiptImage.pixels.length){
    currPrintIndex = 0;
    printReceipt = false;
    println("done printing full image");
  } else {
    println("done printing image section");
  }
  println(currPrintIndex + " -> " + stopPrintIndex + " : " + (stopPrintIndex - currPrintIndex));
  
  printerReady = false;
}

void drawAutostereogram(PImage pattern, PImage depth, PGraphics canvas, int x, int y, boolean drawDots){
  
  int yOffset = 0;
  if (drawDots){
    canvas.noStroke();
    canvas.fill(0);
    canvas.ellipse(x+(depth.width-REPEAT)/2, y+5, 5, 5);
    canvas.ellipse(x+(depth.width+REPEAT)/2, y+5, 5, 5);
    yOffset += 10;
  }
  canvas.image(pattern,x,y+yOffset);
  for(int i = 0; i < depth.width; i++){
    for(int j = 0; j < depth.height; j++){
      int currDepth = 0;
      float depthValue = red(depth.get(i,j));
      if (depthValue < MIN_DEPTH_FILTER){
        depthValue = 0;
      } else if (depthValue > 0){
        currDepth += BACKGROUND_DEPTH;
        currDepth += ceil(map(depthValue, 0, 255, 0, MAX_DEPTH));
      }
      //println(currDepth);
      canvas.set(x+i+REPEAT, y+j+yOffset, canvas.get(x+i+currDepth, y+j+yOffset));
      //set(i+REPEAT, j, 255);
    }
  }
}

PGraphics thresholdGraphic;

PGraphics threshold(float limit, PImage dst){
  if (thresholdGraphic == null){
    thresholdGraphic = createGraphics(dst.width, dst.height);
  }
  thresholdGraphic.image(dst,0,0);
  thresholdGraphic.filter(THRESHOLD, limit);
  thresholdGraphic.blend(dst, 0, 0, dst.width, dst.height, 0, 0, dst.width, dst.height, DARKEST);
  
  return thresholdGraphic;
}

void keyPressed(){
  switch(key){
    case ' '://directly send the screen to the printer
      printReceipt = true;
      break;
    case 's'://save the screen to a file
      updateReceiptImage();
      receiptImage.save("frameshot.bmp");
      break;
    case 'a'://send a byte to try and jog the printer
      myPort.write((byte)0);
      println("sent");
      break;
  }
}

void mouseMoved(){
  MIN_DEPTH_FILTER = mouseX;
}

void serialEvent(Serial myPort) {
  if (myPort.read() == 1){
    printerReady = true;
    println("printer ready");
  }
}
