/**
* Name: Matrix
* Based on the internal empty template. 
* Author: hyesopshin
* Tags: 
*/


model Matrix

/* Insert your model definition here */

global {
	/* File Import */
	
	file my_landuse_file      <- csv_file('../includes/Layers_glasgow/land_use_table.csv',',',true);
	matrix data <- matrix(my_landuse_file);
	
	list<list<unknown>> var0 <- columns_list(data);
	
	
	init{
		
		write var0[1];
		write var0[2];
	}
	
}




experiment showmatrix type: gui {
	output {
	}
}