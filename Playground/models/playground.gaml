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
	
	int nb_obstacles <- 0 parameter: true;
	
	/* */
	bool display_free_space <- false parameter: true;
	bool display_force <- false parameter: true;
	bool display_circle_min_dist <- true parameter: true;
	
	float P_shoulder_length <- 0.45 parameter: true;
	float P_proba_detour <- 1.0 parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 5.0 parameter: true ;
	float P_pedestrian_consideration_distance <- 5.0 parameter: true ;
	float P_tolerance_waypoint <- 0.1 parameter: true;
	bool P_use_geometry_waypoint <- true parameter: true;
	
	string P_model_type <- "simple" among: ["simple", "advanced"] parameter: true ; 
	
	float P_A_pedestrian_SFM_advanced parameter: true <- 25.0 category: "SFM advanced" ;
	float P_A_obstacles_SFM_advanced parameter: true <- 25.0 category: "SFM advanced" ;
	float P_B_pedestrian_SFM_advanced parameter: true <- 0.5 category: "SFM advanced" ;
	float P_B_obstacles_SFM_advanced parameter: true <- 0.1 category: "SFM advanced" ;
	float P_relaxion_SFM_advanced  parameter: true <- 0.1 category: "SFM advanced" ;
	float P_gama_SFM_advanced parameter: true <- 0.35 category: "SFM advanced" ;
	float P_lambda_SFM_advanced <- 0.1 parameter: true category: "SFM advanced" ;
	float P_minimal_distance_advanced <- 0.5 parameter: true category: "SFM advanced" ;
	
	
	float P_n_prime_SFM_simple parameter: true <- 3.0 category: "SFM simple" ;
	float P_n_SFM_simple parameter: true <- 2.0 category: "SFM simple" ;
	float P_lambda_SFM_simple <- 2.0 parameter: true category: "SFM simple" ;
	float P_gama_SFM_simple parameter: true <- 0.35 category: "SFM simple" ;
	float P_relaxion_SFM_simple parameter: true <- 0.54 category: "SFM simple" ;
	float P_A_pedestrian_SFM_simple parameter: true <- 4.5category: "SFM simple" ;
	
	/* */
	
	
	
	
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
		
		// Create children
		create children number: 250 {
			obstacle_consideration_distance <- P_obstacle_consideration_distance;
			obstacle_consideration_distance <- P_obstacle_consideration_distance;
			pedestrian_consideration_distance <- P_pedestrian_consideration_distance;
			shoulder_length <- P_shoulder_length;
			avoid_other <- P_avoid_other;
			proba_detour <- P_proba_detour;
			use_geometry_waypoint <- P_use_geometry_waypoint;
			tolerance_waypoint <- P_tolerance_waypoint;
			
			pedestrian_model <- P_model_type;
			if (pedestrian_model = "simple") {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_simple;
				relaxion_SFM <- P_relaxion_SFM_simple;
				gama_SFM <- P_gama_SFM_simple;
				lambda_SFM <- P_lambda_SFM_simple;
				n_prime_SFM <- P_n_prime_SFM_simple;
				n_SFM <- P_n_SFM_simple;
			} else {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_advanced;
				A_obstacles_SFM <- P_A_obstacles_SFM_advanced;
				B_pedestrians_SFM <- P_B_pedestrian_SFM_advanced;
				B_obstacles_SFM <- P_B_obstacles_SFM_advanced;
				relaxion_SFM <- P_relaxion_SFM_advanced;
				gama_SFM <- P_gama_SFM_advanced;
				lambda_SFM <- P_lambda_SFM_advanced;
				minimal_distance <- P_minimal_distance_advanced;
			}
			
			pedestrian_species <- [children];
			//obstacle_species<-[obstacle];
			
			
			
			
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


species children skills: [pedestrian] schedules: shuffle(children){
	
	image_file boy_icon <- image_file("../includes/boy.png");
	image_file girl_icon <- image_file("../includes/girl.png");
	
	//agent's personal status
	float speed <- gauss(0.1,0.3) #km/#h min: 0.2 #km/#h;
	bool avoid_other <- true;
	string gender;
	bool gender_int <- flip (0.5);
	bool age_int <- flip (0.2);
	int age;
	list target_list  <- [{90, 90}, {50,50}];
	point current_target;
	
	
	//agent shape
	aspect default {
   		draw circle(1#m) color: (gender_int ? #red : #green);
   	}

	aspect icon {
        draw (gender_int ? boy_icon : girl_icon) size: 1.5;
    }

		
	
	//mobility pattern
	reflex break_wandering {
		do wander amplitude: 10.0 bounds: open_area;
		//do walk_to target: current_target bounds: open_area;
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