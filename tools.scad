// ==========================================================================
//
// some general-purpose stuff
//
// author :         Wouter van Ooijen
// email :          wouter@voti.nl
// last modified :  2017-10-19
//
// todo:
// - repeat4 should rotate, 2 should mirror
// - conincal screw head
// - rounding factor must be size-independent
//
// - pass ook overall size, nodig voor bv ridge
// - stop die overall size in een info, net als m3 en pcb
//
// to test:
// - LCD snap-ins 1mm higher
// - LCD horizontal exclusion -1 both sides
// 
// ==========================================================================

// same size in two or three dimensions
function dup2( x )   = [ x, x ];
function dup3( x )   = [ x, x, x ];

// take first two elements
function take2( b )  = [ b[ 0 ], b[ 1 ] ];

// add a third coordinate
function make3( a, z = 0 ) = [ a[ 0 ], a[ 1 ], z ];

// set one coordinate to 0
function zero2_x( b ) = [      0, b[ 1 ] ];
function zero2_y( b ) = [ b[ 0 ],      0 ];

function zero3_x( b ) = [      0, b[ 1 ], b[ 2] ];
function zero3_y( b ) = [ b[ 0 ],      0, b[ 2] ];
function zero3_z( b ) = [ b[ 0 ], b[ 1 ],     0 ];


// ==========================================================================
//
// circle and sphere with a configurable number of segments
//
// ==========================================================================

// can be pre-defined by the user
circle_sides = 20;

// circle with configured number of sides
// (circle_sides must have been defined)
module my_circle( d ){
   circle( d, $fn = circle_sides );
}   

module my_sphere( d ){
   sphere( d, $fn = circle_sides );
};


// ==========================================================================
//
// repeaters
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

// union of 2 copies the children, offset apart
module repeat2( offset, m = [ 0, 0, 0 ] ){
   union() {
      translate( [           0,           0 ] ) children();     
      translate( [ offset[ 0 ], offset[ 1 ] ] ) mirror( m ) children();
   }    
}

module repeat_plusmin( offset ){
   union() {
      translate(   offset ) children();
      translate( - offset ) children();
   }    
}


// ==========================================================================
//
// pole (peg) with either flat or rounded top
//
// ==========================================================================

// pole with flat top
// size = [ radius, height ]
module peg( size, fn = 10 ){
   radius = size[ 0 ];
   height = size[ 1 ];    
   union(){
      linear_extrude( height )
         my_circle( radius );
   };
}   

// pole with rounded top
// size = [ radius, height ]
module rounded_peg( size, fn = 10 ){
   radius = size[ 0 ];
   height = size[ 1 ];    
   union(){
      linear_extrude( height - radius )
         my_circle( radius );
      translate( [ 0, 0, height - radius ] )
         my_sphere( radius );
   };
}   


// ==========================================================================
//
// rounded forms for boxes
//
// ==========================================================================

// a rectangle with rounded corners
module rounded_rectangle( size, rounding = 1 ){
    x = size[ 0 ];
    y = size[ 1 ];
    r = rounding;
    union(){
       translate( [     r,     r ] ) my_circle( r );
       translate( [ x - r,     r ] ) my_circle( r );
       translate( [     r, y - r ] ) my_circle( r );
       translate( [ x - r, y - r ] ) my_circle( r );
       translate( [ 0, r ] ) square( [ x,         y - 2 * r ] );  
       translate( [ r, 0 ] ) square( [ x - 2 * r, y         ] );  
    }    
}

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

module plate( size, rounding = 0, ridges = 0 ){
   if( rounding == 0 ){
       linear_extrude( size[ 2 ] )
          square( take2( size ));       
    } else {
      difference(){
         linear_extrude( size[ 2 ] ) 
            rounded_rectangle( take2( size ), rounding );
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
         translate( [ i * (( size[ 0 ] - size[ 2 ] ) / ( ridges + 1 )), 0, size[ 2 ] ] )
            linear_extrude( size[ 2 ] )
               square( [ size[ 2 ], size[ 1 ] ] );    
         translate( [ 0, i * (( size[ 1 ] - size[ 2 ] ) / ( ridges + 1 )), size[ 2 ] ] )
            linear_extrude( size[ 2 ] )
               square( [ size[ 0 ], size[ 2 ] ] );           
      }       
   }      
}

// a rectangle with rounded corners and rounded cutout
module rounded_outline( size, rounding, thickness ){
    s = size;
    r = rounding;
    t = thickness;
    difference(){
        rounded_rectangle( s, r );
        translate( [ t, t ] ) rounded_rectangle( s - 2 * [ t, t ], r );
    }        
}

module tray( size, thickness = 1.0, rounding = 0, ridges = 0 ){
   plate( make3( size, rounding ), rounding, ridges );
   linear_extrude( size[ 2 ] )
      rounded_outline( take2( size ), rounding, thickness );
}

// ==========================================================================
//
// The add_* modules add an item to a duplex (bottom/top) casing.
//
// An item can be an interal part, or a cutout, or acombination.
//
// arguments:
//    part     = 0 for the bottom part, 1 for the top part
//    location = [ x, y, z ] origin of the item to be added
//    height   = [ lower, upper ] inner height of the two parts
//    ....     =  item specific parameters
// children    = the part the item is added to, start with a box
//
// ==========================================================================

bottom  = 0;
top     = 1;


// ==========================================================================
//
// info about a two-part case
//
// [ inner x size, 
//   inner y size,
//   bottom inner z size,
//   top inner z size,
//   (wall) thickness,
//   rounding ]
//
// When dealing with a case and modular parts in it
// [0,0,0] is the *inner* left-lower-bottom corner.
//
// ==========================================================================

function case_inner_x_size( h )         = h[ 0 ];
function case_inner_y_size( h )         = h[ 1 ];
function case_bottom_inner_z_size( h )  = h[ 2 ];
function case_top_inner_z_size( h )     = h[ 3 ];
function case_inner_x_size( h )         = h[ 4 ];
function case_thickness( h )            = h[ 5 ];
function case_rounding( h )             = h[ 6 ];

function case_part_inner_z_size( h, part ) = ( part == bottom ) 
   ? case_bottom_inner_z_size( h ) 
   : case_top_inner_z_size( h );
   
module case_tray( case, part ){
   tray( 
      [ 
         case_inner_x_size( case ), 
         case_inner_y_size ( case ), 
         case_part_inner_z_size( case, part )
      ] + dup3( case_thickness( case )),
      case_thickness( case ),
      case_rounding( case )
    );
}

module test_case_tray(){
   tray = [ 10.0, 20.0, 10.0, 5.0, 1.0, 1.0 ];
   case_tray( tray, bottom );    
}

test_case_tray();



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
// translated box
//
// ==========================================================================

// box of specified size at specified location
// argument = [ size [ x, y, z ], location [ x, y, z ] ]
module box( box ){
   translate( box[ 1 ] )
      linear_extrude( box[ 0 ][ 2 ] )
         square( [ box[ 0 ][ 0 ], box[ 0 ][ 1 ] ] );
}


// ==========================================================================
//
// an m-sized screw / nut 
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

function pcb_size( x )          = [ x[ 0 ], x[ 1 ] ];
function pcb_thickness( x )     = x[ 2 ];
function pcb_hole_diameter( x ) = x[ 3 ];
function pcb_hole_offset( x )   = [ x[ 4 ], x[ 5 ] ];

function pcb_hole_square( pcb ) = 
   pcb_size( pcb ) - 2 * pcb_hole_offset( pcb ); 
   
   
// ==========================================================================
//
// Add a breadboard PCB
//
// pcb        = one of the breadboard pcb_x_y's
// peg_height = height of the pegs for the pcb holes (above the pcb)
// components = height for components on the pcb
//
// ==========================================================================

module add_pcb( part, location, height, pcb, peg_height = 1.0, components = 10.0 ){
   translate( zero3_z( location ) + make3( pcb_hole_offset( pcb ) ) ){    
      repeat4( make3( pcb_hole_square( pcb ) ) ){
         if( part == bottom ){
             
		    // support and peg
	        union(){
               linear_extrude( location[ 2 ] )  
                  square( 2 * pcb_hole_offset( pcb ), center = true );
		       rounded_peg( [ 
                  pcb_hole_diameter( pcb ) / 2,
                  location[ 2 ] + pcb_thickness( pcb ) + peg_height ] );  
            }
            
         } else if( part == top ){
             
		    // holddown with hole for the peg
            holddown_height = height[ 0 ] + height[ 1 ] - pcb_thickness( pcb ) - 0.5;
            peg_depth = peg_height + 0.5; 
            difference(){
               linear_extrude( holddown_height )  
                  square( 2 * pcb_hole_offset( pcb ), center = true );
               translate( [ 0, 0, location[ 2 ] - peg_depth ] )
                  linear_extrude( peg_depth ) 
                     my_circle( pcb_bb_hole_diameter / 2 + 0.5 ); 
            }	
            
         }
      }		 
   }	  
   difference(){
      children();  
      
      // room for the PCB and components 
      if( part == bottom ){
         translate( location )          
            linear_extrude( location[ 2 ] + components )
               square( pcb_size( pcb ) );
      }       
   }    
} 

module test_add_pcb( pcb = pcb_5_7 ){
   add_pcb( bottom, [ 5.0, 5.0, 1.0 ], [ 10, 10 ], pcb )    
      plate( make3( pcb_size( pcb ) + [ 10.0, 10.0 ], 1 ), ridges = 5, rounding = 1 );    
}

//test_add_pcb();


// ==========================================================================
//
// add a slider (power) switch on the left side on a breadboard PCB
//
// pcb        = one of the breadboard pcb_x_y's
// peg_height = height of the pegs for the pcb holes (above the pcb)
// components = height for components on the pcb
//
// ==========================================================================
    
module add_pcb_slider_switch( part, location, height, pcb, shift = 0 ){
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
   location = [ 1.0, 1.0, 2.0 ];    
   height = [ 10.0, 10.0 ];
   add_pcb_slider_switch( bottom, location, height, pcb, shift )
   add_pcb( bottom, location, height, pcb )  
   tray( make3( pcb_size( pcb ) + [ 2.0, 2.0 ], height[ 0 ], 1 ), rounding = 1 );   
}

//test_add_pcb_slider_switch( pcb_7_5, 0 );


// ==========================================================================
//
// Add a blue-pill board
//
// ==========================================================================
    
module add_blue_pill( part, location, height ){
   if( part == bottom ){
      // support ridge
      linear_extrude( solder_height )
         translate( pcb_blue_origin )
            square( [ inner_size[ 0 ], 2.0 ] );       
       
   }       
   children();     
};

module test_add_blue_pill(){
   location = [ 1.0, 1.0, 2.0 ];      
   height = [ 10.0, 10.0 ];
   add_blue_pill( bottom, location, height )   
   tray( [ 100.0, 20.0, height[ 0 ] ], 1.0, rounding = 1 );    
}

//test_add_blue_pill();


// ==========================================================================
//
// Arduino Nano + switch, on a breadboard
//
// ==========================================================================
    
module add_pcb_5_7_nano( part, location, height, pcb, switch_shift = 0, peg_height = 1.0 ){
   // add_pcb_holddown( position, pcb_5_7,     
};


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
// battery holder
//
// ==========================================================================

module battery_2aaa( wall_thickness, height, text ){
   union(){
      square( [] );
   };
}  


// ==========================================================================
//
// Arduino nano on 5x7 pcb with switch cutout
//
// ==========================================================================

module battery_2aaa( location ){
   difference(){
      union(){
         square( [] );
	     children();
      };
      // switch cutout
   }   
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
module add_lcd_5510_full_cutout( part, location, height ){
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

module test_add_lcd_5510_full_cutout(){
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