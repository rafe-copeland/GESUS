class Planet {
	PApplet parent; //reference to GESUS
	private float pRadius;
	private int pAspect;
	private int pLongitudeLineIncrement;
	private int pLatitudeLineIncrement;
	private int pDepth;
	private int pSphereOpacity;
	private int pDarksideVisibility;
	private float SINCOS_PRECISION = 0.5;
	private int SINCOS_LENGTH = int(360.0 / SINCOS_PRECISION);
	private String pGeographyFile;
	private PVector pCentrePoint;
	private float pSolarDeclination;
	private ArrayList godInputs;
	private GLModel sphere;
	private ArrayList vertices;
	private GLModel geography;
	private ArrayList geoVertices;
	private int sphereDetail;

	Planet(PApplet p) {  
		parent = p;
		
		//Planet settings
		pRadius = 1.8*int(min(height, width)*0.4);
		pAspect = 0;
		pLongitudeLineIncrement = 10;
		pLatitudeLineIncrement = 10;
		pDepth = 1000;
		sphereDetail = 35;
		pCentrePoint = new PVector(width/2, height/2, -pDepth);
		pSphereOpacity = 75; //set the opacity of the darkside of the Earth (0-255)
		pGeographyFile = "continents.gpx"; //GPX file containing the earth's geography
		
		//Planet initialisation
		godInputs = new ArrayList();
		prepSphere();
		prepGeography();
	}

	void plot() {
		pDeclinate(equator.solarDeclination(equator.getDay())); //Tilts the planet to the solar declination
		pRotate(equator.getRotation(equator.getJulianDayNumber()));
		drawMeridians();
		plotGL();
		//drawGeography();
		popMatrix(); //pops rotation matrix
		popMatrix(); //pops declination matrix
		drawNight("DISABLE"); //use "PLANE" or "ELLIPSE", or "DISABLE"
		drawMask("PLANE"); //use "PLANE" or "ELLIPSE", or "DISABLE"
	}

	void pRotate(double pMiddayLongitude) {
		pushMatrix();
		rotateY(-HALF_PI); //resets orbit so midday is over 0 degrees longitude (UTC)
		rotateY((float) pMiddayLongitude);
	}
	
	void prepSphere() {
		calculateSphereCoords();
		sphere = new GLModel(parent, vertices.size(), TRIANGLE_STRIP, GLModel.STATIC);
		sphere.updateVertices(vertices);
		sphere.initColors();
		sphere.setColors(0,pSphereOpacity);
	}
	
	void prepGeography() {
		calculateGeographyCoords();
		geography = new GLModel(parent, geoVertices.size(), LINES, GLModel.STATIC);
		geography.updateVertices(geoVertices);
		geography.initColors();
		geography.setColors(255);
	}

	void drawMeridians() {
		ellipseMode(RADIUS);
		noFill();
		strokeWeight(1);
		stroke(0,255,0);
		line(0, pRadius, 0, 0, pRadius+100, 0);
		line(0, -pRadius, 0, 0, -pRadius-100, 0);
		stroke(60,180,60,50);
		for (int i=0;i<360;i=i+pLongitudeLineIncrement) {
			pushMatrix();
			rotateY(radians(i));
			arc(0, 0, pRadius, pRadius, radians(97.0), TWO_PI-radians(95.0));
			popMatrix();
		}
		for (int i=0;i<180;i=i+pLatitudeLineIncrement/2) {
			float latitudeRadius = pRadius*sin(radians(i));
			float latitudeY = pRadius*cos(radians(i));
			pushMatrix();
			translate(0, latitudeY, 0);
			rotateX(HALF_PI);
			ellipse(0, 0, latitudeRadius, latitudeRadius);
			popMatrix();
		}
	}

	void drawMask(String method) {

		//This function draws a 2D shape to mask the far side of the planet

		float dSpherePointToCamera = cameraZ+pDepth;
		float maskRadius = sqrt(sq(dSpherePointToCamera)-sq(pRadius))*(pRadius/dSpherePointToCamera);
		float dSpherePointToMaskCentreZ = sqrt(sq(pRadius)-sq(maskRadius));
		ellipseMode(RADIUS);
		noStroke();
		fill(0, pDarksideVisibility);
		pushMatrix();
		translate(0, 0, dSpherePointToMaskCentreZ);
		if (method=="PLANE") {
			rectMode(RADIUS);
			rect(0, 0, width*2, height*2);
			
		}
		else if (method=="ELLIPSE") {
			ellipse(0, 0, maskRadius+2, maskRadius+2);
		}
		else if (method=="DISABLE") {

		}
		else {
			println("drawMask() method must be either PLANE or ELLIPSE, or DISABLE");
			exit();
		}
		popMatrix();
	}

	void drawNight(String method) {

		//This functions draws a 2D shape to darken the parts of the planet which are experiencing night
		//This is approximated as the half of the planet facing away from the camera

		float dSpherePointToCamera = cameraZ+pDepth;
		float maskRadius = sqrt(sq(dSpherePointToCamera)-sq(pRadius))*(pRadius/dSpherePointToCamera);
		fill(0,150);
		noStroke();
		if (method=="PLANE") {
			rectMode(RADIUS);
			rect(0,0,width*2,height*2);
		}
		else if (method=="ELLIPSE") {
			ellipse(0,0,maskRadius+1,maskRadius+1);
		}
		else if (method=="DISABLE") {

		}
		else {
			println("drawNight() method must be either PLANE or ELLIPSE");
			exit();
		}
	}

	void drawGeography() {
		stroke(255,255);
		strokeWeight(1);
		//    fill(255,50);
		for (int i = 0; i < planetGeography.getTrackCount(); i++) {
			GPXTrack trk = planetGeography.getTrack(i);
			for (int j = 0; j < trk.size(); j++) {
				GPXTrackSeg trkseg = trk.getTrackSeg(j);
				beginShape();
				for (int k = 0; k < trkseg.size(); k++) {
					GPXPoint pt = trkseg.getPoint(k);

					makeGeographyVertex(pt.lat,pt.lon);
				}
				endShape();
			}
		}
	}
	
	void calculateGeographyCoords() {
		geoVertices = new ArrayList();
		for (int i = 0; i < planetGeography.getTrackCount(); i++) {
			GPXTrack trk = planetGeography.getTrack(i);
			for (int j = 0; j < trk.size(); j++) {
				GPXTrackSeg trkseg = trk.getTrackSeg(j);
				for (int k = 0; k < trkseg.size(); k++) {
					GPXPoint pt = trkseg.getPoint(k);
					addGeographyVertex(pt);
					if(k!=0 && k!=trkseg.size()-1) {
						addGeographyVertex(pt); //duplicate interior points
					}
				}
			}
		}
	}
	
	void addGeographyVertex(GPXPoint p) {
		GPXPoint pt = p;
		float lat = radians((float)pt.lat);
		float lng = radians((float)pt.lon);
		float calc1 = (pRadius)*cos(lat);
		float pX = calc1 * cos(lng);
		float pY = (pRadius) * sin(lat);
		float pZ = calc1 * sin(lng);
		
		PVector vert = new PVector(pX,pY,pZ);
		geoVertices.add(vert);
	}
	
	void makeGeographyVertex(double latitude, double longitude) {

		float lat = (float)latitude;
		float lng = (float)longitude;
		lat = radians(lat);
		lng = radians(lng);
		float calc1 = (pRadius+1)*cos(lat);

		float pX = calc1 * cos(lng);
		float pY = (pRadius+1) * sin(lat);
		float pZ = calc1 * sin(lng);

		vertex(pX,pY,pZ);
	}


	void pDeclinate(double declinationAngle) {
		pushMatrix();
		rotateX((float) declinationAngle);
	}

	void put(GOD input) {
		if(input==null) {
			println("data input is empty");
		}
		else {
			godInputs.add(input);
		}
	}
	
	void conductGODInputs() {
		
		//iterate through all GODs and draw their datapoint GLModels
		
		for(int i=0;i<godInputs.size();i++){
			GOD godInstance = (GOD) godInputs.get(i);
			godInstance.drawData();
		}		
	}
	
	void plotGL() {
		
		//Reset matrix ready for GL drawing
		popMatrix(); //pops rotation matrix
		popMatrix(); //pops declination matrix
		popMatrix(); //pops to-centre matrix
		
		GLGraphics renderer = (GLGraphics) g;
		renderer.beginGL();
		renderer.setDepthMask(false);
		
		
		//Construct matrix for GL drawing
		pushMatrix();
		translate(earth.pCentrePoint.x,earth.pCentrePoint.y,earth.pCentrePoint.z);
		rotateZ(PI);
		pDeclinate(equator.solarDeclination(equator.getDay()));
		pRotate(equator.getRotation(equator.getJulianDayNumber()));
		
		//Draw for GL
		geography.render();
		sphere.render();
		conductGODInputs();

		renderer.setDepthMask(true);
		renderer.endGL();
		
		//Revert matrix for further non-GL drawing
		pushMatrix();
		translate(earth.pCentrePoint.x,earth.pCentrePoint.y,earth.pCentrePoint.z);
		rotateZ(PI);
		pDeclinate(equator.solarDeclination(equator.getDay()));
		pRotate(equator.getRotation(equator.getJulianDayNumber()));
	}
	
	void calculateSphereCoords()
	{
		float[] cx, cz, sphereX, sphereY, sphereZ;
		float sinLUT[];
		float cosLUT[];
		float delta, angle_step, angle;
		int vertCount, currVert;
		float r;
		int v1, v11, v2, voff;

		sinLUT = new float[SINCOS_LENGTH];
		cosLUT = new float[SINCOS_LENGTH];

		for (int i = 0; i < SINCOS_LENGTH; i++) 
		{
			sinLUT[i] = (float) Math.sin(i * DEG_TO_RAD * SINCOS_PRECISION);
			cosLUT[i] = (float) Math.cos(i * DEG_TO_RAD * SINCOS_PRECISION);
		}  

		delta = float(SINCOS_LENGTH / sphereDetail);
		cx = new float[sphereDetail];
		cz = new float[sphereDetail];

		// Calc unit circle in XZ plane
		for (int i = 0; i < sphereDetail; i++) 
		{
			cx[i] = -cosLUT[(int) (i * delta) % SINCOS_LENGTH];
			cz[i] = sinLUT[(int) (i * delta) % SINCOS_LENGTH];
		}

		// Computing vertexlist vertexlist starts at south pole
		vertCount = sphereDetail * (sphereDetail - 1) + 2;
		currVert = 0;

		// Re-init arrays to store vertices
		sphereX = new float[vertCount];
		sphereY = new float[vertCount];
		sphereZ = new float[vertCount];
		angle_step = (SINCOS_LENGTH * 0.5f) / sphereDetail;
		angle = angle_step;

		// Step along Y axis
		for (int i = 1; i < sphereDetail; i++) 
		{
			float curradius = sinLUT[(int) angle % SINCOS_LENGTH];
			float currY = -cosLUT[(int) angle % SINCOS_LENGTH];
			for (int j = 0; j < sphereDetail; j++) 
			{
				sphereX[currVert] = cx[j] * curradius;
				sphereY[currVert] = currY;
				sphereZ[currVert++] = cz[j] * curradius;
			}
			angle += angle_step;
		}

		vertices = new ArrayList();

		r = pRadius;

		// Add the southern cap    

		for (int i = 0; i < sphereDetail; i++) 
		{
			addVertex(0.0, -r, 0.0);
			addVertex(sphereX[i] * r, sphereY[i] * r, sphereZ[i] * r);        
		}
		addVertex(0.0, -r, 0.0);
		addVertex(sphereX[0] * r, sphereY[0] * r, sphereZ[0] * r);

		// Middle rings
		voff = 0;
		for (int i = 2; i < sphereDetail; i++) 
		{
			v1 = v11 = voff;
			voff += sphereDetail;
			v2 = voff;   
			for (int j = 0; j < sphereDetail; j++) 
			{
				addVertex(sphereX[v1] * r, sphereY[v1] * r, sphereZ[v1++] * r);
				addVertex(sphereX[v2] * r, sphereY[v2] * r, sphereZ[v2++] * r);
			}

			// Close each ring
			v1 = v11;
			v2 = voff;
			addVertex(sphereX[v1] * r, sphereY[v1] * r, sphereZ[v1] * r);
			addVertex(sphereX[v2] * r, sphereY[v2] * r, sphereZ[v2] * r);
		}

		// Add the northern cap
		for (int i = 0; i < sphereDetail; i++) 
		{
			v2 = voff + i;

			addVertex(sphereX[v2] * r, sphereY[v2] * r, sphereZ[v2] * r);
			addVertex(0, r, 0);

		}
		addVertex(sphereX[voff] * r, sphereY[voff] * r, sphereZ[voff] * r);
	}

	void addVertex(float x, float y, float z)
	{
		PVector vert = new PVector(x, y, z);
		vertices.add(vert);
	}

}

