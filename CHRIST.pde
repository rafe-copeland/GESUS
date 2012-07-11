//This is CHRIST, the class for the Calculation, Holding and Referal of Instances in Space-Time
//It receives a data entry from a GOD, performs space-time calculations and stores them ready for drawing

class CHRIST {
	
	String[] timeFields;
	int[] timeFieldsI;
	float[] colours = {255,0,0,255};
	int yearI;
	int monthI;
	int dateI;
	int hourI;
	int minuteI;
	int secondI;
	PVector position;
	
	CHRIST(String t,float lat,float lon) {
		timeFields = splitTokens(t,"- :");
		timeFieldsI = int(timeFields);
		position = equator.returnGlobeCoordinate(lat,lon);
	}
	
	boolean testToDisplay() {
		if(equator.testTime(timeFieldsI)==true) {
			return true;
		}
		else return false;
	}
	
	
	
}