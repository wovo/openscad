// ==========================================================================
//
// author         : Wouter van Ooijen
// email          : wouter@voti.nl
// last modified  : 2017-10-29
// license        : CC BY-NC 4.0 
//                  https://creativecommons.org/licenses/by-nc/4.0
//                  https://creativecommons.org/licenses/by-nc/4.0/legalcode
//
// This is a modular OpenSCAD library for piecing together rectangular 
// two-part (top-bottom) casings (boxes) 
// for small micro-controller projects.
//
// Developed with Ultimaker 2+ using PLA, Cura, slow speed.
//
// Supported elements:
//    - rectangular top/bottom case, can be rounded at the edges
//    - recessed M3 screw/nut
//    - 2 x AAA battery pack
//    - blue-pill STM32 board, optional cutouts (prog, USB, reset)
//    - breadboard PCBs 70x50, 70x30, 60x40
//    - slider switch
//    - Nokia 5510 84x48 b/w LCD
//    - small 128x64 OLED 
//    - engraved text
// 
// todo:
// - repeat4 should rotate
// - conincal screw head
// - rounding factor must be size-independent
// - corner alignment pegs
// - snap pegs for the top/bottom
// - mirror the top (finish() ??)
// - battery holddowns
// - use https://creativecommons.org/licenses/by-nc-sa/3.0/ ?
// - write and test blue-pill cutouts
// - hight calculations & warnings
// - standoff tool for soldering the lcd and oled
// - smaller case with CR battery
// - 5510
// - oled
// - current example has outside of the screw head
// - test_tray()
// - y value for 'please align'
//
// to test:
// - LCD snap-ins 1mm higher
// - LCD horizontal exclusion -1 both sides
// 
// ==========================================================================

version  = "0.5";
www      = "github: wovo/openscad";


// ==========================================================================
//
// Utility functions for fiddeling with 2d and 3d coordinates
//
// ==========================================================================

// same figure in two or three dimensions
function dup2( x )   = [ x, x ];
function dup3( x )   = [ x, x, x ];

// take first two elements
function take2( b )  = [ b[ 0 ], b[ 1 ] ];

// add a third coordinate
function make3( a, z = 0 ) = [ a[ 0 ], a[ 1 ], z ];

// set one coordinate to 0
function zero2_x( b )  = [      0, b[ 1 ] ];
function zero2_y( b )  = [ b[ 0 ],      0 ];
function zero3_x( b )  = [      0, b[ 1 ], b[ 2] ];
function zero3_y( b )  = [ b[ 0 ],      0, b[ 2] ];
function zero3_z( b )  = [ b[ 0 ], b[ 1 ],     0 ];

// only one coordinate, rest is zero
function only2_x( b ) = [ b, 0 ];
function only2_y( b ) = [ 0, b ];
function only3_x( b ) = [ b, 0, 0 ];
function only3_y( b ) = [ 0, b, 0 ];
function only3_z( b ) = [ 0, 0, b ];

// get one or two of the components
function x( b )       = b[ 0 ];
function y( b )       = b[ 1 ];
function z( b )       = b[ 2 ];
function xy( b )      = [ b[ 0 ], b[ 1 ] ];


// ==========================================================================
//
// circle and sphere with a pre-set number of segments
//
// ==========================================================================

// can be pre-defined by the user to reduce rendering time
circle_sides = 20;

// circle with configured number of sides
module my_circle( d, sides = circle_sides ){
   circle( d, $fn = sides );
}   

// sphere with a configurable number of segments
module my_sphere( d, sides = circle_sides ){
   sphere( d, $fn = sides );
};


// ==========================================================================
//
// simple shifts
//
// ==========================================================================

module up( n ){ 
   translate( [ 0, 0, n ] ) children();
}   

module down( n ){ 
   translate( [ 0, 0, -n ] ) children();
}   

module right( n ){ 
   translate( [ n, 0, 0 ] ) children();
} 

module left( n ){ 
   translate( [ -n, 0, 0 ] ) children();
} 

module front( n ){ 
   translate( [ 0, -n, 0 ] ) children();
} 

module back( n ){ 
   translate( [ 0, n, 0 ] ) children();
} 


// ==========================================================================
//
// repeaters and the like
//
// ==========================================================================

// union of 4 copies the children 
// at the 4 corners of the argument (= [x,y] rectangle)
module repeat4( offset ){
   union() {
      translate( [           0,           0 ] ) children();
      translate( [ offset[ 0 ],           0 ] ) children();
      translate( [ offset[ 0 ], offset[ 1 ] ] ) children();
      translate( [           0, offset[ 1 ] ] ) children();
   }    
}

// union of 2 copies the children, second at offset
module repeat2( offset, m = [ 0, 0, 0 ] ){
   union() {
      translate( [           0,           0 ] ) children();     
      translate( [ offset[ 0 ], offset[ 1 ] ] ) mirror( m ) children();
   }    
}

// union of 2 copies the children, offset to left and right
module repeat_plusmin( offset, m = [ 0, 0, 0 ] ){
   union() {
      translate(   offset ) children();
      translate( - offset ) mirror( m ) children();
   }    
}   


// ==========================================================================
//
// basic forms: pegs, hold-downs, snap-ins, base-plates, trays, etc.
//
// rounding == 0 means square edges, 1 is a usable bit of rounding
//
// ==========================================================================

// a peg (pole) with either flat or rounded top
// size = [ radius, height ]
// when wall != 0, the peg is hollow with the indicated wall thickness
module peg( 
   size, 
   location = [ 0, 0, 0 ], 
   rotation = [ 0, 0, 0 ],
   rounding = 0, 
   sides    = circle_sides,
   wall     = 0
){     
   radius = size[ 0 ];
   height = size[ 1 ];    
   translate( location ){
      rotate( rotation ){ 
	     difference(){
	        union(){
               linear_extrude( height - rounding * radius )
                  my_circle( radius, sides );
               up( height - radius )
                  my_sphere( rounding * radius );
	        }
            if( wall > 0 ){
		       linear_extrude( height - rounding * radius )
                  my_circle( radius - wall, sides );	
	        }		   
         }			
      }			   
   }
}   

// a rectangle with either square or rounded corners
// size = [ x, y ]
module rectangle( size, r = 0 ){
    x = size[ 0 ];
    y = size[ 1 ];
    if( r == 0 ){
	   square( size );
	} else {
       translate( [     r,     r ] ) my_circle( r );
       translate( [ x - r,     r ] ) my_circle( r );
       translate( [     r, y - r ] ) my_circle( r );
       translate( [ x - r, y - r ] ) my_circle( r );
       translate( [ 0, r ] ) square( [ x,         y - 2 * r ] );  
       translate( [ r, 0 ] ) square( [ x - 2 * r, y         ] );  
    }    
}

// utility for plate: a gouge (rounding chisel)
module cutter_bar( size, rounding = 1 ){
    translate( [ -1000, size, size ] )
       mirror( [ 0, 1, 0 ] ) 
          rotate( [ 0, 90, 0 ] ) 
             linear_extrude( 2000 ) 
                difference(){
                   square( dup2( size ) );
                   my_circle( size );
                };
}

// base plate 
// size = [ x, y, z ]
// ridges can be added for strength or to debug keepout spaces
// the plate is just below the x,y plane, 
// for easy placement of other elements
module plate( size, rounding = 0, ridges = 0 ){
   translate( [ 0, 0, - size[ 2 ] ] ){
      if( rounding == 0 ){
         linear_extrude( size[ 2 ] )
            square( take2( size ));       
      } else {
         difference(){
            linear_extrude( size[ 2 ] ) 
               rectangle( take2( size ), rounding );
      	    cutter_bar( size[ 2 ], rounding );
	        mirror( [ 1, 0, 0 ] ) rotate( [ 0, 0, 90 ] ) 
               cutter_bar( size[ 2 ], rounding );
            translate( [ size[ 0 ], 0, 0 ] ) rotate( [ 0, 0, 90 ] ) 
               cutter_bar( size[ 2 ], rounding ); 
            translate( [ 0, size[ 1 ], 0 ] ) mirror( [ 0, 1, 0 ] ) 
               cutter_bar( size[ 2 ], rounding ); 
         };
      };
   
      // add the ridges
      if( ridges > 0 ){
         for( i = [ 1 : ridges ] ){       
            translate( [
			   i * (( size[ 0 ] - size[ 2 ] ) / ( ridges + 1 )), 
			   0, 
			   size[ 2 ] 
			] )
               linear_extrude( size[ 2 ] )
                  square( [ size[ 2 ], size[ 1 ] ] );    
            translate( [
			   0, 
			   i * (( size[ 1 ] - size[ 2 ] ) / ( ridges + 1 )), 
			   size[ 2 ] 
			] )
               linear_extrude( size[ 2 ] )
                  square( [ size[ 0 ], size[ 2 ] ] );           
         }			  
      }       
   }      
}

module test_plate(){ 
    plate( [ 30.0, 30.0, 1.0 ], 0, 0 );
}

//test_plate();

// an open rectangle (with internal cutout)
module outline( size, thickness, rounding = 0 ){
    s = size;
    r = rounding;
    t = thickness;
    difference(){
        rectangle( s, r );
        translate( [ t, t ] ) 
           rectangle( s - 2 * [ t, t ], r );
    }        
}

// tray (plate with walls)
// size = [ x, y, z ] of the base plate
// thickness is the wall thickness, can be omitted, defaults to size[ 2 ]
// the bottom plate is below the x,y plane
module tray( size, thickness = -1, rounding = 0, ridges = 0 ){
   plate( make3( size, rounding ), rounding, ridges );
   linear_extrude( size[ 2 ] )
      outline( take2( size ), 
         thickness < 0 ? size[ 2 ] : thickness, 
         rounding );
}

module test_tray(){
   tray( [ 30.0, 30.0, 1.0 ] );    
}

// test_tray();

// box of the specified size at the specified location
module box( size, location = [ 0, 0, 0 ] ){
   translate( location )
      linear_extrude( z( size ) )
         square( xy( size ) );
}


// ==========================================================================
//
// The add_* modules each add an item to a duplex (bottom/top) casing (tray).
//
// An item can be an internal part, or a cutout, or a combination.
//
// commonly used arguments:
//    case     = the case to which the part will be added
//    part     = selects the bottom or top of the case
//    location = [ x, y, z ] origin of the item to be added
//    ....     =  item specific parameters
// children    = the part the item is added to, start with a case
//
// When dealing with a case and modular parts in it
// [0,0,0] is always the *inner* left-lower-bottom corner.
//
// ==========================================================================

bottom  = 0;
top     = 1; 


// ==========================================================================
//
// tooling for a two-part case
//
// a case is specified by [ 
//   inner x size, 
//   inner y size,
//   bottom inner z size,
//   top inner z size,
//   (wall) thickness,
//   rounding ]
//
// ==========================================================================

function case_inner_x_size( h )         = h[ 0 ];
function case_inner_y_size( h )         = h[ 1 ];
function case_bottom_inner_z_size( h )  = h[ 2 ];
function case_top_inner_z_size( h )     = h[ 3 ];
function case_thickness( h )            = h[ 4 ];
function case_rounding( h )             = h[ 5 ];

function case_part_inner_z_size( h, part ) = ( part == bottom ) 
   ? case_bottom_inner_z_size( h ) 
   : case_top_inner_z_size( h );

// a tray part (bottom or top)
// [0,0,0] is the *inner* left-lower-bottom corner.   
module case_tray( case, part, ridges = 0 ){
   translate( [ - case_thickness( case ), - case_thickness( case ), 0 ] )
      tray( 
         [ 
            case_inner_x_size( case ) + 2 * case_thickness( case ), 
            case_inner_y_size ( case ) + 2 * case_thickness( case ), 
            case_part_inner_z_size( case, part )
         ], 
         case_thickness( case ),
         case_rounding( case ),
		 ridges
      );
}

module test_case_tray(){
   tray = [ 50.0, 100.0, 1.0, 5.0, 1.0, 1.0 ];
   case_tray( tray, bottom );    
}

//test_case_tray();


// ==========================================================================
//
// info for an m-sized screw / nut 
//
// [ hole diameter, 
//   screw diameter, 
//   screw height,
//   nut diameter,
//   nut height,
//   total height ]
//
// ==========================================================================

function m3( th = 20 ) = [ 3.3, 6.0, 2.0, 6.4, 2.2, th ];

function m_hole_diameter( m )   = m[ 0 ];
function m_screw_diameter( m )  = m[ 1 ];
function m_screw_height( m )    = m[ 2 ];
function m_nut_diameter( m )    = m[ 3 ];
function m_nut_height( m )      = m[ 4 ];
function m_total_height( m )    = m[ 5 ];

module m_screw_recess( m ){
   linear_extrude( m_screw_height( m )) 
      my_circle( m_screw_diameter( m ) / 2 );
};

module m_nut_recess( m ){
   linear_extrude( m_nut_height( m )) 
      // not my_circle because it is a hexagon
      circle( m_nut_diameter( m ) / 2, $fn = 6 );
};


// ==========================================================================
//
// a breadboard PCB
//
// [ 
//    pcb_x_size, 
//    pcb_y_size, 
//    pcb_thickness,
//    hole_diameter,
//    hole_offset_x,
//    hole_offset_y ]
//
// ==========================================================================

pcb_7_5 = [ 70.0, 50.0, 1.6, 1.6, 2.0, 2.0 ];
pcb_5_7 = [ 50.0, 70.0, 1.6, 1.6, 2.0, 2.0 ];
pcb_7_3 = [ 70.0, 30.0, 1.6, 1.6, 2.0, 2.0 ];
pcb_6_4 = [ 60.0, 40.0, 1.6, 1.6, 2.0, 2.0 ];

function pcb_size( x )            = [ x[ 0 ], x[ 1 ] ];
function pcb_x_size( x )          = x[ 0 ];
function pcb_y_size( x )          = x[ 1 ];
function pcb_thickness( x )       = x[ 2 ];
function pcb_hole_diameter( x )   = x[ 3 ];
function pcb_support_radius( x )  = x[ 4 ];
function pcb_hole_offset( x )     = [ x[ 4 ], x[ 5 ] ];

// center locations of the holes, relative to the bottom-left one
function pcb_hole_square( pcb ) = 
   pcb_size( pcb ) - 2 * pcb_hole_offset( pcb ); 
   
   
// ==========================================================================
//
// Add a breadboard PCB
//
// location   = lower-left-bottom corner of the pcb
// pcb        = one of the breadboard pcb_x_y's
// peg_height = height of the pegs for the pcb holes (above the pcb)
// components = height for components on the pcb
//
// ==========================================================================

function case_total_inner_z_size( h )     = h[ 2 ] + h[ 3 ];


module add_pcb( 
   case, part, location, 
   pcb, 
   peg_height = 1.0, 
   components = 10.0 
){
   translate( zero3_z( location ) + make3( pcb_hole_offset( pcb ) ) ){    
      repeat4( make3( pcb_hole_square( pcb ) ) ){
         if( part == bottom ){
             
		    // support, with alignment peg
	        union(){
               peg( [ pcb_support_radius( pcb ), location[ 2 ] ] );
		       peg( [ 
                  pcb_hole_diameter( pcb ) / 2,
                  location[ 2 ] + pcb_thickness( pcb ) + peg_height ],
                  rounding = 1 );  
            }
            
         } else if( part == top ){
             
		    // pcb holddown, with hole for the peg
            holddown_height = 
               case_total_inner_z_size( case ) - pcb_thickness( pcb ) - 0.5;
            peg_depth = peg_height + 1.0;             
            difference(){
               peg( [ pcb_support_radius( pcb ), holddown_height ] ); 
               up( holddown_height - peg_depth )
                  peg( [ pcb_hole_diameter( pcb ) / 2 + 0.5, peg_depth ] );
            }	
            
         }
      }		 
   }	  
   difference(){
      children();  
      
      // room for the PCB and components 
      if( part == bottom ){
         keepout = location[ 2 ] + components + pcb_thickness( pcb );
         translate( location - only3_z( location[ 2 ] ) )          
            linear_extrude( keepout )
               square( pcb_size( pcb ) );
      }        
   }    
} 

module test_add_pcb( part, pcb = pcb_5_7 ){
   case = [ 
      pcb_x_size( pcb ) + 10.0, pcb_y_size( pcb ) + 10.0, 
      10, 10, 
      1.0, 1.0 ];
    
   add_pcb( case, part, [ 5.0, 5.0, 2.0 ], pcb )    
   case_tray( case, part, ridges = 5 );        
}

// test_add_pcb( bottom ); left( 70.0 ) test_add_pcb( top );


// ==========================================================================
//
// add a slider (power) switch on the left side on a breadboard PCB
//
// location   = location of the pcb
// pcb        = one of the breadboard pcb_x_y's
// shift      = number of holes the switch is shifted in y direction
//
// ==========================================================================
    
module add_pcb_slider_switch( 
   part, case, location, 
   pcb, shift = 0 
){
   difference(){
      children();
      if( part == bottom ){
         translate( location + [ -10.0, 8.0 + shift * 2.54, 2.0 ] )
            linear_extrude( 6.0 ) 
               square( [ 10.0, 10.0 ] );
      }          
   }    
};

module test_add_pcb_slider_switch( pcb, shift ){
   location = [ 0.0, 0.0, 2.0 ];    
   case = [ 
      pcb_x_size( pcb ), pcb_y_size( pcb ), 
      10, 10, 
      1.0, 1.0 ];
   add_pcb_slider_switch( bottom, case, location, pcb, shift )
   add_pcb( [], bottom, location, pcb )  
   case_tray( case, bottom );
}

// test_add_pcb_slider_switch( pcb_7_5, 0 );


// ==========================================================================
//
// Add a blue-pill board 
// with a horizontal connector on the underside of the g-c13 side
//
// ==========================================================================
   
blue_pill_size = [ 55.0, 24.0 ];
    
module add_blue_pill( case, part, location ){
   if( part == bottom ){
       
      // support ridge
      box( 
         [ case_inner_x_size( case ), 3.0, z( location ) ], 
         [0, y( location ), 0 ] );
       
      // notches on both sides of the connector     
      repeat2( [ 48.0, 0.0, 0.0 ] )
         box( [ 1.0, 5.0, 5.0 ], zero3_z( location ) + [ 3.0, 25.0, 0 ] );   
   } 
   difference(){   
      children();     
      if( part == bottom ){
          
         // keepout for the PCB itself
         box( make3( blue_pill_size, 20.0 ), zero3_z( location ));
          
         // keepout for the connector       
         box( [ 48.0, 35.0, 20.0 ], zero3_z( location ) + [ 3.0, 0, 0 ] ); 
      } 
   }    
};

module test_add_blue_pill(){
   location = [ 5.0, 5.0, 2.0 ];    
   case = [ 
      65.0, 40.0, 
      5.0, 10, 
      1.0, 1.0 ];
   add_blue_pill( case, bottom, location )   
   case_tray( case, bottom, ridges = 5 );    
}

//test_add_blue_pill();


// ==========================================================================
//
// Add an 2 * aaa battery compartment
//
// location == lower_left side of the compartment
//
// ==========================================================================
    
module add_battery_compartment_2a3( case, part, location ){
   size = [ 52.0, 23.0, 13.0 ]; 
   full_size = size + dup3( 1.0 );
    
   if( part == bottom ){
       
      // walls, upper one with wire slit
      translate( [ 0, y( location ), 0 ] ) difference(){
         repeat2( [ 0, y( full_size ), 0 ] ) box( [ 
            case_inner_x_size( case ), 
            case_thickness( case ), 
            case_bottom_inner_z_size( case ) ],
            [ 0, - case_thickness( case ), 0 ] );
         box( [ 2.0, 30.0, 20.0 ], [ 3.0, 0.0, 3.0 ] );    
      };   
      
      // pegs
      translate( [
         case_inner_x_size( case ) / 2,
         y( location + full_size / 2 ),
         0
      ] )
		 repeat_plusmin( [ 10.0, 0.0 ] )
		    peg( [ 2.7 / 2, 3.0 ], rounding = 1 );
   }       

   difference(){   
      children();     
      if( part == bottom ){
          
         // keepout for the battery
         box( size, zero3_z( location ));
      } 
   }      
};

module test_add_battery_compartment_2a3( case, part, location ){
   location = [ 5.0, 10.0, 2.0 ];    
   case = [ 60.0, 40.0, 5.0, 10, 1.0, 1.0 ];
   add_battery_compartment_2a3( case, bottom, location )   
   case_tray( case, bottom, ridges = 3 );    
}

//test_add_battery_compartment_2a3();


// ==========================================================================
//
// add m-sized screw / nut holes and cutouts
//
// ==========================================================================

module add_screw( case, part, location, s, rotation = [ 0, 0, 90 ] ){
   n_sides = ( part == bottom ) 
      ? 6 : 0; 
   peg_height = ( part == bottom )
      ? case_bottom_inner_z_size( case ) : case_top_inner_z_size( case );
   recess_height = ( part == bottom ) 
      ? m_nut_height( s ) : m_screw_height( s ); 
  
   difference(){  
      union(){
         children(); 
             
         // the tube for the long part 
         peg( [ 
               case_thickness( case ) + m_hole_diameter( s ) / 2,
               peg_height
            ],
            location,
            wall = case_thickness( case ) );   
             
         // the (heagon on the bottom) part for the head/nut recess 
         peg( [ 
               case_thickness( case ) + m_nut_diameter( s ) / 2, 
               recess_height
            ],
            location,
            sides = n_sides,
            rotation = rotation );
      }    
         
      // the (heagon on the bottom) head/nut recess
      peg( 
         [ m_nut_diameter( s ) / 2, recess_height ],
         location - [ 0, 0, case_thickness( case ) ], 
         sides = n_sides,
         rotation = rotation );   
   }    
}

module test_screw( part ){
   case      = [ 50.0, 50.0, 10.0, 5.0, 1.0, 1.0 ];
     
   //add_screw( case, part, [ 10.0, 10.0, 0.0 ], m3( 20.0 ) )
   case_tray( case, part, ridges = 0 );    
}

// test_screw( bottom ); translate( [ -55.0, 0, 0 ] ) test_screw( top );


// ==========================================================================
//
// add engraved text
//
// ==========================================================================

text_size = 4.0;

module text_line( t ){
   text( 
      t, size = text_size, font = "Liberation Sans", 
      halign = "center", valign = "center", $fn = circle_sides );
}

module add_text2( case, part, location, x ){
   difference(){
      children();       
      translate( location - [ 0, 0, 0.5 ] )
      linear_extrude( 1.0 )
      translate( [ 0, - text_size ] ){
         text_line( x[ 0 ] );
	     translate( [ 0, 2 * text_size ] )
	        text_line( x[ 1 ] );
      };
  }      
} 

// ==========================================================================
//
// LCD and OLED 
//
// position = [ x, y, z ]
//    x, y = relative from lower-left corner
//    z is ignored but must be present
//
// ==========================================================================

// location == PCB corner
module add_lcd_5510_full_cutout( case, part, location ){
    
   if( part == bottom ){   
       
      // add keepout?
       
   } else if ( part == top ){
           
      // support distance squares and pegs
      translate( location + [ 2.0, 2.0, 0.0 ] )
	     repeat4( [ 40.0, 40.0 ] )
            union(){
	           peg( [ 2.5 / 2, 4.0 ], rounding = 1 );
               linear_extrude( 2 )
                  square( dup2( 4 ), center = true );
            };
            
      // snap-ins
      translate( location + [ -2.0, 20.0, 0.0 ] )            
         repeat2( [ 48.0, 0.0, 0.0 ], [ 1, 0, 0 ] )
            union(){
               linear_extrude( 6.0 )  
                  square( [ 1.5, 4 ] );                
               translate( [ 1.5, 2.0, 4.5 ] )
                  my_sphere( 1.5 ); 
            }      

      difference(){	  
          
	     children();
          
		 // frontplate cutout
   	     translate( 
             zero3_z( location ) 
             + [ 1.2, 4.2, - case_thickness( case ) ]
          )
	        linear_extrude( case_thickness( case ) )
               square( [ 40.5, 34.5 ] );          
			   
         // room for the LCD itself
	     translate( 
            zero3_z( location )  
            - [ 1.0, 1.0, 0.0 ] 
         )
	        linear_extrude( 20.0 )
               square( [ 46.0, 46.0 ] );
      };
   };      
}

module test_add_lcd_5510_full_cutout( part ){
   case      = [ 54.0, 51.0, 0.0, 1.0, 1.0, 1.0, 1.0 ];
    
   add_lcd_5510_full_cutout( case, part, [ 5.0, 3.0, 1.0 ] )
   case_tray( case, part, ridges = 3, rounding = 1 );
}    

test_add_lcd_5510_full_cutout( top );


// ==========================================================================
//
// 2aaa, blue-pill, 5x7, switch, lcd
//
// ==========================================================================
    
module test_blue_pill_one( part ){
   case      = [ 61.0, 99.0, 10.0, 5.0, 1.0, 1.0 ];
   battery   = [ 0.0, 0.0, 0.0 ];
   blue_pill = [ 2.5, 24.0, 3.0 ];
   pcb       = [ 0.0, 58.0, 3.0 ];
   screw     = m3( 20.0 );
   info      = [ str( "blue pill one v ", version ), www ];
    
   add_screw( case, part, [  3.0, 50.0, 0.0 ], screw )  
   add_screw( case, part, [ 57.0, 50.0, 0.0 ], screw )  
   add_pcb_slider_switch( part, case, pcb, pcb_6_4, 0 )  
   add_add_lcd_5510_full_cutou( case, part, [ 20.0, 40.0, 0 ] )    
   add_pcb( case, part, pcb, pcb_6_4 )    
   add_blue_pill( case, part, blue_pill ) 
   add_battery_compartment_2a3( case, part, [ 4.0, 0.0 ] )   
   add_text2( case, part, [ 30.0, 11.5, 0.0 ], info )
   case_tray( case, part, ridges = 0 );    
}

//test_blue_pill_one( bottom ); translate( [ -70.0, 0, 0 ] ) test_blue_pill_one( top );


// ==========================================================================
//
// text
//
// ==========================================================================

text_size = 4.0;

module text_line( t ){
   text( 
      t, size = text_size, font = "Liberation Sans", 
      halign = "center", valign = "center", $fn = circle_sides );
}

module text2( x ){
   union() translate( [ 0, - text_size ] ){
      text_line( x[ 0 ] );
	  translate( [ 0, 2 * text_size ] )
	     text_line( x[ 1 ] );
   };
} 


// ==========================================================================
//
// LCD and OLED cutout and supports
//
// position = [ x, y, x ]
//    x, y = relative from lower-left corner
//    z    = height == thickness of the plate
//
// ==========================================================================

// location == PCB corner
module xadd_lcd_5510_full_cutout( part, location, height ){
   if( part == bottom ){    
      // add cutout
   } else if ( part == top ){
           
      // support distance squares and pegs
      translate( location + [ 2.0, 2.0, 0.0 ] )
	     repeat4( [ 40.0, 40.0 ] )
            union(){
	           rounded_peg( [ 2.5 / 2, 4.0 ] );
               linear_extrude( 2 )
                  square( dup2( 4 ), center = true );
            };
            
      // snap-ins
      translate( location + [ -2.0, 20.0, 0.0 ] )            
         repeat2( [ 48.0, 0.0, 0.0 ], [ 1, 0, 0 ] )
            union(){
               linear_extrude( 6.0 )  
                  square( [ 1.5, 4 ] );                
               translate( [ 1.5, 2.0, 4.5 ] )
                  my_sphere( 1.5 ); 
            }      

      difference(){	  
          
	     children();
          
		 // frontplate cutout
   	     translate( zero3_z( location + [ 1.2, 4.2, 0 ] ))
	        linear_extrude( location[ 2 ] )
               square( [ 40.5, 34.5 ] );          
			   
         // room for the LCD itself
	     translate( location - [ 1.0, 1.0, 0.0 ] )
	        linear_extrude( 20.0 )
               square( [ 46.0, 46.0 ] );
      };
   };      
}

module xtest_add_lcd_5510_full_cutout(){
   add_lcd_5510_full_cutout( top, [ 5.0, 3.0, 1.0 ], [ 0.0, 0.0 ] )
      plate( [ 54, 51, 1 ], ridges = 5, rounding = 1 );
}    

//test_add_lcd_5510_full_cutout();

module lcd_5510_full_cutout( position ){
   union(){
   
      // support distance squares and pegs
      translate( position + [ 2.0, 2.0, 0.0 ] )
	     repeat4( [ 40.0, 40.0 ] )
            union(){
	           rounded_peg( [ 2.5 / 2, 4.0 ] );
               linear_extrude( 2 )
                  square( dup2( 4 ), center = true );
            };

      difference(){	  
	  
	     // the base plate 
	     children();
		 
		 // the cutout of the baseplate
   	     translate( zero3_z( position + [ 1.0, 4.5, 0 ] ))
	        linear_extrude( position[ 2 ] )
               square( [ 42.0, 35.0 ] );
			   
         // room for the LCD itself
	     translate( position - [ 1.0, 0.0, 0.0 ] )
	        linear_extrude( 30.0 )
               square( [ 46.0, 43.0 ] );
      };
   };      
}

module oled_128_64_glass_cutout( position ){
   difference(){
      union(){
         children();
         translate( position + [ 2.0, 2.0 ] )
	        repeat4( [ 22.5, 23.0 ] )
               union(){
	              rounded_peg( [ 3.0 / 2, 5.0 ] );
                  linear_extrude( 2 )
                     square( [ 4.0, 4.0 ], center = true );
               };
      };
	  translate( position + [ 0.0, 4.0, -10 ] )
	     linear_extrude( 20 )
            square( [ 26.5, 15.0 ] );
   };			
}

// ==========================================================================
//
// logo's
//
// ==========================================================================

// HU-logo
module add_logo_hu(){
   union(){
      translate( [  0,  2, 0 ] ) square( [ 5, 29 ] );
      translate( [ 10,  2, 0 ] ) square( [ 5, 12 ] );
      translate( [ 10, 19, 0 ] ) square( [ 5, 12 ] );
      translate( [ 20, 16, 0 ] ) square( [ 5, 15 ] );
      translate( [ 30, 16, 0 ] ) square( [ 5, 15 ] );
      translate( [ 27.5, 16, 0 ] ) difference(){
         my_circle( 15 / 2 );
         my_circle( 5 / 2 );
         translate( [ - 10, 0, 0 ] ) square( [ 20, 15 ] );        
      } 
   };
}


// ==========================================================================
//
// test
//
// ==========================================================================
//add_pcb( bottom, [ 5.0, 5.0, 5.0 ], [ 3, 3 ], pcb_7_5 )
//add_pcb( top,    [ -50.0, 5.0, 4.0 ], [ 3, 3 ], pcb_7_5 )


// text2( [ "hello", "world" ] );
// hu_logo();
// rounded_peg( [ 5, 10 ] );
// cutter_bar( 1, 1 );
// rounded_plate( [ 10, 20 ], 1, 1 );
// lcd_5510_full_cutout( dup3( 1 )) rounded_plate( dup2( 80 ), 1.0 );