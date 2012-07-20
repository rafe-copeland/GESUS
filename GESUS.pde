// Welcome to GESUS
// Geospatial Earth Simulation Using Sound (SuperCollider)


import processing.opengl.*;
import codeanticode.glgraphics.*;
import javax.media.opengl.*;
import tomc.gpx.*;
import java.util.Calendar;
import java.util.TimeZone;
import java.lang.Math;
import java.io.File;

/////////////////////////////////////// OPENGL VARIABLES /////////////////////////////////////////

PGraphicsOpenGL pgl;
GL gl;

///////////////////////////////////////////////////////////////////////////////////////////////////


Equator equator;
private Planet earth;
GPX planetGeography;
private XMLElement godDirectory;

int mInterval; //length of rolling time-period to display data in minutes. Must be a factor of 60.
public float cameraX;
public float cameraY;
public float cameraZ;

PFont inconsolata;


//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////



// SETUP FUNCTION ////////////////////////////////////////////////////////////////////////////////

void setup() {

	size(screen.width,screen.height-50,GLConstants.GLGRAPHICS); //MUST be set to GLConstants.GLGRAPHICS
	GLGraphics renderer = (GLGraphics) g;
	renderer.beginGL();
	setOpenGLParameters(); //MUST run first to avoid problems
	
	inconsolata = loadFont("Inconsolata-16.vlw");
	textFont(inconsolata,16);
	
	background(0);
	
	text("GESUS is loading...",50,height-50);
	
	mInterval = 10; //must be a factor of 60

	planetGeography = new GPX(this);
	planetGeography.parse("continents.gpx");
	earth = new Planet(this);
	equator = new Equator(earth.pRadius, mInterval);
	equator.setTimes();

	getDataPaths();

	cameraX = width/2.0;
	cameraY = height/2.0;
	cameraZ = (height/2.0) / tan(PI*60/360.0);

	camera(cameraX, cameraY, cameraZ, width/2.0, height/2.0, 0, 0, 1, 0);
	renderer.endGL();

}

//////////////////////////////////////////////////////////////////////////////////////////////////



// DRAW FUNCTION /////////////////////////////////////////////////////////////////////////////////

void draw() {
	
	//If I put everything inside this GLGraphics object then stuff goes nuts
	//The other one that kinda works is in the Planet class, in the function conductGODInputs()
	//GLGraphics renderer = (GLGraphics) g;
	//renderer.beginGL();
	//Dunno why.
	
	background(0);
	drawTicker();
	equator.setTimes();
	equator.getDay();
	pushMatrix();
	translate(earth.pCentrePoint.x,earth.pCentrePoint.y,earth.pCentrePoint.z);
	rotateZ(PI);
	earth.plot();
	popMatrix();
	
	//
	//renderer.endGL();
	//
	
}

//////////////////////////////////////////////////////////////////////////////////////////////////



// OPENGL INITIALISATION /////////////////////////////////////////////////////////////////////////

void setOpenGLParameters()
{
	GLGraphics renderer = (GLGraphics) g;
	renderer.beginGL();
	hint(DISABLE_OPENGL_2X_SMOOTH);
	hint(ENABLE_OPENGL_4X_SMOOTH);
	renderer.setDepthMask(false);
	renderer.setBlendMode(ADD);
	renderer.endGL();
}

//////////////////////////////////////////////////////////////////////////////////////////////////



void getDataPaths() {
	godDirectory = new XMLElement(this,"godDirectory.xml");
	int godCount = godDirectory.getChildCount();
	for(int i=0;i<godCount;i++) {
		XMLElement godLayer = godDirectory.getChild(i);
		GOD GODLayer = new GOD(this, godLayer);
		earth.put(GODLayer);
	}
}

void drawTicker() {
	String tickerText = "framerate: "+str(frameRate)+"\n"+"UTC time:  "+nf(equator.hourInt,2)+":"+nf(equator.minuteInt,2)+":"+nf(equator.secondInt,2)+" "+str(equator.yearInt)+"-"+nf(equator.monthInt,2)+"-"+nf(equator.dayInt,2);
	noStroke();
	fill(255);
	text(tickerText, 50,height-50);
}
