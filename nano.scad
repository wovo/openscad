// ==========================================================================
//
// two-part housing, containing
//    - arduino nano, on a
//    - 50 x 70 sea-of-holes prototype PCB
//    - 2 x AAA battery holder
//    - slider switch
//    - four sunken m3 hex nuts + two normal M3 screws
//
// author         :  Wouter van Ooijen
// email          :  wouter@voti.nl
// last modified  :  2017-10-25
//
// todo:
// - something
// 
// ==========================================================================

// identification, put inside top and bottom
id_text                  = [
   "nano.scad v 0.1",
   "github: wovo/openscad" ]; 

// circle and ball accuracy
// this affects the rendering time a lot!
// 20 (or even 10) is enough for drafts, 40 is high-quality
circle_sides             = 40;

// the horizontal gap on the hotplate when multiple items are printed
hotplate_gap             = 2.0; 

include <tools.scad>;


// ==========================================================================
//
// customizable dimensions
//
// ==========================================================================

// total outsize height of housing (bottom + top)
total_height             = 22.0;

// thickness of the external walls (and floors)
// this has a big impact on printing time and material consumption!
// 0.6 is fragile and flimsy, but still doable for tryouts
// 1.0 is still a bit fragile
// 1.2 is sturdier 
// 2.0 is realy stiff
wall_thickness           = 1.0;

// same as external wall is a good start, 
// but it could be a bit thinner
// 0.4 is not printed in the Ultimaker 2+ default settings, 0.6 is
battery_wall             = min( wall_thickness, 0.6 );

// the screw used to fasten top to bottom
screws                   = m3( 20.0 );

// the breadboard
// tested with pcb_7_5, pcb_7_3, and pcb_6_4
breadboard               = pcb_5_7;

// solder side required free height 
// = clearance between breadboard PCB and bottom plate
// 2.5 is the minimum for the pinheader connectors
// 3.5 is required to avoid problems with the sunken nuts
solder_height           = 3.5;

// diameter of the align notches in the corners
aligner_diameter        = 2.0;

// distance between the aligner and the other half of the case
// 0.0 will give a very tight fit, maybe suitable for use without screws
// 0.1 gives some room for misalignment and print errors
aligner_gap             = 0.1;

// height of the aligner notches above the walls
aligner_height          = 3.0;

// amount of rounding of the edges
// 0.0 gives square edges
// 1.0 gives minimal rounding
// 1.5 is a good compromise
// 2.0 is possible, the edge is about half the wall thickness
// 3.0 leaves the edges almost unconnected
rounding_factor         = 1.0;

// engraving depth of the texts
// 0.4 is not visible on Ultimaker 2+ default settings
text_engraving          = 0.5;


// ==========================================================================
//
// internal components dimensions and separation
//
// Don't change this unless you use different components.
//
// ==========================================================================

pcb_blue_size            = [ 53.0, 23.0 ];
pcb_blue_thickness       = 1.0;

notch_size               = [ 7.0, 7.0 ];
screw_offset             = [ 3.2, 3.5 ];

pcb_bb_size              = pcb_size( breadboard );
pcb_bb_thickness         = pcb_thickness( breadboard );
pcb_bb_hole_clearance    = pcb_hole_offset( breadboard )[ 0 ];
pcb_bb_hole_diameter     = pcb_hole_diameter( breadboard );
pcb_bb_support_size      = 2 * pcb_bb_hole_clearance;

battery_size             = [ 51.0, 24.5 ];
battery_height           = 12.0;
battery_wires_gap        = [ 2.0, battery_wall, 6.0 ];

magnets_diameter         = 20.0;
magnets_distance         = [ 5.0, 10.0 ];
magnets_cutout           = 0.4;


// ==========================================================================
//
// derived dimensions
//
// ==========================================================================

inner_size           = [ pcb_bb_size[ 0 ] + 2 * pcb_bb_gap,
                            battery_size[ 1 ] + 2 * battery_gap +
						    battery_wall +
                            pcb_blue_size[ 1 ] + 2 * pcb_blue_gap +
						    notch_size[ 1 ] + 
                            pcb_bb_size[ 1 ] + 2 * pcb_bb_gap ];

outer_size           = inner_size + dup2( 2 * wall_thickness ); 

bottom_height        = wall_thickness
                          + solder_height
                          + pcb_blue_thickness
                          + 2.5 // for the switch cutout
						  + 4.0;
                          
top_height           = total_height - bottom_height;

// all origins are left-aligned against the inner wall
inner_origin         = dup2( wall_thickness );

battery_origin       = inner_origin + [ 0, 
                            battery_gap ];

battery_wall_origin  = battery_origin + [ 0, 
                            battery_size[ 1 ] + battery_gap ];
                            
battery_wires_cutout  = [ battery_wires_gap, make3( battery_wall_origin )
                        + [ 3, 0, 
                           bottom_height + wall_thickness 
                              - battery_wires_gap[ 2 ] ] ];

pcb_blue_origin      = battery_wall_origin + [ 0,
                            battery_wall + pcb_blue_gap ];

notch_origin         = pcb_blue_origin + [ 0,
                            pcb_blue_size[ 1 ] + pcb_blue_gap ];

screw_origin         = notch_origin + screw_offset;

screw_to_side        = screw_offset[ 0 ];

pcb_bb_origin        = notch_origin + [ 0,
                            notch_size[ 1 ] + pcb_bb_gap ];
                            
power_switch_cutout  = [ [ wall_thickness, 8.0, 3.5 ], 
                         make3( zero2_x( pcb_bb_origin ))
                            + [ 0, 10, 7.5 ]];

support_height       = wall_thickness + solder_height;
pin_height           = support_height + pcb_bb_thickness + 2.0; 
pin_square           = pcb_bb_size - dup2( 2 * pcb_bb_hole_clearance ); 
hold_down_height     = total_height
                          - 2 * wall_thickness 
                          - support_height
                          - pcb_bb_thickness;


// ==========================================================================
//
// basic plate and walls
//
// ==========================================================================

module blue_base( height ){
    
   difference(){
       union(){    
    
         // plate bottom    
         // linear_extrude( wall_thickness ) 
            rounded_plate( outer_size, wall_thickness, rounding_factor );
   
         // side walls    
         translate( [ 0, 0, wall_thickness ] ) 
            linear_extrude( height - wall_thickness ) 
               difference() {
                  rounded_rectangle( outer_size, wall_thickness, rounding_factor );
                  translate( inner_origin ) square( inner_size );  
               }; 
   
         // battery wall
         linear_extrude( height )
            translate( battery_wall_origin ) 
               square( [ outer_size[ 0 ] 
			      - wall_thickness * 2, battery_wall ] );
      
         // notches between the PCBs
         difference(){
            linear_extrude( height )
               repeat2( zero2_y( inner_size - notch_size ))
                  translate( notch_origin )
                     square( notch_size );    
         };
         
         // sink for nut and screw
         linear_extrude( solder_height )
            repeat2( zero2_y( inner_size - [ 2 * screw_to_side, 0 ] ))
               translate( screw_origin )
                  my_circle( m_nut_diameter( screw ) / 2 
				     + wall_thickness );

         // id text embossed
         translate( 
            [ outer_size[ 0 ] / 2, 
            ( battery_origin + battery_size / 2 )[ 1 ],
            wall_thickness ] 
         )
            linear_extrude( text_engraving )
               text2( id_text );
      };         
         
      union(){
          
         // screw hole  
         linear_extrude( height )
            repeat2( zero2_y( inner_size - [ 2 * screw_to_side, 0 ] ))
               translate( screw_origin )
                  my_circle( m_hole_diameter( screw )  / 2 );   
          
         // id text engraved
         *translate( 
            [ outer_size[ 0 ] / 2, 
            ( battery_origin + battery_size / 2 )[ 1 ],
            wall_thickness - text_engraving ] 
         )
            linear_extrude( text_engraving )
               text2( id_text );
      };    
   };    
}


// ==========================================================================
//
// bottom plate
//
// ==========================================================================

module cutout( position, size ){
   difference(){ 
      children();
      translate( position )
         linear_extrude( size[ 2 ] )
            square( [ size[ 0 ], size[ 1 ] ] );
   };    
}

module blue_bottom(){
    
   // programming connector 
   cutout( [ outer_size[ 0 ] - wall_thickness, wall_thickness + 31.5, 2.8 ], [ wall_thickness, 11.0, 5.0 ] )    
     
   difference(){ 
      union(){
          
         // bottom and walls    
         blue_base( bottom_height );
          
         // bb PCB supports and aligner pins
         union(){ 
            repeat4( pin_square )
               translate( pcb_bb_origin )
                  linear_extrude( support_height )  
                     square( pcb_bb_support_size ); 
            repeat4( pin_square )  
               translate( 
			      pcb_bb_origin + dup2( pcb_bb_hole_clearance )
			   )
                  rounded_peg( [ 
                     pcb_bb_hole_diameter / 2,
                     pin_height ] ); 
         };
         
         // blue pill support ridge
         linear_extrude( solder_height )
            translate( pcb_blue_origin )
               square( [ inner_size[ 0 ], 2.0 ] );
		 
		 // battery holder fixation pins
		 translate( [
            ( outer_size / 2 )[ 0 ],
            ( battery_origin + battery_size / 2 )[ 1 ]
         ] )
		    repeat_plusmin( [ 10.0, 0.0 ] )
		       rounded_peg( [ 2.7 / 2, 3.0 ] );
         
      }; 
      
      // nut recess 
      repeat2( zero2_y( inner_size - [ 2 * screw_to_side, 0 ] ))
         translate( screw_origin )
		    rotate( [ 0, 0, 90 ] )
               m_nut_recess( screw );  
      
      // magnet cutout
      translate( [ 
          outer_size[ 0 ] / 2, 
          outer_size[ 1 ] - magnets_diameter / 2 - magnets_distance[ 1 ], 
          wall_thickness - magnets_cutout 
      ] )
         linear_extrude( wall_thickness )
            repeat_plusmin( 
			   [ magnets_diameter / 2 + magnets_distance[ 0 ], 0 ] 
			)
               my_circle( magnets_diameter / 2 );

      // cut-outs  
      box( battery_wires_cutout ); 
      box( power_switch_cutout );      

   };
}


// ==========================================================================
//
// top plate
//
// ==========================================================================

module repeat( n, step ){
   for( i = [ 0 : n - 1 ] )
      translate( i * step )       
         children();    
}

module hole_row( position, n, step, diameter ){
   difference(){
      children();
      translate( position )
         linear_extrude( wall_thickness )
            repeat( n, step )
               my_circle( diameter / 2 );
   };       
}

module blue_top(){  

   // requires inner_height ~= 20.0
   lcd_5510_full_cutout( [ 9.4, 24.4, wall_thickness ] )  
    
   // 7 LEDs
   // hole_row( [ 6.1, 77.4 ],  7,  [ 7.68, 0 ], 5.5 )
     
   difference(){  
      union(){
          
         // bottom and walls    
         blue_base( top_height );
          
         // bb PCB hold-downs 
         difference(){ 
            linear_extrude( wall_thickness + hold_down_height )  
               translate( pcb_bb_origin )
                  repeat4( pin_square )
                     square( pcb_bb_support_size );
            translate( [ 0, 0, wall_thickness ] ) 
               linear_extrude( hold_down_height ) 
                  translate( pcb_bb_origin + dup2( pcb_bb_hole_clearance ))
                     repeat4( pin_square )  
                        my_circle( pcb_bb_hole_diameter / 2 + 0.5 ); 
         };           
      };

      // screw-head recess 
      repeat2( zero2_y( inner_size - [ 2 * screw_to_side, 0 ] ))
         translate( screw_origin )
            m_screw_recess( screw ); 
   };
}


// ==========================================================================
//
// both plates at once
//
// ==========================================================================

module blue_both(){
   union(){
      blue_top();
      translate( [ - outer_size[ 0 ] - hotplate_gap, 0, 0 ] ) 
	     blue_bottom();
   };	  
}

// test
// blue_bottom();
// blue_top();
blue_both();

	