// ==========================================
// Bathroom Hook Holder - Through-Hole Variant
// ==========================================
//
// Problem:  small adhesive area -> hook detaches from tile
// Solution: large stadium-shaped base plate with:
//           - circular THROUGH-HOLE -> hook post passes through adapter
//           - retention lip         -> holds disc against peel force
//
// Orientation: Y = up/down, X = left/right, Z = thickness (into wall)
// Hole at BOTTOM of stadium -> adhesive above has maximum lever arm
//
// Print: flat on bed, hole opening facing up (Z+)
// Mount: flat back glued to tile
// Disc insertion: insert hook post through hole from back
// ==========================================

/* [Hook disc] */
disc_d = 50;   // Disc diameter [mm]
disc_h = 6;    // Disc thickness [mm] (disc will protrude ~1.5 mm from adapter face)

/* [Base plate shape] */
base_r     = 32;     // Semicircle radius [mm]
base_len   = 45;     // Straight section length between semicircle centres [mm]
base_thick = 6;      // Full thickness at hole (matches disc) [mm]
top_thick  = 3.5;    // Reduced thickness at top (adhesive area only) [mm]

/* [Through-hole] */
hole_clr  = 0.4;  // Hole clearance [mm]
hole_d    = disc_d + 2 * hole_clr;  // Hole diameter [mm]

/* [Retention lip] */
// The lip is a 120 deg arc ring (centred on +Y = top of disc opening).
// 120 deg leaves 30 deg free on each side for easy tilt-in insertion.
//
// Cross-section (r-z plane, local z=0 = adapter front face):
//
//  ri     ro         ro+fw
//  |       |             |
//  | inner |             |
//  | face  |             | <- flange: lies flat on adapter face (large contact area)
//  |       |             |
//  z=lp    z=lp          z=fh  <- slope from here up to lip outer top
//  |       \            /
//  |        \          /  <- outer sloped face (natural easing / no sharp edge)
//  |         \        /
//  |          +------+
//  z=0                        adapter front face (solid beyond ro)
//
// ri = pocket_d/2 - lip_w   inner radius: lip OVERHANGS DISC by (lip_w - pocket_clr)
// ro = pocket_d/2            outer radius: at pocket wall
// Flange (ro..ro+fw): lies ON the adapter face -> large contact surface for printer
// Slope from [ro+fw, fh] to [ro, lp]: smooth outer transition, no sharp edge
//
// Inner face (ri): SQUARE - disc slides against this when inserting/removing
// Inner top (lp): SQUARE - retains disc against pull-out
lip_w        = 4;     // Radial overhang of lip over disc edge [mm]
lip_protrude = 3;     // Height of lip above adapter face [mm]
                      //   must be > (disc_h - pocket_dep) to capture disc
lip_flange_w = 8;     // Flange width extending OVER adapter face [mm]
                      //   larger = more contact area with adapter, stronger print bond
lip_flange_h = 1.2;   // Flange thickness / height of slope start [mm]
                      //   slope runs from [ro+fw, fh] diagonally to [ro, lp]
lip_fillet   = 1.5;   // Fillet radius on outer slope corners [mm]

/* [Render] */
$fn = 128;

// === Derived ===
total_thick = base_thick;  // Full thickness at hole area
hole_y      = -base_len / 2;

_lip_capture = lip_w - hole_clr;
echo(str("Overall: ", 2*base_r, " x ", 2*base_r+base_len, " x ", base_thick, " (hole) / ", top_thick, " (top) mm"));
echo(str("Hole dia: ", hole_d, " mm  |  wall: ", base_r - hole_d/2, " mm"));
echo(str("Radial disc capture: ", _lip_capture, " mm/side"));

// === Modules ===

module stadium(r, len, h) {
    hull() {
        translate([0,  len/2, 0]) cylinder(r=r, h=h);
        translate([0, -len/2, 0]) cylinder(r=r, h=h);
    }
}

module through_hole() {
    translate([0, hole_y, -0.01])
        cylinder(d=hole_d, h=total_thick + 0.02);
}

// Retention lip - single rotate_extrude polygon, 120 deg arc centred on +Y.
//
// One polygon covers everything: inner face (square), top (square),
// outer slope, flange, bottom.  No separate pieces needed.
//
// Polygon vertices (CCW in r-z plane):
//   [ri,    0  ]  inner bottom - flush with adapter face, SQUARE
//   [ro+fw, 0  ]  outer bottom of flange (sits on adapter face)
//   [ro+fw, fh ]  outer top of flange
//   [ro,    lp ]  outer top of main lip  <- slope from [ro+fw,fh] to here
//   [ri,    lp ]  inner top              <- SQUARE (disc retention face)
//
// Cubic Bézier curve: B(t) = (1-t)³·P0 + 3(1-t)²t·P1 + 3(1-t)t²·P2 + t³·P3
// P0 = start point, P1 = first control point, P2 = second control point, P3 = end point
// n = number of segments
function bezier_curve(P0, P1, P2, P3, n=16) =
    [for (i = [0:n])
        let(
            t = i / n,
            t1 = 1 - t,
            b0 = t1 * t1 * t1,
            b1 = 3 * t1 * t1 * t,
            b2 = 3 * t1 * t * t,
            b3 = t * t * t
        )
        b0 * P0 + b1 * P1 + b2 * P2 + b3 * P3
    ];

module retention_lip() {
    ri = hole_d/2 - lip_w;
    ro = hole_d/2;
    lp = lip_protrude;
    fw = lip_flange_w;
    fh = lip_flange_h;

    // Trójkątny profil w przestrzeni [r, z]:
    // Lewy dolny:  [ri, 0]
    // Lewy górny:  [ri, lp]
    // Prawy dolny: [ro+fw, 0]
    //
    // Krzywa Béziera zastępuje bok od [ri, lp] do [ro+fw, 0]
    //
    // Mapowanie z Twojego przykładu [0,10]→[15,10]→[15,0]→[20,0]:
    // [0, 10]  → [ri, lp]        start (lewy górny)
    // [15, 10] → [ri + 0.75*(ro+fw-ri), lp]   kontrolny 1 (wysoko, 75% w prawo)
    // [15, 0]  → [ri + 0.75*(ro+fw-ri), 0]    kontrolny 2 (nisko, 75% w prawo)
    // [20, 0]  → [ro+fw, 0]      koniec (prawy dolny)

    P0 = [ri, lp];                              // start
    P1 = [ri + 0.75*(ro+fw-ri), lp];           // kontrolny 1 (wysoko)
    P2 = [ri + 0.75*(ro+fw-ri), 0];            // kontrolny 2 (nisko)
    P3 = [ro+fw, 0];                            // koniec

    ski_jump = bezier_curve(P0, P1, P2, P3, n=20);

    profile = concat(
        [[ri, 0]],          // left bottom - vertical edge
        [[ro+fw, 0]],       // right bottom
        ski_jump,           // Bézier ski-jump curve (diagonal replacement)
        [[ri, lp]]          // left top - closes shape
    );

    translate([0, hole_y, total_thick])
        rotate([0, 0, 30])
            rotate_extrude(angle = 120, $fn = $fn)
                polygon(profile);
}

// === Front taper (upper section) ===
// Ramps from full thickness at hole top edge down to top_thick at adapter top.
// Saves material where it's just adhesive surface anyway.
module front_taper() {
    ramp_y0 = hole_y + hole_d/2 + lip_flange_w + 1;  // above lip flange + margin
    ramp_y1 = base_len/2 + base_r + 1;       // top of stadium + margin
    w       = 2 * base_r + 2;

    translate([-(base_r + 1), 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = w)
                polygon([
                    [ramp_y0, total_thick + 0.01],
                    [ramp_y1, total_thick + 0.01],
                    [ramp_y1, top_thick],
                ]);
}

// === Test disc (transparent) ===
// Disc in mounted position - flush with adapter, held by lip
module test_disc() {
    translate([0, hole_y, 0])
        cylinder(d=disc_d, h=disc_h);
}

// === Assembly ===
union() {
    difference() {
        stadium(base_r, base_len, total_thick);
        through_hole();
        front_taper();
    }
    retention_lip();
}

// Show disc as transparent overlay to check for intersections
%test_disc();
