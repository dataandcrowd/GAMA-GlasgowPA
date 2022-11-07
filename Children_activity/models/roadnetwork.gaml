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
	file road_shape_file <- file('../includes/Layers_glasgow/' + scale + '/Road_' + scale + '.shp');
	geometry shape <- envelope(road_shape_file);
	graph road_network;
	
	init{
		create road from: road_shape_file;
	}
	
	action create_layers {
		
		road_network <- as_edge_graph(list(road)); 
		road_network <- road_network with_shortestpath_algorithm AStar;
	}
}

species road {
	float speed_coef;
	aspect default {
		draw shape color: #black;
	}

}

experiment pathfinding type: gui {
	output {
	display Landuse_display {
			species road aspect: default refresh: false;
	
	}
}}