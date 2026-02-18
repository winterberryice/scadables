// ==========================================
// Bathroom Hook Holder - Adapter Base Plate
// ==========================================
//
// Problem:  small adhesive area -> hook detaches from tile
// Solution: large stadium-shaped base plate with:
//           - circular pocket  -> locates the hook disc (no glue)
//           - retention lip    -> holds disc against peel force
//
// Orientation: Y = up/down, X = left/right, Z = thickness (into wall)
// Pocket at BOTTOM of stadium -> adhesive above has maximum lever arm
//
// Print: flat on bed, pocket opening facing up (Z+)
// Mount: flat back glued to tile
// Disc insertion: tilt disc (bottom edge in first), rotate flat -
//                 top edge slides under lip and is retained
// Disc removal:   push bottom edge in to tilt disc, top pops out
// ==========================================

/* [Hook disc] */
disc_d = 50;   // Disc diameter [mm]
disc_h = 6;    // Disc thickness [mm] (disc will protrude ~1.5 mm from adapter face)

/* [Base plate shape] */
base_r     = 32;   // Semicircle radius [mm]
base_len   = 45;   // Straight section length between semicircle centres [mm]
base_thick = 3.5;  // Back wall thickness (against tile) [mm]

/* [Locating pocket] */
pocket_clr  = 0.4;  // Pocket clearance [mm]
pocket_dep  = 4.5;  // Pocket depth [mm]

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
lip_w        = 2.5;   // Radial overhang of lip over disc edge [mm]
lip_protrude = 2.5;   // Height of lip above adapter face [mm]
                      //   must be > (disc_h - pocket_dep) = 1.5 mm to capture disc
lip_flange_w = 3.5;   // Flange width extending OVER adapter face [mm]
                      //   larger = more contact area with adapter, stronger print bond
lip_flange_h = 1.2;   // Flange thickness / height of slope start [mm]
                      //   slope runs from [ro+fw, fh] diagonally to [ro, lp]

/* [Render] */
$fn = 128;

// === Derived ===
pocket_d    = disc_d + 2 * pocket_clr;
total_thick = base_thick + pocket_dep;
pocket_y    = -base_len / 2;

_disc_prot   = disc_h - pocket_dep;
_lip_capture = lip_w - pocket_clr;
echo(str("Overall: ", 2*base_r, " x ", 2*base_r+base_len, " x ", total_thick, " mm"));
echo(str("Pocket dia: ", pocket_d, " mm  |  wall: ", base_r - pocket_d/2, " mm"));
echo(str("Disc protrusion: ", _disc_prot, " mm  |  Lip protrusion: ", lip_protrude,
         " mm  |  Axial overlap: ", lip_protrude - _disc_prot, " mm"));
echo(str("Radial disc capture: ", _lip_capture, " mm/side"));

// === Modules ===

module stadium(r, len, h) {
    hull() {
        translate([0,  len/2, 0]) cylinder(r=r, h=h);
        translate([0, -len/2, 0]) cylinder(r=r, h=h);
    }
}

module pocket() {
    translate([0, pocket_y, base_thick])
        cylinder(d=pocket_d, h=pocket_dep + 0.01);
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
module retention_lip() {
    ri = pocket_d/2 - lip_w;
    ro = pocket_d/2;
    lp = lip_protrude;
    fw = lip_flange_w;
    fh = lip_flange_h;

    translate([0, pocket_y, total_thick])
        rotate([0, 0, 30])          // centres 120 deg arc on +Y
            rotate_extrude(angle = 120, $fn = $fn)
                polygon([
                    [ri,    0 ],    // inner bottom: SQUARE, flush with adapter face
                                    //   disc contact starts here
                    [ro+fw, 0 ],    // flange outer bottom: sits ON adapter face
                                    //   -> large contact surface for the printer
                    [ro+fw, fh],    // flange outer top: start of slope
                    [ro,    lp],    // outer lip top: slope ends here
                                    //   smooth diagonal = natural easing
                    [ri,    lp],    // inner top: SQUARE, retains disc
                ]);
}

// === Assembly ===
union() {
    difference() {
        stadium(base_r, base_len, total_thick);
        pocket();
    }
    retention_lip();
}
