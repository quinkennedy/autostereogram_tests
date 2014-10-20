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


SimpleOpenNI  context;

int REPEAT = 200;
PShader depthFilter;
PImage depthBuffer;
PImage magicTexture;
int MAX_WIDTH = 1000;
int MAX_HEIGHT=800;
int MAX_IMG_WIDTH = MAX_WIDTH-REPEAT;
int BACKGROUND_DEPTH = 0;
int MAX_DEPTH = 20;
PImage texture;
float MIN_DEPTH_FILTER = 200;

void setup()
{
  context = new SimpleOpenNI(this);
   
  // mirror is by default enabled
  context.setMirror(false);
  
  // enable depthMap generation 
  if(context.enableDepth() == false)
  {
     println("Can't open the depthMap, maybe the camera is not connected!"); 
     exit();
     return;
  }
  
  // enable ir generation
  //context.enableRGB(640,480,30);
  //context.enableRGB(1280,1024,15);  
  if(context.enableRGB() == false)
  {
     println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!"); 
     exit();
     return;
  }
 
  size(context.depthWidth() + context.rgbWidth() + 10, context.depthHeight()*2+10);
 
  texture = genTexture().get(); 
}

PGraphics genTexture(){
  PGraphics pg = createGraphics(REPEAT, context.depthHeight());
  pg.beginDraw();
  pg.noStroke();
  int size = 2;
  
  for(int i = 0; i < pg.width; i++){
    for(int j = 0; j < pg.height; j++){
      //set a random color
      pg.fill(int((255*noise(i,j,0))/3)*3, 
        int((255*noise(i,j,1))/3)*3, 
        int((255*noise(i,j,2))/3)*3);
      //and a random size
      //int r = (int)random(5, 10);
      //and a random place
      int x = (int)random(-size, REPEAT-size);
      int y = (int)random(pg.height);
      for(int k = x; k < REPEAT+size; k += REPEAT){
        pg.ellipse(k, y, size, size);
      }
    }
  }

  pg.endDraw();
  return pg;
}

void draw()
{
  // update the cam
  context.update();
  
  background(0,100,200);
  
  PImage myDepth = context.depthImage();
  //myDepth = threshold(MIN_DEPTH_FILTER, context.depthImage()).get();
  // draw depthImageMap
  //image(context.depthImage(),0,context.depthHeight()+10);
  image(myDepth, 0, context.depthHeight()+10);
  
  // draw irImageMap
  image(context.rgbImage(),context.depthWidth() + 10,context.depthHeight()+10);
  
  //draw autostereogram
  drawAutostereogram(texture, myDepth, this.g, 0, 0);
  
  text(MIN_DEPTH_FILTER, width - 100, 100);
}

void drawAutostereogram(PImage pattern, PImage depth, PGraphics canvas, int x, int y){
  
  canvas.noStroke();
  canvas.fill(0);
  canvas.ellipse(x+(depth.width-REPEAT)/2, y+5, 5, 5);
  canvas.ellipse(x+(depth.width+REPEAT)/2, y+5, 5, 5);
  canvas.image(pattern,x,y+10);
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
      canvas.set(x+i+REPEAT, y+j+10, canvas.get(x+i+currDepth, y+j+10));
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

void mouseMoved(){
  MIN_DEPTH_FILTER = mouseX;
}
