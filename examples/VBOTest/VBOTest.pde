import processing.opengl.*;
import javax.media.opengl.*;
import java.nio.FloatBuffer ;
import javax.media.opengl.glu.*;
import com.sun.opengl.util.*;
import traer.physics.*;
FloatBuffer fb;   // float buffer for x,y particle position
FloatBuffer fbColor; // float buffer for RGBA color
FloatBuffer fbLines; // float buffer for RGBA color
FloatBuffer fbLineColor; // float buffer for RGBA color
final int NUM_PARTICLES=50000;  // tons of particles"
Particle[] p;    // array containing all particles
Particle mouse;  // magnet
ParticleSystem physics;
void setup()
{
	size( 800, 600,OPENGL );
	frameRate( 60 );
	hint(ENABLE_OPENGL_4X_SMOOTH);
	noStroke();
	noCursor();
	noFill();
	physics = new ParticleSystem();
	mouse = physics.makeParticle();
	mouse.makeFixed();
	physics.setIntegrator( ParticleSystem.MODIFIED_EULER );
	physics.setDrag( 0.01 );
	p=new Particle[NUM_PARTICLES]; // init the p array
	for(int i=0; i<p.length; i++) {
		p[i]=physics.makeParticle( 1.0, random( 0, width ), random( 0, height ), 0 ); // make particle
		physics.makeAttraction( mouse,  p[i], 10000, 100 );                            // make attraction
	}
	fb = BufferUtil.newFloatBuffer(NUM_PARTICLES*2);          // init pos float buffer X Y
	fbColor = BufferUtil.newFloatBuffer(NUM_PARTICLES * 4);    // init color float buffer R G B A
	fbLines = BufferUtil.newFloatBuffer(NUM_PARTICLES * 4);    // init lines float buffer x1, y1, x2, y2
	fbLineColor = BufferUtil.newFloatBuffer(NUM_PARTICLES * 8);    // init lines float buffer RGBA for x1,y1 & RGBA for x2,y2
	PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;        
	GL gl = pgl.beginGL();
	for (int i = 0; i < NUM_PARTICLES; i++) {
		//  r,g,b,a
		fbColor.put(random(0,1));
		fbColor.put(random(.5,1));
		fbColor.put(0);
		fbColor.put(.4);
	}
	fbColor.rewind();
	for (int i = 0; i < NUM_PARTICLES; i++) {
		// Fade line from Aqua to Purple, Constant Semi-Transparent Alpha
		//  r,g,b,a  v1 (x1,y1)
		fbLineColor.put(0);
		fbLineColor.put(1);   //Aqua
		fbLineColor.put(.5);
		fbLineColor.put(.4);
		//  r,g,b,a   v2 (x2,y2)
		fbLineColor.put(.5);
		fbLineColor.put(0);  //Purple
		fbLineColor.put(1);  
		fbLineColor.put(.4);
	}
	fbLineColor.rewind();
	gl.glEnableClientState(GL.GL_VERTEX_ARRAY);        // particles
	gl.glVertexPointer(2, GL.GL_FLOAT, 0, fb);
	gl.glEnableClientState(GL.GL_COLOR_ARRAY);          //  particles' color
	gl.glColorPointer(4, GL.GL_FLOAT, 0, fbColor);
	gl.glColorPointer(4, GL.GL_FLOAT, 0, fbLineColor);
	gl.glEnableClientState(GL.GL_VERTEX_ARRAY);        // line
	gl.glVertexPointer(2, GL.GL_FLOAT, 0, fbLines);
	gl.glPointSize(2);                                // particle size
	pgl.endGL();
}
void draw()
{
	frame.setTitle(str(frameRate));
	mouse.position().set( mouseX, mouseY, 0 );      // set the magnet position
	physics.tick();                            // advance physic simulation
	background( 0 );
	stroke( 255 );
	ellipse( mouse.position().x(), mouse.position().y(), 35, 35 );    // draw the magnet
	int lineCounter=0;
	for(int i=0; i<p.length; i++) {
		fb.put(p[i].position().x());          // put the x,y particle position into the buffer
		fb.put(p[i].position().y());
		if(i!=0) {
			float d=dist(p[i].position().x(), p[i].position().y(),p[i-1].position().x(), p[i-1].position().y());
			if(d<100) {
				fbLines.put(p[i].position().x());      
				fbLines.put(p[i].position().y());
				fbLines.put(p[i-1].position().x());          // put the x1, y1, x2, y2 particles position into the line buffer
				fbLines.put(p[i-1].position().y());
				lineCounter++;
			}
		}
		handleBoundaryCollisions( p[i] );    // perform the collision
	}
	fb.rewind();
	fbLines.rewind();
	PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
	GL gl = pgl.beginGL();
	gl.glColorPointer(4, GL.GL_FLOAT, 0, fbColor);                       
	gl.glVertexPointer(2,GL.GL_FLOAT,0,fb);                // draw the particles
	gl.glDrawArrays(GL.GL_POINTS,0,NUM_PARTICLES);
	gl.glColorPointer(4, GL.GL_FLOAT, 0, fbLineColor);
	gl.glVertexPointer(2,GL.GL_FLOAT,0,fbLines);                // draw the lines
	gl.glDrawArrays(GL.GL_LINES,0,lineCounter);                  // end when lineCounter in reached
	//  gl.glDisableClientState(GL.GL_VERTEX_ARRAY);
	pgl.endGL();
}
// really basic collision strategy:
// sides of the window are walls
// if it hits a wall pull it outside the wall and flip the direction of the velocity
// the collisions aren't perfect so we take them down a notch too
void handleBoundaryCollisions( Particle p )
{
	if ( p.position().x() < 0 || p.position().x() > width )
	p.velocity().set( -0.999*p.velocity().x(), p.velocity().y(), 0 );
	if ( p.position().y() < 0 || p.position().y() > height )
	p.velocity().set( p.velocity().x(), -0.999*p.velocity().y(), 0 );
	p.position().set( constrain( p.position().x(), 0, width ), constrain( p.position().y(), 0, height ), 0 );
}