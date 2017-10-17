// ==========================================================================
//
// two-part housing, containing
//    - blue-pill STM32F103C8T6 
//    - 50 x 70 sea-of-holes prototype PCB
//    - 2 x AAA battery holder
//    - slider switch
//    - two sunken m3 hex nuts + two normal M3 screws
//
// author :         Wouter van Ooijen
// email :          wouter@voti.nl
// last modified :  2017-10-14
//
// todo:
// - specify screw length -> calculate front sink
// - screw height (top recess and cutout)
// 
// - front cutouts similar to wall cutouts
// - picture of explosion
// - PCB rattles, calculate column height
// - IR hole
// - buzzer
// - 4 leds
// - round the other edges
// 
// ==========================================================================

// identification, put inside top and bootom
id_text                  = [
   "blue-pill.scad v0.01",
   "www.github.com/wovo/openscad" ]; 

// circle and ball accuracy
// this affects the rendering time a lot!
// 20 (or even 10) is enough for drafts, 40 is high-quality
circle_sides             = 10;

// gap when comonents must fit inside one another
// this depends on the printer accuracy
// 0.1 seems to be OK for the Ultimaker 2+
fitting_gap              = 0.1;

// the horizontal gap on the hotplate when multiple items are printed
hotplate_gap             = 2.0; 

include <tools.scad>;


// ==========================================================================
//
// customizable dimensions
//
// ==========================================================================

// total outsize height of housing (bottom + top)
total_height             = 18.0;

// thickness of the external walls (and floors)
// this has a big impact on printing time and material consumption!
// 1.0 is sufficient but still a bit fragile
// 1.2 is sturdier 
// 2.0 is realy stiff
wall_thickness           = 1.0;

// same as external wall is a good start, 
// but it could be a bit thinner
battery_wall             = min( wall_thickness, 1.0 );

// horizontal gap between PCB and (inner) walls
// 0.5 can give some rattling when the PCB is not secured
// 0.0 is probably too tight (I never tried)
pcb_blue_gap             = 0.2;
pcb_5x7_gap              = 0.2;
battery_gap              = 0.2;

// the screw used to fasten top to bottom
screw                    = m3();

// solder side required free height 
// = clearance between 5x7 PCB and bottom plate
// the blue pill is thinner so it will have a marginally larger clearance
// 2.5 is the minimum for the pinheader connectors
// 5.0 is required to avoid problems with the sunken nuts
solder_height           = 5.0;

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

// depth of the embossing of images
// must be (significantly) less than wall_thickness!
embossing_depth        = 0.2;


// ==========================================================================
//
// internal components dimensions and separation
//
// Don't change this unless you use different components.
//
// ==========================================================================

pcb_blue_size            = [ 53.0, 23.0 ];
pcb_blue_thickness       = 1.0;

notch_size               = [ 7.0, 6.0 ];
screw_offset             = [ 4.0, 3.0 ];

pcb_5x7_size             = [ 70.0, 50.0 ];
pcb_5x7_thickness        = 1.6;
pcb_5x7_hole_clearance   = 2.0;
pcb_5x7_hole_diameter    = 1.6;
pcb_5x7_support_size     = 2 * pcb_5x7_hole_clearance;

battery_size             = [ 51.0, 23.0 ];
battery_height           = 12.0;

magnets_diameter  = 24.5;
magnets_distance  = [ 5.0, 10.0 ];
magnets_cutout    = 0.2;


// ==========================================================================
//
// derived dimensions
//
// ==========================================================================

inner_size           = [ pcb_5x7_size[ 0 ] + 2 * pcb_5x7_gap,
                            battery_size[ 1 ] + 2 * battery_gap +
						    battery_wall +
                            pcb_blue_size[ 1 ] + 2 * pcb_blue_gap +
						    notch_size[ 1 ] + 
                            pcb_5x7_size[ 1 ] + 2 * pcb_5x7_gap ];

outer_size           = inner_size + dup2( 2 * wall_thickness ); 

// all origins are left-aligned against the inner wall
inner_origin         = dup2( wall_thickness );

battery_origin       = inner_origin + [ 0, 
                            battery_gap ];

battery_wall_origin  = battery_origin + [ 0, 
                            battery_size[ 1 ] + battery_gap ];

pcb_blue_origin      = battery_wall_origin + [ 0,
                            battery_wall + pcb_blue_gap ];

notch_origin         = pcb_blue_origin + [ 0,
                            pcb_blue_size[ 1 ] + pcb_blue_gap ];

screw_origin         = notch_origin + screw_offset;						

screw_to_side        = screw_offset[ 0 ];

pcb_5x7_origin       = notch_origin + [ 0,
                            notch_size[ 1 ] + pcb_5x7_gap ];

bottom_height        = wall_thickness
                          + solder_height
                          + pcb_blue_thickness
                          + 2.5; // for the programming hole
top_height           = total_height - bottom_height;

support_height       = wall_thickness + solder_height;
pin_height           = support_height + pcb_5x7_thickness + 2.0; 
pin_square           = pcb_5x7_size - dup2( 2 * pcb_5x7_hole_clearance ); 
hold_down_height     = total_height 
                          - 2 * wall_thickness 
                          - pcb_5x7_thickness;


// ==========================================================================
//
// basic plate and walls
//
// ==========================================================================

module blue_base( height ){
    
   difference(){
       union(){    
    
         // plate bottom    
         linear_extrude( wall_thickness )
            rounded_rectangle( outer_size, 
               rounding_factor * wall_thickness );
   
         // side walls    
         linear_extrude( height ) 
            difference() {
               rounded_rectangle( outer_size, 
                  rounding_factor * wall_thickness );
               translate( inner_origin ) 
                  square( inner_size );  
         };    
   
         // battery wall
         linear_extrude( height )
            translate( battery_wall_origin ) 
               square( [ outer_size[ 0 ] - wall_thickness * 2, battery_wall ] );   
      
         // notches between the PCBs
         difference(){
            linear_extrude( height )
               repeat2( zero_y( inner_size - notch_size ))
                  translate( notch_origin )
                     square( notch_size );    
         };
         
         // sink for nut and screw
         linear_extrude( solder_height )
            repeat2( zero_y( inner_size - [ 2 * screw_to_side, 0 ] ))
               translate( screw_origin )
                  my_circle( m_nut_diameter( screw ) / 2 + wall_thickness );

         // id text
         linear_extrude( height = wall_thickness + 0.2 )
            translate( 
               [ outer_size[ 0 ] / 2, 
               ( battery_origin + battery_size / 2 )[ 1 ] ] )
                  text2( id_text );
      };         
         
      union(){
          
         // screw hole  
         linear_extrude( height )
            repeat2( zero_y( inner_size - [ 2 * screw_to_side, 0 ] ))
               translate( screw_origin )
                  my_circle( m_hole_diameter( screw )  / 2 );              
      };    
   };    
}


// ==========================================================================
//
// bottom plate
//
// ==========================================================================

module blue_bottom(){
     
   difference(){ 
      union(){
          
         // bottom and walls    
         blue_base( bottom_height );
          
         // 5x7 PCB supports and aligner pins
         union(){ 
            repeat4( pin_square )
               translate( pcb_5x7_origin )
                  linear_extrude( support_height )  
                     square( pcb_5x7_support_size ); 
            repeat4( pin_square )  
               translate( pcb_5x7_origin + dup2( pcb_5x7_hole_clearance ))
                  rounded_peg( [ pcb_5x7_hole_diameter / 2 + 2 * fitting_gap,
                     pin_height ] ); 
         };   
         
      }; 
      
      // nut recess 
      repeat2( zero_y( inner_size - [ 2 * screw_to_side, 0 ] ))
         translate( screw_origin )
            m_nut_recess( screw );  
      
      // magnet cutout
      translate( [ 
          outer_size[ 0 ] / 2, 
          outer_size[ 1 ] - magnets_diameter / 2 - magnets_distance[ 1 ], 
          wall_thickness - magnets_cutout 
      ] )
         linear_extrude( wall_thickness )
            repeat_plusmin( [ magnets_diameter / 2 + magnets_distance[ 0 ], 0 ] )
              my_circle( magnets_diameter / 2 );
      
   };       
}


// ==========================================================================
//
// top plate
//
// ==========================================================================

module blue_top(){    
     
   difference(){  
      union(){
          
         // bottom and walls    
         blue_base( top_height );
          
         // 5x7 PCB hold-downs
         difference(){ 
            linear_extrude( support_height )  
               translate( pcb_5x7_origin )
                  repeat4( pin_square )
                     square( pcb_5x7_support_size );
            translate( [ 0, 0, wall_thickness ] ) 
               linear_extrude( hold_down_height ) 
                  translate( pcb_5x7_origin + dup2( pcb_5x7_hole_clearance ))
                     repeat4( pin_square )  
                        my_circle( pcb_5x7_hole_diameter / 2 ); 
         };           
          
      };
      
      // screw-head recess 
      repeat2( zero_y( inner_size - [ 2 * screw_to_side, 0 ] ))
         translate( screw_origin )
            m_screw_recess( screw );        
      
   };       
}


// ==========================================================================
//
// both plates
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
blue_both();
	