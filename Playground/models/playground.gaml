/**
* Name: Playground ABM Part1
* Author: hyesopshin
* Tags: 
*/


model playground

/* Insert your model definition here */

global {
	
	
	file buildings_shapefile <- shape_file("../includes/gaelic_building.shp", true);
	shape_file playgrounds_shapefile <- shape_file("../includes/gaelic_playground.shp");
	
	geometry shape <- envelope(buildings_shapefile);
	geometry open_area;
	
	
	init {
		create buildings from:buildings_shapefile {
			ask buildings overlapping self{
				is_building <- true;
			}			
		}
		create playground from:playgrounds_shapefile;
		open_area <- first(playgrounds_shapefile.contents);
		create children number: 250{
			int id <- int(self);
			location <- any_location_in(open_area);
			//location <- any_location_in(even(id) ? playground);
		}
	}
	
	reflex stop when: cycle = 1000 {
		do pause;
	}
	
}


species buildings {
	bool is_building <- true;
	aspect default { 
		draw shape  border: #darkgray width: 4;
	}
	
}

species playground {
	bool is_building <- false;
	
	aspect default { 
		draw shape  color: #white;
	}
	
}


species children {
	rgb color <- rnd_color(255);
	float speed <- gauss(5,1.5) #km/#h min: 2 #km/#h;
	
	
	
}


experiment playground_sim type: gui {
	//float minimum_cycle_duration <- 0.02;
		output {
		display map type: opengl{
			species playground refresh: false;
			species buildings refresh: false;
			species children refresh: false;

		}
	}
}