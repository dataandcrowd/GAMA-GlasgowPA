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
	shape_file playgrounds_env <- shape_file("../includes/gaelic_playground_env.shp");
	
	geometry shape <- envelope(playgrounds_env);
	geometry open_area;
	
	
	init {
		create buildings from:buildings_shapefile {
			ask buildings overlapping self{
				is_building <- true;
			}			
		}
		create playground from:playgrounds_shapefile;
		open_area <- first(playgrounds_shapefile.contents);
		create children number: 250 {
			int id <- int(self);
			location <- any_location_in(open_area);
			if (gender_int = true){
				gender <- "boy";
				}
			else{
				gender <- "girl";
				}
			}
}
	
	reflex stop when: cycle = 10000 {
		do pause;
	}
	
}


species buildings {
	bool is_building <- true;
	float height <- rnd(5#m, 10#m) ;
    
    aspect default {
    draw shape color: #dodgerblue border: #black depth: height;
    }
	
}

species playground {
	bool is_building <- false;
	
	aspect default { 
		draw shape color: #white border: #black;
	}
	
}


species children skills: [pedestrian] {
	
	image_file boy_icon <- image_file("../includes/boy.png");
	image_file girl_icon <- image_file("../includes/girl.png");
	
	//agent's personal status
	float speed <- gauss(2,1.5) #km/#h min: 2 #km/#h;
	bool avoid_other <- true;
	string gender;
	bool gender_int <- flip (0.5);
	
	//agent shape
	aspect default {
   		draw circle(1#m) color: (gender_int ? #red : #green);
   	}

	aspect icon {
        draw (gender_int ? boy_icon : girl_icon) size: 1.5;
    }

	
	//mobility pattern
	reflex basic_move {
		do wander amplitude: 30.0 bounds: open_area;
	}
	
}


experiment playground_sim type: gui {
	//float minimum_cycle_duration <- 0.02;
		output {
		display map type: opengl{
			species playground aspect:default;
			species buildings aspect:default;
			species children aspect:icon;

		}
	}
}