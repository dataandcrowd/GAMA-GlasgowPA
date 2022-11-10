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
	int save_on_day <- 100;
	string save_file <- 'scenario';
	float max_visits <- 0.0;
	float min_visits <- 0.0;
	float max_less_min <- 1.0;
	
	bool show_school_routes <- false;
	bool show_zones <- false;
	float imp_kids <- 0.1;
	float imp_friends_influence <- 0.3; //impact of friends on my_activeness
	string travel_mode <- "usual" among: ["usual", "active_school", "walk_all"];
	graph child_graph <- ([]);
	string optimizer_type <- #AStar among: [#NBAStar, #NBAStarApprox, #Dijkstra, #AStar, #BellmannFord, #FloydWarshall];
	
	
	init{
		write "Start initialise:" + date("now");
		
		
		create road from: road_shape_file;
	}
	
	action create_layers {
		
		road_network <- as_edge_graph(list(road)); 
		road_network <- road_network with_shortest_path_algorithm #AStar;
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

				my_crime <- myself.norm_crime;
				my_simd <- myself.simd;
				my_simd_imp <- my_simd = 5 ? 1.0 : (my_simd = 4 ? 0.9 : (my_simd = 3 ? 0.8 : (my_simd = 2 ? 0.7 : 0.6)));
				// impact of crime of playing_outdoors no impact if crime<=0 
				// low impact-80% 0-0.7, medium 60% [0.7-1.3] high 40% >=1.3
				my_neigh_prob <- min(1, n_p * playing_outdoors * my_simd_imp); 
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
			avg_my_social_status <- (children where (each.my_school = self) mean_of (each.my_social_status)) with_precision 2;
		}

	}

	action cal_sch_walk_prob {
		ask children parallel: true {
			school_route <- path_between(road_network, my_home, my_school);
			if school_route = nil {
				do die;
			}

			distance_to_school <- int(school_route.edges sum_of (each.perimeter)); //distance to school based on roads
			if distance_to_school <= 300 or num_car < 1 {
				school_walk_prob <- 1.0;
			} else {
				float coef_dis <- -1.6 * ln(distance_to_school / 250) + 0.056; //-1.1*ln(dis/250)+0.056
				float coef_walkb <- my_home.walk_quant = 1 ? 0 : -0.035 * (my_home.walk_quant - 1) ^ 2 + 0.0678 * (my_home.walk_quant - 1) - 0.8382; // -0.0292*(walk-1)^2+0.0678*(walk-1)-0.838
				float winter_coef <- -0.3;
				float logit_0 <- -5.807733 - (-1.427 + coef_walkb + coef_dis + winter_coef); //cut1-(-1.427+coef_walk+coef_dis)
				float logit_1_2 <- -4.922359 - (-1.427 + coef_walkb + coef_dis + winter_coef); ////cut2-(-1.427+coef_walk+coef_dis)
				float logit_3_4 <- -3.9048 - (-1.427 + coef_walkb + coef_dis + winter_coef); ////cut3-(-1.427+coef_walk+coef_dis) ******cu1,cut2,cut3 are coefficient from ordinal logistic regression -1.427 is the coef of latitude- impact of weather in Glasgow 
				float cum_prob0 <- exp(logit_0) / (1 + exp(logit_0));
				float cum_prob_1_2 <- exp(logit_1_2) / (1 + exp(logit_1_2));
				float cum_prob_3_4 <- exp(logit_3_4) / (1 + exp(logit_3_4));
				float prob0 <- cum_prob0;
				float prob1_2 <- cum_prob_1_2 - cum_prob0;
				float prob_3_4 <- cum_prob_3_4 - cum_prob_1_2;
				float prob_5 <- 1 - cum_prob_3_4;
				int cat <- rnd_choice(prob0, prob1_2, prob_3_4, prob_5); //One of the number of active walking categories is selected  
				school_walk_prob <- ([0, rnd(0.2, 0.4), rnd(0.4, 0.8), rnd(0.8, 1.0)][cat]);
			}

			if distance_to_school > 2500 and num_car > 0 {
				school_walk_prob <- 0.0;
			}

		}

		ask zone parallel: true {
			avg_dis_sh <- int(children where (each.my_zone = self) mean_of (each.distance_to_school));
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
	path school_route;
	path my_path;
	
	
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
}


species private_garden {
	int poly_id;
	rgb color <- rgb(204, 255, 153);
	int area;
	int perimeter;
	float mvpa_prob;
	string lu_name;
	int code;

	aspect base {
		draw shape color: color;
	}

}

species schools {
	int id_catch;
	int pe_day <- rnd(4) + 1;
	rgb color <- rgb(255, 0, 127);
	float per_meeting;
	list<float> list_meeting;
	float avg_list_meeting;
	int nb_pupils;
//	float avg_my_social_status;
//	float avg_mvpa;

	aspect base {
		draw shape border: #black color: color;
//		draw string(avg_my_social_status) at: point(self) font: font('Default', 12, #bold) color: #black;
	}



}


experiment pathfinding type: gui {
	output {
	display Landuse_display {
			species road aspect: default refresh: false;
	
	}
}}