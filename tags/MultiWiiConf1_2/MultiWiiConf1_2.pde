import processing.serial.*; // serial library
import controlP5.*; // controlP5 library

Serial g_serial;
ControlP5 controlP5; // create the handler to allow for controlP5 items
Textlabel txtlblWhichcom; // text label displaying which comm port is being used
ListBox commListbox; // list of available comm ports
Textlabel version;

cGraph g_graph;
int windowsX    = 800;
int windowsY    = 500;
int xGraph      = 10;
int yGraph      = 300;
int xObj        = 700;
int yObj        = 450;
int xParam      = 180;
int yParam      = 15;
int xRC         = 650;
int yRC         = 15;
int xMot        = 480;
int yMot        = 30;

int xNunchuk    = 475;
int yNunchuk    = 185;
int xLevel      = 475;
int yLevel      = 210;

int xSens       = xParam + 90;
int ySens       = yParam + 110;

boolean axGraph =true,ayGraph=true,azGraph=true,gxGraph=true,gyGraph=true,gzGraph=true;

int multiType;  // 1 for tricopter, 2 for quad+, 3 for quadX

cDataArray accPITCH   = new cDataArray(100);
cDataArray accROLL    = new cDataArray(100);
cDataArray accYAW     = new cDataArray(100);
cDataArray gyroPITCH  = new cDataArray(100);
cDataArray gyroROLL   = new cDataArray(100);
cDataArray gyroYAW    = new cDataArray(100);

Numberbox confP_ROLL;
Numberbox confP_PITCH;
Numberbox confP_YAW;
Numberbox confI_ROLL;
Numberbox confI_PITCH;
Numberbox confI_YAW;
Numberbox confD_ROLL;
Numberbox confD_PITCH;
Numberbox confD_YAW;
Numberbox confRC_RATE;
Numberbox confRC_EXPO;
Numberbox confACC_STRENGTH;

Slider rcStickThrottleSlider;
Slider rcStickRollSlider;
Slider rcStickPitchSlider;
Slider rcStickYawSlider;
Slider rcStickAUX1Slider;

Slider motRightSlider;
Slider motLeftSlider;
Slider motRearSlider;
Slider motFRONTLSlider; //for QUAD X
Slider yawSlider; //for TRI
Slider servoFRONTSlider; //for BI
Slider servoREARSlider; //for BI

Slider axSlider;
Slider aySlider;
Slider azSlider;
Slider gxSlider;
Slider gySlider;
Slider gzSlider;

Button buttonREAD;
Button buttonWRITE;
Button buttonSTART;
Button buttonSTOP;

Button buttonNunchuk;
Button buttonLevel;

color yellow_ = color(200, 200, 20);
color green_ = color(30, 120, 30);
color red_ = color(120, 30, 30);
boolean graphEnable = false;
boolean readEnable = false;
boolean writeEnable = false;

float gx,gy,gz = 0;
float ax,ay,az = 0;
float angx,angy = 0;
float r;
int init_com = 0;
int graph_on = 0;

float motRight = 1000,motLeft = 1000,motRear = 1000,servo=1500;
float rcThrottle = 1500,rcRoll = 1500,rcPitch = 1500,rcYaw =1500,rcAUX1=1500;
int nunchukPresent;
int levelMode;

float time1;
float time2;
int cycleTime;

void setup() {
  size(windowsX,windowsY);
  frameRate(20); 
  controlP5 = new ControlP5(this); // initialize the GUI controls
  controlP5.setControlFont(createFont("Arial bold",12));
  background(0);
 
  g_graph  = new cGraph(120,10, 480, 200);
  // make a listbox and populate it with the available comm ports
  commListbox = controlP5.addListBox("portComList",5,65,80,180); //addListBox(name,x,y,width,height)
  commListbox.captionLabel().toUpperCase(true);
  commListbox.captionLabel().set("PORT COM");
  commListbox.setColorBackground(red_);
  for(int i=0;i<Serial.list().length;i++) {
    commListbox.addItem("port: "+Serial.list()[i],i); // addItem(name,value)
  }

  // text label for which comm port selected
  txtlblWhichcom = controlP5.addTextlabel("txtlblWhichcom","No Port Selected",5,42); // textlabel(name,text,x,y)
  
  buttonREAD = controlP5.addButton("READ",1,xParam-55,yParam+100,40,19); // buton(name,value,x,y,width,height)
  buttonREAD.setColorBackground(red_);
  
  buttonWRITE = controlP5.addButton("WRITE",1,xParam+235,yParam+100,40,19); // buton(name,value,x,y,width,height)
  buttonWRITE.setColorBackground(red_);
  
  buttonSTART = controlP5.addButton("START",1,xGraph+110,yGraph-30,40,19); // buton(name,value,x,y,width,height)
  buttonSTART.setColorBackground(red_);
  
  buttonSTOP = controlP5.addButton("STOP",1,xGraph+160,yGraph-30,40,19); // buton(name,value,x,y,width,height)
  buttonSTOP.setColorBackground(red_);

  buttonNunchuk = controlP5.addButton("---",1,xNunchuk,yNunchuk,150,19); // buton(name,value,x,y,width,height)
  buttonNunchuk.setColorBackground(red_);

  buttonLevel = controlP5.addButton("----",1,xLevel,yLevel,150,19); // buton(name,value,x,y,width,height)
  buttonLevel.setColorBackground(red_);

  controlP5.addToggle("ACC_ROLL",true,xGraph-7,yGraph,20,15);
  controlP5.addToggle("ACC_PITCH",true,xGraph-7,yGraph+30,20,15);
  controlP5.addToggle("ACC_Z",true,xGraph-7,yGraph+60,20,15);
  controlP5.addToggle("GYRO_ROLL",true,xGraph-7,yGraph+90,20,15);
  controlP5.addToggle("GYRO_PITCH",true,xGraph-7,yGraph+120,20,15);
  controlP5.addToggle("GYRO_YAW",true,xGraph-7,yGraph+150,20,15);
  
  confP_ROLL = controlP5.addNumberbox("P_ROLL",0,xParam,yParam,40,14);
  confP_ROLL.setDecimalPrecision(1);
  confP_ROLL.setMultiplier(0.1);
  confP_ROLL.setDirection(Controller.HORIZONTAL);
  confP_ROLL.setMin(0);
  confP_ROLL.setMax(20);
  confP_ROLL.setColorBackground(red_);

  confI_ROLL = controlP5.addNumberbox("I_ROLL",0,xParam+75,yParam,40,14);
  confI_ROLL.setDecimalPrecision(3);
  confI_ROLL.setMultiplier(0.001);
  confI_ROLL.setDirection(Controller.HORIZONTAL);
  confI_ROLL.setMin(0);
  confI_ROLL.setMax(0.250);
  confI_ROLL.setColorBackground(red_);
  
  confD_ROLL = controlP5.addNumberbox("D_ROLL",0,xParam+150,yParam,40,14);
  confD_ROLL.setDecimalPrecision(1);
  confD_ROLL.setMultiplier(1);
  confD_ROLL.setDirection(Controller.HORIZONTAL);
  confD_ROLL.setMin(-40);
  confD_ROLL.setMax(0);
  confD_ROLL.setColorBackground(red_);

  confP_PITCH = controlP5.addNumberbox("P_PITCH",0,xParam,yParam+35,40,14);
  confP_PITCH.setDecimalPrecision(1);
  confP_PITCH.setMultiplier(0.1);
  confP_PITCH.setDirection(Controller.HORIZONTAL);
  confP_PITCH.setMin(0);
  confP_PITCH.setMax(20);
  confP_PITCH.setColorBackground(red_);

  confI_PITCH = controlP5.addNumberbox("I_PITCH",0,xParam+75,yParam+35,40,14);
  confI_PITCH.setDecimalPrecision(3);
  confI_PITCH.setMultiplier(0.001);
  confI_PITCH.setDirection(Controller.HORIZONTAL);
  confI_PITCH.setMin(0);
  confI_PITCH.setMax(0.250);
  confI_PITCH.setColorBackground(red_);

  confD_PITCH = controlP5.addNumberbox("D_PITCH",0,xParam+150,yParam+35,40,14);
  confD_PITCH.setDecimalPrecision(1);
  confD_PITCH.setMultiplier(1);
  confD_PITCH.setDirection(Controller.HORIZONTAL);
  confD_PITCH.setMin(-40);
  confD_PITCH.setMax(0);
  confD_PITCH.setColorBackground(red_);
  
  confP_YAW = controlP5.addNumberbox("P_YAW",0,xParam,yParam+70,40,14);
  confP_YAW.setDecimalPrecision(1);
  confP_YAW.setMultiplier(0.1);
  confP_YAW.setDirection(Controller.HORIZONTAL);
  confP_YAW.setMin(0);
  confP_YAW.setMax(20);
  confP_YAW.setColorBackground(red_);

  confI_YAW = controlP5.addNumberbox("I_YAW",0,xParam+75,yParam+70,40,14);
  confI_YAW.setDecimalPrecision(3);
  confI_YAW.setMultiplier(0.001);
  confI_YAW.setDirection(Controller.HORIZONTAL);
  confI_YAW.setMin(0);
  confI_YAW.setMax(0.250);
  confI_YAW.setColorBackground(red_);

  confD_YAW = controlP5.addNumberbox("D_YAW",0,xParam+150,yParam+70,40,14);
  confD_YAW.setDecimalPrecision(1);
  confD_YAW.setMultiplier(1);
  confD_YAW.setDirection(Controller.HORIZONTAL);
  confD_YAW.setMin(-40);
  confD_YAW.setMax(0);
  confD_YAW.setColorBackground(red_);

  confRC_RATE = controlP5.addNumberbox("RC RATE",0,xParam+0,yParam+130,40,14);
  confRC_RATE.setDecimalPrecision(2);
  confRC_RATE.setMultiplier(0.01);
  confRC_RATE.setDirection(Controller.HORIZONTAL);
  confRC_RATE.setMin(0);
  confRC_RATE.setMax(1);
  confRC_RATE.setColorBackground(red_);

  confRC_EXPO = controlP5.addNumberbox("RC EXPO",0,xParam+0,yParam+165,40,14);
  confRC_EXPO.setDecimalPrecision(2);
  confRC_EXPO.setMultiplier(0.01);
  confRC_EXPO.setDirection(Controller.HORIZONTAL);
  confRC_EXPO.setMin(0);
  confRC_EXPO.setMax(1);
  confRC_EXPO.setColorBackground(red_);

  confACC_STRENGTH = controlP5.addNumberbox("AUTOLEVEL STRENGTH",0,xParam+0,yParam+210,40,14);
  confACC_STRENGTH.setDecimalPrecision(1);
  confACC_STRENGTH.setMultiplier(0.1);
  confACC_STRENGTH.setDirection(Controller.HORIZONTAL);
  confACC_STRENGTH.setMin(0);
  confACC_STRENGTH.setMax(10);
  confACC_STRENGTH.setColorBackground(red_);

  rcStickThrottleSlider = controlP5.addSlider("Throttle",900,2100,1500,xRC,yRC,10,100);
  rcStickThrottleSlider.setDecimalPrecision(0);

  rcStickPitchSlider = controlP5.addSlider("Pitch",900,2100,1500,xRC+80,yRC,10,100);
  rcStickPitchSlider.setDecimalPrecision(0);
  rcStickRollSlider = controlP5.addSlider("Roll",900,2100,1500,xRC,yRC+125,100,10);
  rcStickRollSlider.setDecimalPrecision(0);
  rcStickYawSlider = controlP5.addSlider("Yaw",900,2100,1500,xRC,yRC+150,100,10);
  rcStickYawSlider.setDecimalPrecision(0);
  rcStickAUX1Slider = controlP5.addSlider("AUX1",900,2100,1500,xRC,yRC+175,100,10);
  rcStickAUX1Slider.setDecimalPrecision(0);


  motLeftSlider  = controlP5.addSlider("LEFT",1000,2000,1500,xMot,yMot-15,10,100);
  motLeftSlider.setDecimalPrecision(0);
  motLeftSlider.hide();

  motRearSlider  = controlP5.addSlider("REAR",1000,2000,1500,xMot+50,yMot+15,10,100);
  motRearSlider.setDecimalPrecision(0);
  motRearSlider.hide();
  
  motRightSlider  = controlP5.addSlider("RIGHT",1000,2000,1500,xMot+100,yMot-15,10,100);
  motRightSlider.setDecimalPrecision(0);
  motRightSlider.hide();
  
  yawSlider  = controlP5.addSlider("Servo",1000,2000,1500,xMot,yMot+135,100,10);
  yawSlider.setDecimalPrecision(0);
  yawSlider.hide();
  
  motFRONTLSlider = controlP5.addSlider("FRONTL",1000,2000,1500,xMot,yMot-15,10,100);
  motFRONTLSlider.setDecimalPrecision(0);
  motFRONTLSlider.hide();
  
  servoFRONTSlider = controlP5.addSlider("SERVOF",1000,2000,1500,xMot,yMot-15,100,10);
  servoFRONTSlider.setDecimalPrecision(0);
  servoFRONTSlider.hide();

  servoREARSlider = controlP5.addSlider("SERVOR",1000,2000,1500,xMot,yMot-15,100,10);
  servoREARSlider.setDecimalPrecision(0);
  servoREARSlider.hide();


  axSlider  = controlP5.addSlider("ACCX",-400,+400,0,xGraph+60,yGraph+10,50,10);axSlider.setDecimalPrecision(0);
  aySlider  = controlP5.addSlider("ACCY",-111400,+111400,0,xGraph+60,yGraph+40,50,10);aySlider.setDecimalPrecision(0);
  azSlider  = controlP5.addSlider("ACCZ",-400,+400,0,xGraph+60,yGraph+70,50,10);azSlider.setDecimalPrecision(0);
  gxSlider  = controlP5.addSlider("GYRX",-500,+500,0,xGraph+60,yGraph+100,50,10);gxSlider.setDecimalPrecision(0);
  gySlider  = controlP5.addSlider("GYRY",-500,+500,0,xGraph+60,yGraph+130,50,10);gySlider.setDecimalPrecision(0);
  gzSlider  = controlP5.addSlider("GYRZ",-500,+500,0,xGraph+60,yGraph+160,50,10);gzSlider.setDecimalPrecision(0);
}

void draw() {
  int i;
  float val;
  float inter;
  float a;
  float b;
  float sina;
  float sinb;
  float cosa;
  float cosb;

  background(80);
  
  textFont(createFont("Arial bold",12), 15);
  text("MultiWii conf", 0, 16);
  text("v1.2", 0, 32);

  textFont(createFont("Arial bold",12), 15); 
  text("Cycle Time:", 230, 285);
  text(cycleTime, 330, 285);

  time1=millis();
  if (init_com==1) {
    while (g_serial.available() >0)
      processSerialData();
    if ((time1-time2)>100 && graph_on==1) {
      g_serial.write('A');
      time2=time1;
    }
  }
  controlP5.draw();
  
  axSlider.setValue(ax);
  aySlider.setValue(ay);
  azSlider.setValue(az);
  gxSlider.setValue(gx);
  gySlider.setValue(gy);
  gzSlider.setValue(gz);

  motRightSlider.setValue(motRight);
  motLeftSlider.setValue(motLeft);
  motRearSlider.setValue(motRear);
  yawSlider.setValue(servo);
  motFRONTLSlider.setValue(servo);
  servoFRONTSlider.setValue(motRight);
  servoREARSlider.setValue(motLeft);
  
  rcStickThrottleSlider.setValue(rcThrottle);
  rcStickRollSlider.setValue(rcRoll);
  rcStickPitchSlider.setValue(rcPitch);
  rcStickYawSlider.setValue(rcYaw);
  rcStickAUX1Slider.setValue(rcAUX1);


  stroke(255); 
  a=angx*PI/180;
  b=angy*PI/180;
  sina = sin(a);
  sinb = sin(b);
  cosa = cos(a);
  cosb = cos(b);

  float size = 30.0;

  if (multiType == 1) { //TRI
    ellipse(xObj-size*cosa, yObj-size*cosb, size*cosa *(1+sina/3) *(1-sinb/3) , size*cosb *(1+sina/3) *(1-sinb/3) );
    ellipse(xObj+size*cosa, yObj-size*cosb, size*cosa *(1-sina/3) *(1-sinb/3) , size*cosb *(1-sina/3) *(1-sinb/3) );
    ellipse(xObj,  yObj+size*cosb,          size*cosa *(1+sinb/3), size*cosb *(1+sinb/3));
    line(xObj-size*cosa,yObj-size*cosb, xObj,yObj);
    line(xObj+size*cosa,yObj-size*cosb, xObj,yObj);  
    line(xObj,yObj+size*cosb, xObj,yObj);
    textFont(createFont("Arial bold",12), 15);
    text("TRICOPTER", xObj-200, yObj-190);

    motLeftSlider.setPosition(xMot,yMot-15);
    motLeftSlider.setHeight(100);
    motLeftSlider.setCaptionLabel("LEFT");
    motLeftSlider.show();
  
    motRearSlider.setPosition(xMot+50,yMot+15);
    motRearSlider.setHeight(100);
    motRearSlider.setCaptionLabel("REAR");
    motRearSlider.show();

    motRightSlider.setPosition(xMot+100,yMot-15);
    motRightSlider.setHeight(100);
    motRightSlider.setCaptionLabel("RIGHT");
    motRightSlider.show();

    yawSlider.setPosition(xMot,yMot+135);
    yawSlider.setCaptionLabel("SERVO");
    yawSlider.show(); 

    motFRONTLSlider.hide();
    servoFRONTSlider.hide();
    servoREARSlider.hide();

  } else if (multiType == 2) { //QUAD+
    ellipse(xObj,  yObj-size*cosb,   size*cosa *(1-sinb/3), size*cosb *(1-sinb/3));
    ellipse(xObj,  yObj+size*cosb,   size*cosa *(1+sinb/3), size*cosb *(1+sinb/3));
    ellipse(xObj+size*cosa, yObj,    size*cosa *(1-sina/3) , size*cosb *(1-sina/3) );
    ellipse(xObj-size*cosa, yObj,    size*cosa *(1+sina/3) , size*cosb *(1+sina/3) );
    line(xObj-size*cosa,yObj, xObj,yObj);
    line(xObj+size*cosa,yObj, xObj,yObj);  
    line(xObj,yObj+size*cosb, xObj,yObj);  
    line(xObj,yObj-size*cosb, xObj,yObj);
    textFont(createFont("Arial bold",12), 15);
    text("QUADRICOPTER +", xObj-220, yObj-190);
    
    motLeftSlider.setPosition(xMot,yMot+35);
    motLeftSlider.setHeight(60);
    motLeftSlider.setCaptionLabel("LEFT");
    motLeftSlider.show();
  
    motRearSlider.setPosition(xMot+50,yMot+75);
    motRearSlider.setHeight(60);
    motRearSlider.setCaptionLabel("REAR");
    motRearSlider.show();

    motRightSlider.setPosition(xMot+100,yMot+35);
    motRightSlider.setHeight(60);
    motRightSlider.setCaptionLabel("RIGHT");
    motRightSlider.show();

    motFRONTLSlider.setPosition(xMot+50,yMot-15);
    motFRONTLSlider.setHeight(60);
    motFRONTLSlider.setCaptionLabel("FRONT");
    motFRONTLSlider.show();
    
    yawSlider.hide();
    servoFRONTSlider.hide();
    servoREARSlider.hide();
    
  } else if (multiType == 3) { //QUAD X
    ellipse(xObj-size*cosa,  yObj-size*cosb, size*cosa *(1+sina/3)*(1-sinb/3), size*cosb *(1+sina/3)*(1-sinb/3));
    ellipse(xObj+size*cosa,  yObj-size*cosb, size*cosa *(1-sina/3)*(1-sinb/3), size*cosb *(1-sina/3)*(1-sinb/3));
    ellipse(xObj-size*cosa,  yObj+size*cosb, size*cosa *(1+sina/3)*(1+sinb/3), size*cosb *(1+sina/3)*(1+sinb/3));
    ellipse(xObj+size*cosa,  yObj+size*cosb, size*cosa *(1-sina/3)*(1+sinb/3), size*cosb *(1-sina/3)*(1+sinb/3));
    line(xObj-size*cosa,yObj-size*cosb, xObj,yObj);
    line(xObj+size*cosa,yObj-size*cosb, xObj,yObj);
    line(xObj-size*cosa,yObj+size*cosb, xObj,yObj);
    line(xObj+size*cosa,yObj+size*cosb, xObj,yObj);
    textFont(createFont("Arial bold",12), 15);
    text("QUADRICOPTER X", xObj-220, yObj-190);
  
    motLeftSlider.setPosition(xMot+10,yMot+75);
    motLeftSlider.setHeight(60);
    motLeftSlider.setCaptionLabel("REAR_L");
    motLeftSlider.show();
  
    motRearSlider.setPosition(xMot+90,yMot+75);
    motRearSlider.setHeight(60);
    motRearSlider.setCaptionLabel("REAR_R");
    motRearSlider.show();

    motRightSlider.setPosition(xMot+90,yMot-15);
    motRightSlider.setHeight(60);
    motRightSlider.setCaptionLabel("FRONT_R");
    motRightSlider.show();

    motFRONTLSlider.setPosition(xMot+10,yMot-15);
    motFRONTLSlider.setHeight(60);
    motFRONTLSlider.setCaptionLabel("FRONT_L");
    motFRONTLSlider.show(); 
    
    yawSlider.hide();
    servoFRONTSlider.hide();
    servoREARSlider.hide();
  } else if (multiType == 4) { //BI
    ellipse(xObj,  yObj-size*cosb,   size*cosa *(1-sinb/3), size*cosb *(1-sinb/3));
    ellipse(xObj,  yObj+size*cosb,   size*cosa *(1+sinb/3), size*cosb *(1+sinb/3));
    line(xObj,yObj+size*cosb, xObj,yObj);  
    line(xObj,yObj-size*cosb, xObj,yObj);
    textFont(createFont("Arial bold",12), 15);
    text("BICOPTER", xObj-200, yObj-190);
   
    motRearSlider.setPosition(xMot+50,yMot+73);
    motRearSlider.setHeight(55);
    motRearSlider.setCaptionLabel("");
    motRearSlider.show();

    servoREARSlider.setPosition(xMot,yMot+135);
    servoREARSlider.setCaptionLabel("SERVO");
    servoREARSlider.show();


    motFRONTLSlider.setPosition(xMot+50,yMot+2);
    motFRONTLSlider.setHeight(55);
    motFRONTLSlider.setCaptionLabel("MOT");
    motFRONTLSlider.show();
    
    
    servoFRONTSlider.setPosition(xMot,yMot-15);
    servoFRONTSlider.setCaptionLabel("SERVO");
    servoFRONTSlider.show();

    motLeftSlider.hide();
    motRightSlider.hide();
    yawSlider.hide();
  }


  size = 30.0;

  line(xObj+30+size*cosa,yObj-165+size*sina, xObj+30-size*cosa,yObj-165-size*sina);
  line(xObj+30,yObj-165,xObj+30+10*sina,yObj-165-10*cosa);
  line(xObj+30+size*cosb,yObj-100+size*sinb, xObj+30-size*cosb,yObj-100-size*sinb); 
  
  line(xObj+30+size*cosb,yObj-100+size*sinb, xObj+30+(size-10)*cos(b+PI/10) ,yObj-100+(size-10)*sin(b+PI/10));  
  line(xObj+30+size*cosb,yObj-100+size*sinb, xObj+30+(size-10)*cos(b-PI/10) ,yObj-100+(size-10)*sin(b-PI/10));  
  
  textFont(createFont("Arial bold",12), 15);
  text("ROLL", xObj-60, yObj-160);
  text("PITCH", xObj-60, yObj-95);


  strokeWeight(1);
  fill(255, 255, 255);
  g_graph.drawGraphBox();
  
  strokeWeight(1.5);
  stroke(255, 0, 0);
  if (axGraph) g_graph.drawLine(accROLL, -500, +500);
  stroke(0, 255, 0);
  if (ayGraph) g_graph.drawLine(accPITCH, -500, +500);
  stroke(0, 0, 255);
  if (azGraph) g_graph.drawLine(accYAW, -500, +500);
  stroke(200, 200, 0);
  if (gxGraph) g_graph.drawLine(gyroROLL, -300, +300);
  stroke(0, 255, 255);
  if (gyGraph) g_graph.drawLine(gyroPITCH, -300, +300);
  stroke(255, 0, 255);
  if (gzGraph) g_graph.drawLine(gyroYAW, -300, +300);

  strokeWeight(2);
  stroke(255, 0, 0);     line(xGraph+25, yGraph+10, xGraph+60, yGraph+10);
  stroke(0, 255, 0);     line(xGraph+25, yGraph+40, xGraph+60, yGraph+40);
  stroke(0, 0, 255);     line(xGraph+25, yGraph+70, xGraph+60, yGraph+70);
  stroke(200, 200, 0);   line(xGraph+25, yGraph+100, xGraph+60, yGraph+100);
  stroke(0, 255, 255);   line(xGraph+25, yGraph+130, xGraph+60, yGraph+130);
  stroke(255, 0, 255);   line(xGraph+25, yGraph+160, xGraph+60, yGraph+160);
  fill(0, 0, 0);

  strokeWeight(3);
  stroke(0, 0, 0);
  rectMode(CORNERS);
  rect(xMot-5,yMot-20, xMot+145, yMot+150);
  rect(xRC-5,yRC-5, xRC+185, yRC+195);
  rect(xParam-60,yParam-5, xParam+280, yParam+245);
  
  stroke(255);
  a=confRC_RATE.value();
  b=confRC_EXPO.value();
  strokeWeight(1);
  line(xSens+50,ySens,xSens+50,ySens+100);
  line(xSens,ySens+50,xSens+100,ySens+50);
  strokeWeight(3);
  stroke(30,120,30);
  for(i=0;i<100;i++) {
    inter = 10*(i-50);
    val = a*inter*(1-b+inter*inter*b/250000);
    point(xSens+i,ySens+(50-val/10));
  }
  
}

void ACC_ROLL(boolean theFlag) {axGraph = theFlag;}
void ACC_PITCH(boolean theFlag) {ayGraph = theFlag;}
void ACC_Z(boolean theFlag) {azGraph = theFlag;}
void GYRO_ROLL(boolean theFlag) {gxGraph = theFlag;}
void GYRO_PITCH(boolean theFlag) {gyGraph = theFlag;}
void GYRO_YAW(boolean theFlag) {gzGraph = theFlag;}

// print the name of the control being triggered (for debugging) and see if it was a Listbox event
public void controlEvent(ControlEvent theEvent) {
  // ListBox is if type ControlGroup, you need to check the Event with if (theEvent.isGroup())to avoid an error message from controlP5
  if (theEvent.isGroup()) {
    // an event from a group
    if (theEvent.name()=="portComList") {
      InitSerial(theEvent.group().value()); // initialize the serial port selected
      println("got portComList"+"   value = "+theEvent.group().value()); // for debugging
    }
  }
  else {
    //println(theEvent.controller().name()); // for debugging
  }
}

public void START(int theValue) {
  if(graphEnable == false) {return;}
  graph_on=1;
  readEnable = true;
  buttonREAD.setColorBackground(green_);
}

public void STOP(int theValue) {
  graph_on=0;
}

int byteP_ROLL,byteI_ROLL,byteD_ROLL,
     byteP_PITCH,byteI_PITCH,byteD_PITCH,
     byteP_YAW,byteI_YAW,byteD_YAW,
     byteRC_RATE,byteRC_EXPO,byteACC_STRENGTH;


public void READ(int theValue) {
  if(readEnable == false) {return;}
  confP_ROLL.setValue(byteP_ROLL/10.0);
  confI_ROLL.setValue(byteI_ROLL/1000.0);
  confD_ROLL.setValue(-byteD_ROLL);
  confP_PITCH.setValue(byteP_PITCH/10.0);
  confI_PITCH.setValue(byteI_PITCH/1000.0);
  confD_PITCH.setValue(-byteD_PITCH);
  confP_YAW.setValue(byteP_YAW/10.0);
  confI_YAW.setValue(byteI_YAW/1000.0);
  confD_YAW.setValue(-byteD_YAW);
  confRC_RATE.setValue(byteRC_RATE/100.0);
  confRC_EXPO.setValue(byteRC_EXPO/100.0);
  confACC_STRENGTH.setValue(byteACC_STRENGTH/10.0);

  buttonWRITE.setColorBackground(green_);
  confP_ROLL.setColorBackground(green_);
  confI_ROLL.setColorBackground(green_);
  confD_ROLL.setColorBackground(green_);
  confP_PITCH.setColorBackground(green_);
  confI_PITCH.setColorBackground(green_);
  confD_PITCH.setColorBackground(green_);
  confP_YAW.setColorBackground(green_);
  confI_YAW.setColorBackground(green_);
  confD_YAW.setColorBackground(green_);
  confRC_RATE.setColorBackground(green_);
  confRC_EXPO.setColorBackground(green_);
  confACC_STRENGTH.setColorBackground(green_);
  writeEnable = true;
}

public void WRITE(int theValue) {
  if(writeEnable == false) {return;}

  byteP_ROLL = (round(confP_ROLL.value()*10));
  byteI_ROLL = (round(confI_ROLL.value()*1000));
  byteD_ROLL = (round(-confD_ROLL.value()));
  byteP_PITCH = (round(confP_PITCH.value()*10));
  byteI_PITCH = (round(confI_PITCH.value()*1000));
  byteD_PITCH = (round(-confD_PITCH.value()));
  byteP_YAW = (round(confP_YAW.value()*10));
  byteI_YAW = (round(confI_YAW.value()*1000));
  byteD_YAW = (round(-confD_YAW.value()));
  byteRC_RATE = (round(confRC_RATE.value()*100));
  byteRC_EXPO = (round(confRC_EXPO.value()*100));
  byteACC_STRENGTH = (round(confACC_STRENGTH.value()*10));

  int[] s = new int[32];
   s[0] = 'C';
   s[1] =  byteP_ROLL;
   s[2] =  byteI_ROLL;
   s[3] =  byteD_ROLL;
   s[4] =  byteP_PITCH;
   s[5] =  byteI_PITCH;
   s[6] =  byteD_PITCH;
   s[7] =  byteP_YAW;
   s[8] =  byteI_YAW;
   s[9] =  byteD_YAW;
   s[10] = byteRC_RATE;
   s[11] = byteRC_EXPO;
   s[12] = byteACC_STRENGTH;
   for(int i =0;i<13;i++)    g_serial.write(char(s[i]));
}


// initialize the serial port selected in the listBox
void InitSerial(float portValue) {
  println("initializing serial " + int(portValue) + " in serial.list()"); // for debugging
  String portPos = Serial.list()[int(portValue)]; // grab the name of the serial port
  txtlblWhichcom.setValue("COM Initialized = " + portPos);
  g_serial = new Serial(this, portPos, 115200); // initialize the port
  // read bytes into a buffer until you get a linefeed (ASCII 10):
  g_serial.bufferUntil('\n');
  println("done init serial");
  init_com=1;
  buttonSTART.setColorBackground(green_);
  buttonSTOP.setColorBackground(green_);
  commListbox.setColorBackground(green_);
  graphEnable = true;
}

void processSerialData() {
  byte[] inBuf = new byte[128];
  if (g_serial.read() == 'A') {

    while (g_serial.available() <51) {}
    g_serial.readBytes(inBuf);
    ax = (inBuf[1]<<8) + (inBuf[0]&0xff);
    ay = (inBuf[3]<<8) + (inBuf[2]&0xff);
    az = (inBuf[5]<<8) + (inBuf[4]&0xff);
    gx = (inBuf[7]<<8) + (inBuf[6]&0xff);
    gy = (inBuf[9]<< 8) + (inBuf[8]&0xff);
    gz = (inBuf[11]<<8) + (inBuf[10]&0xff);
    motRight = (inBuf[13]<<8) + (inBuf[12]&0xff);
    motLeft = (inBuf[15]<<8) + (inBuf[14]&0xff);
    motRear = (inBuf[17]<<8) + (inBuf[16]&0xff);
    servo =   (inBuf[19]<<8) + (inBuf[18]&0xff);
    rcThrottle = (inBuf[21]<<8) + (inBuf[20]&0xff);
    rcRoll = (inBuf[23]<<8) + (inBuf[22]&0xff);
    rcPitch = (inBuf[25]<<8) + (inBuf[24]&0xff);
    rcYaw = (inBuf[27]<<8) + (inBuf[26]&0xff);
    rcAUX1 = (inBuf[29]<<8) + (inBuf[28]&0xff);
    levelMode = inBuf[30];
    nunchukPresent = inBuf[31];
    cycleTime = (inBuf[33]<<8) + (inBuf[32]&0xff);
    angx = (inBuf[35]<<8) + (inBuf[34]&0xff);
    angy = (inBuf[37]<<8) + (inBuf[36]&0xff);
    multiType = inBuf[38];
    
    byteP_ROLL = inBuf[39]&0xff;
    byteI_ROLL = inBuf[40]&0xff;
    byteD_ROLL = inBuf[41]&0xff;
    byteP_PITCH = inBuf[42]&0xff;
    byteI_PITCH = inBuf[43]&0xff;
    byteD_PITCH = inBuf[44]&0xff;
    byteP_YAW = inBuf[45]&0xff;
    byteI_YAW = inBuf[46]&0xff;
    byteD_YAW = inBuf[47]&0xff;
    byteRC_RATE = inBuf[48]&0xff;
    byteRC_EXPO = inBuf[49]&0xff;
    byteACC_STRENGTH = inBuf[50]&0xff;

    if (levelMode>0) {
      buttonLevel.setCaptionLabel("AutoLevel Enable");
      buttonLevel.setColorBackground(green_);
    } else {
      buttonLevel.setCaptionLabel("AutoLevel Disable");
      buttonLevel.setColorBackground(red_);
    }
    if (nunchukPresent>0) {
      buttonNunchuk.setCaptionLabel("Nunchuk Connected");
      buttonNunchuk.setColorBackground(green_);
    } else {
      buttonNunchuk.setCaptionLabel("Nunchuk Absent");
      buttonNunchuk.setColorBackground(red_);
    }

    accROLL.addVal(ax);
    accPITCH.addVal(ay);
    accYAW.addVal(az);
    gyroROLL.addVal(gx);
    gyroPITCH.addVal(gy);
    gyroYAW.addVal(gz);
  }
}


//********************************************************
//********************************************************
//********************************************************

class cDataArray
{
  float[] m_data;
  int m_maxSize;
  int m_startIndex = 0;
  int m_endIndex = 0;
  int m_curSize;
  
  cDataArray(int maxSize){
    m_maxSize = maxSize;
    m_data = new float[maxSize];
  }
  void addVal(float val) {
    m_data[m_endIndex] = val;
    m_endIndex = (m_endIndex+1)%m_maxSize;
    if (m_curSize == m_maxSize) {
      m_startIndex = (m_startIndex+1)%m_maxSize;
    } else {
      m_curSize++;
    }
  }
  float getVal(int index) {return m_data[(m_startIndex+index)%m_maxSize];}
  int getCurSize(){return m_curSize;}
  int getMaxSize() {return m_maxSize;}
}

// This class takes the data and helps graph it
class cGraph {
  float m_gWidth, m_gHeight;
  float m_gLeft, m_gBottom, m_gRight, m_gTop;
  
  cGraph(float x, float y, float w, float h) {
    m_gWidth     = w;
    m_gHeight    = h;
    m_gLeft      = x;
    m_gBottom    = windowsY - y;
    m_gRight     = x + w;
    m_gTop       = windowsY - y - h;
  }
  
  void drawGraphBox() {
    stroke(0, 0, 0);
    rectMode(CORNERS);
    rect(m_gLeft, m_gBottom, m_gRight, m_gTop);
  }
  
  void drawLine(cDataArray data, float minRange, float maxRange) {
    float graphMultX = m_gWidth/data.getMaxSize();
    float graphMultY = m_gHeight/(maxRange-minRange);
    
    for(int i=0; i<data.getCurSize()-1; ++i) {
      float x0 = i*graphMultX+m_gLeft;
      float y0 = m_gBottom-((data.getVal(i)-minRange)*graphMultY);
      float x1 = (i+1)*graphMultX+m_gLeft;
      float y1 = m_gBottom-((data.getVal(i+1)-minRange)*graphMultY);
      line(x0, y0, x1, y1);
    }
  }
} 

