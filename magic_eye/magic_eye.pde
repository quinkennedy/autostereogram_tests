float rotation = 0;
int REPEAT = 200;
PShader depthFilter;
PImage depthBuffer;
PImage magicTexture;
int MAX_WIDTH = 1000;
int MAX_HEIGHT=800;
int MAX_IMG_WIDTH = MAX_WIDTH-REPEAT;
int BACKGROUND_DEPTH = 0;
int MAX_DEPTH = 20;

void setup(){
  loadImage();
  //setupTestImage();
  size(depthBuffer.width+REPEAT,depthBuffer.height+10, P3D);
  //depthFilter = loadShader(PShader.FLAT, "DepthShader.glsl");
  //shader(depthFilter);
  genTexture();
  noLoop();
}

void loadImage(){
  String a = "01481w20835C838C835D838C83m8B9797A320-208FE93F32081x.jpg";
  depthBuffer = loadImage(a);
  if (depthBuffer.width > MAX_IMG_WIDTH){
    depthBuffer.resize(MAX_IMG_WIDTH, 0);
  }
  if (depthBuffer.height > MAX_HEIGHT){
    depthBuffer.resize(0, MAX_HEIGHT);
  }
}

void setupTestImage(){
  PGraphics pg = createGraphics(MAX_IMG_WIDTH, MAX_HEIGHT);
  pg.beginDraw();
  for(int i = 0; i < pg.height; i++){
    pg.stroke(map(sin(i*.03), -1, 1, 0, 255));//map(i, 0, pg.height, 0, 255));
    //pg.fill(i);
    pg.line(0,i,pg.width,i);
  }
  pg.endDraw();
  depthBuffer = pg.get();
}
/*
void draw(){
  //image(depthBuffer,0,0);
  //if(true)
  //return;
  background(0);
  fill(255);
  rotation += .002;
  if (rotation >= PI*2){
    rotation -= PI*2;
  }
  pushMatrix();
  translate(width/2, height/2);
  rotateX(rotation);
  rotateY(rotation*3);
  rotateZ(rotation*5);
  scale(100);
  box(1);
  popMatrix();
}*/

void draw(){
  //image(depthBuffer, REPEAT, 0);
  background(255);
  noStroke();
  fill(0);
  ellipse((width-REPEAT)/2, 5, 5, 5);
  ellipse((width+REPEAT)/2, 5, 5, 5);
  translate(0, 10);
  image(magicTexture,0,0);
  for(int i = 0; i < depthBuffer.width; i++){
    for(int j = 0; j < depthBuffer.height; j++){
      int currDepth = 0;
      float depthValue = red(depthBuffer.get(i,j));
      if (depthValue > 0){
        currDepth += BACKGROUND_DEPTH;
        currDepth += ceil(map(depthValue, 0, 255, 0, MAX_DEPTH));
      }
      //println(currDepth);
      set(i+REPEAT, j+10, get(i+currDepth, j+10));
      //set(i+REPEAT, j, 255);
    }
  }
}

//
void genTexture(){
  PGraphics pg = createGraphics(REPEAT, height);
  pg.beginDraw();
  pg.noStroke();
  int size = 2;
  
  for(int i = 0; i < REPEAT; i++){
    for(int j = 0; j < height; j++){
      //set a random color
      pg.fill(int((255*noise(i,j,0))/3)*3, 
        int((255*noise(i,j,1))/3)*3, 
        int((255*noise(i,j,2))/3)*3);
      //and a random size
      //int r = (int)random(5, 10);
      //and a random place
      int x = (int)random(-size, REPEAT-size);
      int y = (int)random(height);
      for(int k = x; k < REPEAT+size; k += REPEAT){
        pg.ellipse(k, y, size, size);
      }
    }
  }

  pg.endDraw();
  magicTexture = pg.get();
}
/*
final int REPEAT = 200;
noSmooth();
background(255);
noStroke();
//stroke(255);
for(int i = 0; i < REPEAT; i++){
  for(int j = 0; j < height; j++){
    //set a random color
    fill(255*noise(i,j,0), 255*noise(i,j,1), 255*noise(i,j,2));
    //and a random size
    int r = (int)random(5, 10);
    //and a random place
    int x = (int)random(height);
    int y = (int)random(height);
    for(int k = x; k < width; k += REPEAT){
      ellipse(k, y, r, r);
    }
  }
}
//copy(0, 0, width/2, height, width/2, 0, width/2, height); 

//have some square in the middle shifted by some pixels
int rectWidth = 200;
int rectHeight = 200;
int squareStartX = (width-rectWidth)/2;
int squareStartY = (height-rectHeight)/2;
int offset = 20;
for(int i = REPEAT; i < width; i+=REPEAT){
  if (squareStartX < i && rectWidth > 0){
    int diff = i - squareStartX;
    int copyWidth = rectWidth;//min(diff, rectWidth);
    //copy the overlapped section over one repeat width
    copy(squareStartX, squareStartY, copyWidth, rectHeight,
        i + REPEAT - diff - offset, squareStartY, copyWidth, rectHeight);
    //and update the rectangle info to disregard the piece
    // that we just took care of
    squareStartX += diff;
    rectWidth -= diff;
  }
}

//could do this as a shader, pass in a pattern & grayscale image, BAM! autostereography!
*/
