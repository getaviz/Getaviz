package org.getaviz.generator.spl;

import org.getaviz.generator.Step;
import org.getaviz.generator.database.DatabaseConnector;

import java.io.FileReader;
import org.json.simple.*;
import org.json.simple.parser.JSONParser;

public class SPLEnhancement implements Step {

	//private DatabaseConnector connector = DatabaseConnector.getInstance();
	//private 
	
	@Override
	public boolean checkRequirements() {
		// TODO Auto-generated method stub
		// check if metaData.json exists and if not, tell that it has to run before
		return false;
	}

	@Override
	public void run() {
		if (checkRequirements()) {
			enhanceClasses();
		}
	}

	private void enhanceClasses() {
		BenchmarkFileReader bfReader = new BenchmarkFileReader();
		bfReader.read();
		String path = "C:\\Users\\Janik\\Documents\\Bachelorarbeit\\getaviz\\generator2\\org.getaviz.generator\\test\\output\\ArgoUmlTest\\default\\model\\metaData.json";
		JSONParser parser = new JSONParser();
		try { 
			FileReader reader = new FileReader(path);
			JSONArray arr = (JSONArray) parser.parse(reader);
			for (Object obj: arr) {
				JSONObject jsonObj = (JSONObject) obj;
				String qualifiedName = jsonObj.get("qualifiedName").toString();
				int index = qualifiedName.indexOf("(");
				if (index >= 0) {
					qualifiedName = qualifiedName.substring(0, index);
				}
				System.out.println(qualifiedName);
			}
		} catch (Exception e) {
			System.out.println(e.toString());
		}
	}
	
	public static void main(String[] args) {
		SPLEnhancement spl = new SPLEnhancement();
		spl.enhanceClasses();
	}

}
