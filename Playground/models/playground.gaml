/**
* Name: Playground ABM Part1
* Author: hyesopshin
* Tags: 
*/

model playground

/* Insert your model definition here */

global {
	
	
	shape_file buildings_shapefile <- shape_file("../includes/gaelic_building.shp");
	shape_file playgrounds_shapefile <- shape_file("../includes/gaelic_playground.shp");
	shape_file playgrounds_env <- shape_file("../includes/gaelic_playground_env.shp");
	
	geometry shape <- envelope(envelope(playgrounds_env)+envelope(buildings_shapefile));
	geometry open_area;
	
	
	init {
		create buildings from:buildings_shapefile {
			ask buildings overlapping self{
				is_building <- true;
			}			
		}
		create playground from:playgrounds_shapefile;
		open_area <- first(playgrounds_shapefile.contents);
		
		
		// Create children
		create children number: 100 {
			int id <- int(self);
			location <- any_location_in(open_area);
			current_target <- one_of(target_list) ;
			//write one_of(current_target) ;
			
			if (gender_int = true){
				gender <- "boy";
				}
			else{
				gender <- "girl";
				}
			
			if (age_int = true){
				age <- 9;
				}
			else{
				age <- 10;
				}
			}
}
	 
	reflex stop when: children all_match(each.current_target = each.location){
		do pause;
		
		list<agent> var0 <- agents_overlapping(self);
		write var0;
	}
	int tick <- 1;
	/* 
	reflex tiktok {
	  write counter;
      if counter = 0 {
      	counter <- 150;
      }}	
	*/
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
		draw shape color: #lightsteelblue border: #white;
	}
	
}


species children skills: [moving] schedules: shuffle(children){
	image_file boy_icon <- image_file("../includes/boy.png");
	image_file girl_icon <- image_file("../includes/girl.png");
	
	/*agent's personal status*/
	float speed <- gauss(0.07,0.04) #km/#h min: 0.03 #km/#h;
	bool avoid_other <- true;
	string gender;
	bool gender_int <- flip (0.5);
	bool age_int <- flip (0.2);
	int age;
	list target_list  <- [{100, 60}, {110,59.5}, {120,59}, {130,58}];
	point current_target;
	int counter <- 10000 update: counter - tick;
	
	
	/*agent shape */
	aspect icon {
        draw (gender_int ? boy_icon : girl_icon ) size: 1.5;
	}
	//aspect default {
    //		draw circle(1#m) color: (gender_int ? #red : #green);
    		
   	//}
    	
/* mobility pattern*/
	reflex breaktime {
		if (counter >= 0){
		do wander amplitude: 45.0 bounds: open_area;
		}
		else{do goto target: current_target speed: 0.002;
			
			//if the cell contains more than two people 
			//then move to 1 cell south
		
		}
		
		
	}
}

experiment playground_sim type: gui {
		output {
				display map type: opengl{
					species playground aspect:default;
					species buildings aspect:default;
					species children aspect:icon;
					}
				}
}