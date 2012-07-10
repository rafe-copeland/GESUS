class Planet {
	private float pRadius;
	private int pAspect;
	private int pLongitudeLineIncrement;
	private int pLatitudeLineIncrement;
	private int pDepth;
	private int pDarksideVisibility;
	private String pGeographyFile;
	private PVector pCentrePoint;
	private float pSolarDeclination;
	private ArrayList godInputs;

	Planet() {  
		pRadius = 1.8*int(min(height, width)*0.4);
		pAspect = 0;
		pLongitudeLineIncrement = 10;
		pLatitudeLineIncrement = 10;
		pDepth = 1000;
		pCentrePoint = new PVector(width/2, height/2, -pDepth);
		pDarksideVisibility = 175; //set the opacity of the darkside of the Earth (0-255)
		pGeographyFile = "continents.gpx"; //GPX file containing the earth's geography
		godInputs = new ArrayList();
	}

	void plot() {
		pushMatrix();
		pDeclinate(equator.solarDeclination(equator.getDay())); //Tilts the planet to the solar declination
		pRotate(equator.getRotation(equator.getJulianDayNumber()));
		drawMeridians();
		drawGeography();
		conductGODInputs();
		popMatrix(); //pops rotation matrix
		popMatrix(); //pops declination matrix
		drawNight("DISABLE"); //use "PLANE" or "ELLIPSE", or "DISABLE"
		drawMask("PLANE"); //use "PLANE" or "ELLIPSE", or "DISABLE"
	}

	void pRotate(double pMiddayLongitude) {
		pushMatrix();
		rotateY(-HALF_PI); //resets orbit so midday is over 0 degrees longitude (greenwich)

		rotateY((float) pMiddayLongitude);
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
		for(int i=0;i<godInputs.size();i++){
			GOD godInstance = (GOD) godInputs.get(i);
			godInstance.drawData();
		}
	}

}

