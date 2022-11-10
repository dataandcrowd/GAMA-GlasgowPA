/**
* Name: roadnetwork
* Based on the internal empty template. 
* Author: hyesopshin
* Tags: 
*/


model roadnetwork

/* Insert your model definition here */

global {
	string scale <- "53zones" among: ["53zones", "120zones"];
	file private_garden_file <- file('../includes/Layers_glasgow/' + scale + '/Private_Garden_' + scale + '.shp');
	file road_shape_file <- file('../includes/Layers_glasgow/' + scale + '/Road_' + scale + '.shp');
	file landuse_shape_file <- file('../includes/Layers_glasgow/' + scale + '/Landuse_' + scale + '.shp');
	file my_landuse_file <- csv_file('../includes/Layers_glasgow/land_use_table.csv', ',', true);
	file food_drink_shapefile <- file('../includes/Layers_glasgow/' + scale + '/FoodDrink_' + scale + '.shp');
	file buildings_shapefile <- file('../includes/Layers_glasgow/' + scale + '/Bld_' + scale + '.shp');
	file zone_shape_file <- file('../includes/Layers_glasgow/' + scale + '//Zones_' + scale + '.shp');
	file school_shape_file <- file('../includes/Layers_glasgow/' + scale + '/Prim_Edu_' + scale + '.shp');
	file leisure_shape_file <- file('../includes/Layers_glasgow/' + scale + '/OS_Open_Leisure_Centre.shp');
	
	
	/* Setting up the Ecosystem */
	geometry shape <- envelope(road_shape_file);
	list<rgb> red_pallete <- brewer_colors("Reds");
	matrix data <- matrix(my_landuse_file);
	float step <- #minute;
	int t <- 60 * 7 + 48; //minutes counter
	float current_hour <- 7.8;
	int days <- 1;
	int week_day <- 1;
	graph road_network;
	int nb_agents <- length(children);
	bool activity_hours <- false; //act hours are:15:00-19:00
	list<building> residential;
	
	
	
	bool show_school_routes <- false;
	bool show_zones <- false;
	float imp_kids <- 0.1;
	float imp_friends_influence <- 0.3; //impact of friends on my_activeness
	string travel_mode <- "usual" among: ["usual", "active_school", "walk_all"];
	graph child_graph <- ([]);
	string optimizer_type <- #AStar among: [#NBAStar, #NBAStarApprox, #Dijkstra, #AStar, #BellmannFord, #FloydWarshall];
	
	
	init{
		write "Start initialise:" + date("now");
		
		
		do create_layers;
		do create_children;
		do assign_schools;
		//do cal_sch_walk_prob;
		//do assign_neighbourhood;
		//do assign_routehome;
		
	}




	action create_layers {
		create schools from: school_shape_file with: [id_catch::int(read("ID_catch"))];
		
		create zone from: zone_shape_file with:
		[dataZone::string(read("DataZone")), nb_children::int(1.5 * int(read("8_9"))), simd::int(read("Quintile")), // unit of norm_crime , 1 unit=1 SD
		prob_social::[float(read("de25_44")), float(read("c2_25_44")), float(read("c1_25_44")), float(read("ab25_44"))],
		AB_car_prob::[float(read("AB_NO_CAR")), float(read("AB_1CAR")), float(read("AB_2CAR"))], //Least deprived
		C1_car_prob::[float(read("C1_NO_CAR_")), float(read("C1_1CAR")), float(read("C1_2CAR"))], C2_car_prob::[float(read("C2_NO_CAR_")), float(read("C2_1CAR")), float(read("C2_2CAR"))], DE_car_prob::[float(read("DE_NO_CAR_")), float(read("DE_1CAR")), float(read("DE_2CAR"))]]; //Most deprived
		
		ask zone where (each.nb_children = 0) {do die;}
				
		create road from: road_shape_file;
		road_network <- as_edge_graph(list(road)); 
		
		create building from: buildings_shapefile with:
		[type:: string(read("type")), zone::string(read("zone")), area::int(read("area")), 
			x_cor::int(read("X_cor")), y_cor::int(read("Y_cor")), height::int(read("Height")), 
			id_catch::int(read("Id_catch")), poly_id::int(read("Poly_ID")), walk_quant::int(read("walk_quant"))
		];
		residential <- building where (each.type = 'Home');
		
	}
	
	
	
	action create_children {
		int counter <- 0;
		ask zone {
			list<building> zone_homes <- residential where (each.zone = self.dataZone); 
			create children number: nb_children {
				counter <- counter + 1; 
				if counter / 1000 = int(counter / 1000) {
					write counter;
				}

				my_zone <- myself;
				my_home <- one_of(zone_homes);
				id_catch <- my_home.id_catch;
				x_cor <- my_home.x_cor;
				y_cor <- my_home.y_cor;
				location <- any_location_in(my_home);
				my_social_status <- rnd_choice(my_zone.prob_social) + 1; //4 social level 1,2,3,4 (1-poorest 4-richest)
				if my_social_status = 1 {
					num_car <- rnd_choice(my_zone.DE_car_prob);
				} //assign number of car based on the distribution for DE class in the data zone
				if my_social_status = 2 {
					num_car <- rnd_choice(my_zone.C2_car_prob);
				}
				if my_social_status = 3 {
					num_car <- rnd_choice(my_zone.C1_car_prob);
				}
				if my_social_status = 4 {
					num_car <- rnd_choice(my_zone.AB_car_prob);
				}

				my_simd <- myself.simd;
				my_simd_imp <- my_simd = 5 ? 1.0 : (my_simd = 4 ? 0.9 : (my_simd = 3 ? 0.8 : (my_simd = 2 ? 0.7 : 0.6)));
				// impact of crime of playing_outdoors no impact if crime<=0 
				// low impact-80% 0-0.7, medium 60% [0.7-1.3] high 40% >=1.3
				my_neigh_prob <- min(1, 0.2 * playing_outdoors * my_simd_imp); 
			}
		}
	}

	action assign_schools {
		ask children parallel: true {
			list<schools> my_school_candidates <- schools where (each.id_catch = self.id_catch) sort_by (each distance_to self); 
			my_school <- length(my_school_candidates) > 2 ? my_school_candidates[rnd(0, 2)] : one_of(my_school_candidates);
			if my_school = nil {
				my_school_candidates <- schools sort_by (each distance_to self);
				my_school <- my_school_candidates[0];
			}
		}

		ask schools parallel: true {
			nb_pupils <- length(children where (each.my_school = self)); 
		}

		ask children where (each.my_school.nb_pupils < 25) parallel: true {
			if num_car = 0 {
				list<schools> my_school_candidates <- schools where (each.nb_pupils >= 25) sort_by (each distance_to self);  
				my_school <- my_school_candidates[0];
			}

			if num_car > 0 {
				list<schools> my_school_candidates <- schools where (each.nb_pupils >= 25) sort_by (each distance_to self); 
				my_school <- my_school_candidates[rnd(0, 2)];
			}
		}

		ask schools parallel: true {
			nb_pupils <- length(children where (each.my_school = self)); 
		} 
	}
}
	

species road {
	float speed_coef;
	aspect default {
		draw shape color: #black;
	}

}


species children skills: [moving] { 
	zone  my_zone;
	string gender <- flip(0.5) ? "boy" : "girl";
	int   my_social_status; //4 social levels 1-richest 4-poorest based on AB, C1,C2,DE
	float my_activeness <- max(0.3, gauss({1, 0.3})); //distribution of tendency to be active (A)
	float playing_outdoors <- max(0, gauss({1, 0.3})); //distribution of preference to be outdoor (O)
	float my_crime;
	int   my_simd;
	float my_simd_imp;
	int   nb_friends;
	int   num_car;
	int   id_catch;
	float my_neigh_prob;
	int   distance_to_school;
	int   x_cor;
	int   y_cor;
	float school_walk_prob; //probability to walk to school
	building my_home;
	schools my_school;
	point target;
	//activities
	int dis_target;
	list<children> my_best_friends;
	list<int> activity_list;
	list<int> lu_list <- list_with(27, 0); //list the counts the time spent on each landuse. Land use is organised by code in the list
	string my_activity;
	int my_lu_code <- 1;
	bool have_formal; //do I have formal activties today
	bool a_s_play <- false;
	int nb_sports <- 0;
	
	list<int> list_mvpa;
	list<int> list_lu_mvpa <- list_with(27, 0);
	children goto_friend; ////the friend to visit
	list<children> host_friends; //the friends that are hosted 
	bool meeting_friends <- false;
	float meet_hour;
	bool with_friends <- false; //when the meeting take place=true 
	path school_route;
	
	path my_path;
	string purpose; //to determine what reflex the agent will implement
	int duration;
	int mode_of_transport <- 0;
	float my_speed;
	bool return_home <- false;
	bool goto_school <- false;
	
	aspect default {
		if target != nil and mode_of_transport = 2 {
			draw square(12) color: #black;
		} else {
			draw circle(8) border: #black color: #yellow;
		}
		if (school_route != nil and show_school_routes) {
			draw (school_route.shape + 10) color: #magenta;
		}
		if my_activity = "Neigh play" and target = nil {
			draw circle(8) border: #black color: #cyan;
		}
		if my_activity = "Planned sport" and target = nil {
			draw circle(8) border: #black color: #blue;
		}
	}


	action show_route_sc {
		draw (school_route.shape + 10) color: #magenta;
	}

	reflex go_to_school when: current_hour = 8.0 {
		purpose <- 'go_school';
		target <- my_school.location;
		do set_mode_of_transport(false);
	}

	action set_mode_of_transport (bool return_same_mode) {
		if return_same_mode = false {
			path my_route <- path_between(road_network, location, target);
			dis_target <- int(my_route.edges sum_of (each.perimeter));
			float walk_prob;
			if purpose = 'go_school' {
				walk_prob <- travel_mode = "active_school" or travel_mode = "walk_all" ? 1.0 : school_walk_prob;
				//walk_prob<-distance_to_school<=1500?1:school_walk_prob; //walking to school scenario and walk all
			} else {
				if travel_mode = "walk_all" {
					walk_prob <- 1.0;
				} else {
					walk_prob <- num_car = 0 or dis_target < 300 ? 1 : 0.3 * 0.9 ^ (my_home.walk_quant - 1) + 0.2 * 0.8 ^ num_car + 0.5 * 0.7 ^ ((dis_target / 300) - 1);
				}
				//walk_prob<-num_car=0 or dis_target<1500? 1: 0.3 *0.9^(my_home.walk_quant-1)+0.2*0.8^num_car+0.5*0.7^((dis_target/300)-1) ; //for scenario walk all dis<1500	
			}

			mode_of_transport <- flip(walk_prob) ? 1 : 2; //prob for: walk=1, car=2	
		}

		my_speed <- mode_of_transport = 1 ? 1.2 : 5;
		return_same_mode <- false;
	}

	reflex move_to_target when: target != nil {
		do goto on: road_network target: target speed: my_speed;
		if mode_of_transport = 1 {
			lu_list[23] <- lu_list[23] + 1; //updating walking in list
		}

		if mode_of_transport = 2 {
			lu_list[25] <- lu_list[25] + 1; //updating car in list
		}
		//do report_which_road;
		if location = target and purpose = 'go_school' {
			my_activity <- "School";
			lu_list[20] <- lu_list[20] + 60 * 6;
			int PE <- my_school.pe_day = week_day ? 1 : 0;

			target <- nil;
			purpose <- 'stay_school';
			location <- any_location_in(my_school);
		}

		
		

		

		if location = target and purpose = 'go_home' {
			target <- nil;
			purpose <- 'stay_home';
			location <- any_location_in(my_home);
		}

	}

	reflex school_time when: purpose = 'stay_school' {
	//end of school
		if current_hour >= 15.0 {
				do set_mode_of_transport(true);
				do go_home;
			}

		}

	

	

	action go_home {
		purpose <- 'go_home';
		target <- my_home.location;
		my_activity <- "home";
	}

	

	


}


species schools {
	int id_catch;
	int pe_day <- rnd(4) + 1;
	rgb color <- rgb(255, 0, 127);
	int nb_pupils;
	aspect base {
		draw shape border: #black color: color;
	}
}

species zone {
	string dataZone;
	int nb_children;
	list<float> AB_car_prob; //list of car prob [no_car, one_car, two_cars]
	list<float> C1_car_prob; //list of car prob [no_car, one_car, two_cars]
	list<float> C2_car_prob; //list of car prob [no_car, one_car, two_cars]
	list<float> DE_car_prob; //list of car prob [no_car, one_car, two_cars]
	list<float> prob_social; //list of fraction of each class in the zone [DE,C2,C1,ab]
	int simd;
	int avg_dis_sh;
	
	aspect default {
		draw shape.contour + 4 color: #brown;
	}
}


species building {
	string type; // Home,School, Other use
	string zone;
	int poly_id;
	int area;
	int height;
	int x_cor;
	int y_cor;
	int id_catch;
	int walk_quant; //walkability quantile 1-high 5- low 
	rgb color <- #gray;

	aspect base {
		draw shape color: color;
	}
}



experiment pathfinding type: gui {
	parameter "Show school routes" var: show_school_routes;
	output {
	display simulation type: opengl {
			
			species zone aspect: default;
			species building aspect: base refresh: false;
			species schools aspect: base refresh: false;
			species road aspect: default refresh: false;	
			species children aspect: default refresh: true;
	}
}
}
