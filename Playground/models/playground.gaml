/**
* Name: Playground ABM Part1
* Author: hyesopshin
* Tags: 
*/


model playground

/* Insert your model definition here */

global {
	
	
	shape_file buildings_shapefile <- shape_file("../includes/free spaces.shp");
	shape_file playgrounds <- shape_file("../includes/Schoolareas.shp");
	
	geometry shape <- envelope(buildings_shapefile);
	
	
	
	init {
		//create buildings from:buildings_shapefile;
	
	}
	}