//The Equator solves equations. Each calculation is its own function.
//It has nothing to do with the equator of a planet.

static class Equator {

	float pRadius;
	int yearInt;
	int monthInt;  
	int dayInt;
	int hourInt;
	int minuteInt;
	int secondInt;
	int millisecondInt;
	int mInterval;
	private int sortKey;
	double solarDeclination;
	Calendar utcCalendar;

	Equator(float pRadiusIn, int mIn) {
		pRadius = pRadiusIn;
		mInterval = mIn;
		utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
	}

	PVector geoPlot(float lng, float lat) {

		//function for converting latitude and longitude into planet x,y,z coordinates

		float pX = pRadius * sin(radians(lat));

		PVector pPoint = new PVector(1, 1, 1);
		return pPoint;
	}

	void setTimes() {
		utcCalendar = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
		yearInt = utcCalendar.get(Calendar.YEAR);
		monthInt = utcCalendar.get(Calendar.MONTH);  
		dayInt = utcCalendar.get(Calendar.DAY_OF_MONTH);
		hourInt = utcCalendar.get(Calendar.HOUR_OF_DAY);
		minuteInt = utcCalendar.get(Calendar.MINUTE);
		secondInt = utcCalendar.get(Calendar.SECOND);
		millisecondInt = utcCalendar.get(Calendar.MILLISECOND);
	}

	double getDay() {

		//function to return the day number of the entire year

		double dayFloat = 0;

		int[] monthLengths = {
			31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
		};
		if (yearInt%4==0) {
			if (yearInt%100==0) {
				if (yearInt%400==0) {
					monthLengths[1] = 29;
				}
			}
			else {
				monthLengths[1] = 29;
			}
		}

		for (int i=0;i<monthInt;i++) {
			dayFloat += monthLengths[i];
		}
		dayFloat += (double) dayInt;
		dayFloat += (double) hourInt/24.0;
		dayFloat += (double) minuteInt/60.0/24.0;
		dayFloat += (double) secondInt/60.0/60.0/24.0;
		dayFloat += (double) millisecondInt/1000.0/60.0/60.0/24.0;
		return dayFloat; //this will be passed into solarDeclination()
	}

	double solarDeclination(double d) {

		//function for determining the solar declination - that is, 
		//the latitude at which the sun is directly overhead at midday.

		double dayAngle = (TWO_PI*(d-1.0))/365.0;
		solarDeclination = 0.006918 - 0.399912*Math.cos(dayAngle) + 0.070257*Math.sin(dayAngle) 
		- 0.006758*Math.cos(2.0*dayAngle) + 0.000907*Math.sin(2.0*dayAngle)
		- 0.002697*Math.cos(3.0*dayAngle) + 0.001480*Math.sin(3.0*dayAngle);
		return solarDeclination;
	}

	int getJulianDayNumber() {

		//function for converting gregorian day number into Julian calendar number
		//necessary for calculating the solar noon

		int jA = floor((14-monthInt)/12.0);
		int jY = yearInt + 4800 - jA;
		int jM = (monthInt+1) + 12*jA - 3;
		int jDayNumber = dayInt+floor((153*jM+2)/5) + 365*jY + floor(jY/4.0) - floor(jY/100.0) +floor(jY/400.0) - 32045;
		return(jDayNumber); //this passes to getRotation()
	}

	double getJulianTime(int jDayNumber) {

		//function for converting determining the decimal Julian Time
		//getJulianDayNumber() is the input argument

		double jTime = (double) jDayNumber;
		jTime += (double) (hourInt-12.0)/24.0;
		jTime += (double) minuteInt/1440.0;
		jTime += (double) secondInt/86400.0;
		jTime += (double) millisecondInt/86400000.0;
		//    println("current time is: "+jDate);
		return(jTime); //this will be passed into getRotation()
	}

	double getRotation(int date) {

		//function for calculating the angle of rotation the earth has achieved at the current time
		//getJulianDayNumber() is the argument

		//this function has an unusual structure due to the limitations of floating decimal precision
		//returns a value with a precision of less than one second, but only a real-world accuracy of about three minutes

		int jDate = date;
		double jDoubleDate = (double) jDate;
		double julianCycle = Math.round(jDoubleDate - 2451545 - .0009 - (0.0/360.0)); //0.0 is the longitude for determining solar noon at. Here we test for 0.0 degrees, UTC
		double solarNoon = 2451545.0 + (0.0/360.0) + julianCycle; solarNoon += 0.0009; //julian time of solar noon at given longitude
		double solarMeanAnomaly = (357 + 0.5291 + 0.98560028 * (solarNoon-2451545))%360.0; //Solar Mean Anomaly
		double e1 = Math.sin(Math.toRadians(solarMeanAnomaly)); double e2 = solarMeanAnomaly*2.0; e2 = Math.sin(Math.toRadians(e2)); double e3 = solarMeanAnomaly*3.0; e3 = Math.sin(Math.toRadians(e3));
		double equationOfCentre = e1 * 1.9148; equationOfCentre += e2 * 0.0200; equationOfCentre += e3 * 0.000300;
		double eclipticLongitude = (solarMeanAnomaly + 102 + 0.9372 + equationOfCentre + 180) % 360.0; //Ecliptic Longitude
		double solarTransit = solarNoon; solarTransit += Math.sin(Math.toRadians(solarMeanAnomaly))*0.0053; solarTransit -= Math.sin(Math.toRadians(2.0*eclipticLongitude))*0.0069;
		double currentTime = getJulianTime(jDate);
		double pOrbitAngle = solarTransit - currentTime; pOrbitAngle *= TWO_PI;
		//    println(pOrbitAngle);
		return(pOrbitAngle);
	}
	
	PVector returnGlobeCoordinate(float latitude, float longitude) {

		float lat = radians(latitude);
		float lng = radians(longitude);
		float calc1 = pRadius*cos(lat);

		float pX = calc1 * cos(lng);
		float pY = pRadius * sin(lat);
		float pZ = calc1 * sin(lng);

		PVector outputPVector = new PVector(pX,pY,pZ);
		return outputPVector;

	}
	
	int getSortKey() { //no paramaters returns the sort key of the current time
		
		//function to determine how many times mInterval has elapsed.
		//this number is used as a key to access the time-seperated draw lists
		//such that the entire day's data does not need to be held in memory
		
		sortKey = hourInt*(60/mInterval) + floor(minuteInt/mInterval);
		return sortKey;
		
	}
	
	int getSortKey(int[] timeFieldsI) { //entire timeFields array input
		
		//function to determine how many times mInterval has elapsed.
		//this number is used as a key to access the time-seperated draw lists
		//such that the entire day's data does not need to be held in memory
		
		int hourI = timeFieldsI[3];
		int minuteI = timeFieldsI[4];
		sortKey = hourI*(60/mInterval) + floor(minuteI/mInterval);
		return sortKey;
		
	}
	
	int getSortKey(int hourI,int minuteI) { //individual time fields input
		
		//function to determine how many times mInterval has elapsed.
		//this number is used as a key to access the time-seperated draw lists
		//such that the entire day's data does not need to be held in memory
		
		sortKey = hourI*(60/mInterval) + floor(minuteI/mInterval);
		return sortKey;
		
	}
	
	boolean testTime(int[] tFields) {
		if(tFields[4]+mInterval<60 && minuteInt+mInterval>tFields[4]){
			return true;
		}
		else if(tFields[4]+mInterval>60 && tFields[3]<23 && minuteInt+mInterval-60>tFields[4]) {
			return true;
		}
		else return false;
	}
	
}

