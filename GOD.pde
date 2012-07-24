//This is GOD, the class for a Geospatially Overlaid Dataset.
//It takes a data input, parses it and is then called by the Planet to which it is assigned.

class GOD {

	PApplet parent; //Reference to GESUS
	private String name; //name of the dataset
	private String source; //source of the dataset
	private String path; //path
	private String filetype; //type of data file
	private String separator; //character used to separate 
	private int fieldCount; //how many columns of data exist
	private HashMap metaValues; //HashMap of the column names
	private XMLElement metaData;
	private String[][] godLayerData; 
	private int datasetSize;
	private int latitudeIndex;
	private int longitudeIndex;
	private int timeIndex;
	private int depthIndex;
	private ArrayList[] timeBins;
	private int timeBinsCount;
	private int sortKey;
	private ArrayList relevantBins;
	private int loopedBinSize;
	private CHRIST cOpener;
	private int maxChrists; //approximation (over-estimation) of maximum number of CHRISTS in a frame
	private ArrayList currentVertices;
	private ArrayList currentColours;
	private GLModel currentModel;
	private GLTexture currentModelTexture;
	private int currentModelIndex;
	private int previousModelIndex;


	GOD(PApplet p,XMLElement GODLayer) {
		parent = p;
		metaData = GODLayer;
		loadData();
		createChrists();
		createCurrentModel();
	}

	void getMetadata() {

		name = metaData.getChild("name").getContent();
		source = metaData.getChild("source").getContent();
		path = metaData.getChild("path").getContent();
		filetype = metaData.getChild("filetype").getContent();
		separator = metaData.getChild("separator").getContent();
		fieldCount = metaData.getChild("values").getChildCount();
		metaValues = new HashMap(fieldCount,1);
		for (int i=0;i<fieldCount;i++) {
			metaValues.put(metaData.getChild("values").getChild(i).getContent(),str(i));
		}
	}

	void loadData() {

		getMetadata();

		if (filetype==null) {
			println("filetype for "+name+" is either not set or caught");
		}
		else if (filetype!=null) {

			if (filetype.equals("csv")) {
				String[] rawLines = loadStrings(path);
				int ii=rawLines.length;
				datasetSize = ii-1;
				godLayerData = new String[datasetSize][fieldCount];
				for(int i=1;i<ii;i++) {
					String[] splitLine = split(rawLines[i], separator);
					for(int j=0;j<fieldCount;j++) {
						godLayerData[i-1][j] = splitLine[j];
					}
				}
				latitudeIndex = int(metaValues.get("latitude").toString());
				longitudeIndex = int(metaValues.get("longitude").toString());
				timeIndex = int(metaValues.get("time").toString());
			}
			else {
				println("filetype '"+filetype+"' is not recognised");
			}
		}	
	}

	void createChrists() {
		timeBinsCount = equator.getSortKey(23,59)+1;
		timeBins = new ArrayList[timeBinsCount];
		for(int i=0;i<timeBinsCount;i++) {
			timeBins[i] = new ArrayList();			
		}
		for(int i=0;i<datasetSize;i++) {
			String time = godLayerData[i][timeIndex];
			String lat = godLayerData[i][latitudeIndex];
			String lon = godLayerData[i][longitudeIndex];
			CHRIST cInstance = new CHRIST(time,float(lat),float(lon));
			timeBins[equator.getSortKey(cInstance.timeFieldsI)].add(cInstance);
		}
		maxChrists = findMaxVertices();
	}
	
	int findMaxVertices() {
		int count = 0;
		for(int i=0;i<timeBinsCount-1;i++) {
			int testCount = timeBins[i].size()+timeBins[i+1].size();
			if(testCount>count) count = testCount;
		}
		return count;
	}
	
	void createCurrentModel() {
		currentModel = new GLModel(parent, maxChrists, POINT_SPRITES, GLModel.STREAM);
		currentModel.initColors();
		currentModelTexture = new GLTexture(parent, "textures/particle.png");
		float pmax = currentModel.getMaxPointSize();
		currentModel.initTextures(1);
		currentModel.setTexture(0,currentModelTexture);
		currentModel.setMaxSpriteSize(0.9*pmax);
		currentModel.setSpriteSize(20, 150);
		updateCurrentModel();
		
	}
	
	void updateCurrentModel() {
		
		currentVertices = new ArrayList();
		currentColours = new ArrayList();
		int currentSortKey = equator.getSortKey();
		currentModelIndex = 0;
		for(int i=0;i<timeBins[currentSortKey].size();i++) {
			cOpener = (CHRIST) timeBins[currentSortKey].get(i);
			if(cOpener.testToDisplay()) {
				currentVertices.add(cOpener.position.x);
				currentVertices.add(cOpener.position.y);
				currentVertices.add(cOpener.position.z);
				currentColours.add(cOpener.colours[0]);
				currentColours.add(cOpener.colours[1]);
				currentColours.add(cOpener.colours[2]);
				currentColours.add(cOpener.colours[3]);
				currentModelIndex++;
			}
			
		}
		if(currentSortKey!=timeBinsCount-1) {
			for(int i=0;i<timeBins[currentSortKey+1].size();i++) {
				cOpener = (CHRIST) timeBins[currentSortKey+1].get(i);
				if(cOpener.testToDisplay()) {
					currentVertices.add(cOpener.position.x);
					currentVertices.add(cOpener.position.y);
					currentVertices.add(cOpener.position.z);
					currentColours.add(cOpener.colours[0]);
					currentColours.add(cOpener.colours[1]);
					currentColours.add(cOpener.colours[2]);
					currentColours.add(cOpener.colours[3]);
					currentModelIndex++;
				}
			}
		}
		if(currentModelIndex!=previousModelIndex) println(name+" has changed number of displayed points to: "+currentModelIndex);
		currentModel.beginUpdateVertices();
		noFill();
		strokeWeight(3);
		stroke(255,0,0);
		for(int i=0;i<currentModelIndex;i++) {
			currentModel.updateVertex(i,(Float) currentVertices.get(3*i),(Float) currentVertices.get(3*i+1),(Float) currentVertices.get(3*i+2));
			//point((Float) currentVertices.get(3*i),(Float) currentVertices.get(3*i+1),(Float) currentVertices.get(3*i+2));
		}
		currentModel.endUpdateVertices();
		currentModel.beginUpdateColors();
		for(int i=0;i<currentModelIndex;i++) {
			currentModel.updateColor(i,(Float) currentColours.get(4*i),(Float) currentColours.get(4*i+1),(Float) currentColours.get(4*i+2),(Float) currentColours.get(4*i+3));
		}
		currentModel.endUpdateColors();
		previousModelIndex = currentModelIndex;
	}
	

	void drawData() {	
		updateCurrentModel();
		currentModel.render(0,currentModelIndex-1);
	}

}

