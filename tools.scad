// ==========================================================================
//
// some general-purpose stuff
//
// author :         Wouter van Ooijen
// email :          wouter@voti.nl
// last modified :  2017-10-14
//
// todo:
// - repeat4 should rotate, 2 should mirror
// - screw recess, conincal screw head
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
function zero_x( b ) = [      0, b[ 1 ] ];
function zero_y( b ) = [ b[ 0 ],      0 ];

// circle with configured number of sides
// (circle_sides must have been defined)
module my_circle( d ){
   circle( d, $fn = circle_sides );
}   

module my_sphere( d ){
   sphere( d, $fn = circle_sides );
};

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
module repeat2( offset ){
   union() {
      translate( [           0,           0 ] ) children();
      translate( [ offset[ 0 ], offset[ 1 ] ] ) children();
   }    
}

module repeat_plusmin( offset ){
   union() {
      translate(   offset ) children();
      translate( - offset ) children();
   }    
}

// a rectangle with rounded corners
module rounded_rectangle( size, rounding ){
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

// HU-logo
module hu_logo(){
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

// box of specified size at specified location
// argument = [ size [ x, y, z ], location [ x, y, z ] ]
module box( box ){
   translate( box[ 1 ] )
      linear_extrude( box[ 0 ][ 2 ] )
         square( [ box[ 0 ][ 0 ], box[ 0 ][ 1 ] ] );
}


// ==========================================================================
//
// m-sized screw / nut 
//
// [ hole_diameter, 
//   screw_diameter, 
//   screw_height,
//   nut_diameter,
//   nut_height,
//   total_height ]
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
// text
//
// ==========================================================================

version_size = 2;

module text_line( t ){
   text( 
      t, size = version_size, font = "Liberation Sans", 
      halign = "center", valign = "center", $fn = circle_sides );
}

module text2( x ){
   union() translate( [ 0, - version_size ] ){
      text_line( x[ 0 ] );
	  translate( [ 0, 2 * version_size ] )
	     text_line( x[ 1 ] );
   };
}


// ==========================================================================
//
// test
//
// ==========================================================================

// hu_logo();
// rounded_peg( [ 5, 10 ] );