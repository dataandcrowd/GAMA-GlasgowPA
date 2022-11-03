/**
* Name: Playground ABM Part1
* Author: hyesopshin
* Tags: 
*/

model playground2

/* Insert your model definition here */

global {
	
	
	shape_file buildings_shapefile <- shape_file("../includes/gaelic_building.shp");
	shape_file playgrounds_shapefile <- shape_file("../includes/gaelic_playground.shp");
	shape_file playgrounds_env <- shape_file("../includes/gaelic_playground_env.shp");
	
	//geometry shape <- envelope(envelope(playgrounds_env)+envelope(buildings_shapefile));
	
	geometry shape <- rectangle(25, 25);
	//geometry shape <- circle(10);
	geometry open_area <- shape;
	
	
	init {

		//create playground ;
		//open_area <- first(playgrounds_shapefile.contents);
		
		
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
	list target_list  <- [{3, 3}, {3,7}, {3,11}, {3,15}];
	point current_target;
	int counter <- 10000 update: counter - tick;
	
	
	/*agent shape */
	aspect icon {
        draw (gender_int ? boy_icon : girl_icon ) size: 1.5;
	}

    	
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
					graphics "Abstract Playground"{
						draw rectangle(5,15) at:{0,10} color:#teal;
						draw shape color: #dimgrey border: #white;
						
						
					}
					species children aspect:icon;
					}
					
				}
}