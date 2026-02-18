// ==========================================
// Bathroom Hook Holder - Adapter Base Plate
// ==========================================
//
// Problem:  small adhesive area -> hook detaches from tile
// Solution: large stadium-shaped base plate with:
//           - circular pocket  -> locates the hook disc (no glue)
//           - retention lip    -> holds disc against peel force
//                                without any adhesive on the disc
//
// Orientation: Y = up/down, X = left/right, Z = thickness (into wall)
// Pocket at BOTTOM of stadium -> adhesive above has maximum lever arm
//
// Print: flat on bed, pocket opening facing up (Z+)
// Mount: flat back glued to tile
// Disc insertion: tilt disc (bottom edge in first), rotate flat -
//                 top edge slides under the lip and is retained
// Disc removal:   push up on bottom edge to tilt out
// ==========================================

/* [Hook disc] */
disc_d = 50;   // Disc diameter [mm]
disc_h = 6;    // Disc thickness [mm] (informational - disc will protrude ~1.5 mm)

/* [Base plate shape] */
base_r     = 32;   // Semicircle radius [mm]  (must be >= disc_d/2 + pocket_wall)
base_len   = 45;   // Straight section length between semicircle centres [mm]
base_thick = 3.5;  // Back wall thickness (against tile) [mm]

/* [Locating pocket] */
pocket_clr  = 0.4;  // Pocket clearance - disc slides in freely [mm]
pocket_dep  = 4.5;  // Pocket depth [mm]  (disc protrudes = disc_h - pocket_dep)
pocket_wall = 5.0;  // Min. wall thickness around pocket [mm] (reference only)

/* [Retention lip] */
// 120 deg arc ring protruding FORWARD from the adapter face, centred on +Y (top of disc).
// 120 deg leaves 30 deg free on each side -> easy tilt-in insertion.
//
// Cross-section (r-z plane, local z=0 = adapter front face):
//
//  ri        ro   ro+lb
//  |          |      |
//  |   LIP    | FOOT |
//  |          |      |
//  z=0 -------+      ) <- concave arc (scooped corner)
//             |     /
//  z=-lb -----+----+
//
//  Two pieces (both rotate_extrude'd over 120 deg, centred on +Y):
//
//  1. Main lip body: plain rectangle [ri,0]->[ro,lp].
//     Inner face (ri): SQUARE at z=0, no embedding on disc side.
//
//  2. Foot: rectangle [ro,0]->[ro+lb,-lb] embedded into adapter,
//     MINUS a circle of radius lip_fillet at [ro+lb, 0].
//     The circle subtracts a concave arc from the outer-top corner of the foot.
//     With lip_fillet = lip_base: the entire outer face becomes the concave arc,
//     smoothly connecting adapter face (z=0) to foot bottom ([ro+lb, -lb]).
//
// ri = pocket_d/2 - lip_w   (inner radius)
// ro = pocket_d/2            (outer radius = pocket wall)
lip_w        = 2.5;   // Radial overhang inward from pocket wall [mm]
lip_protrude = 2.5;   // How far lip sticks out BEYOND adapter face [mm]
                      //   must be > (disc_h - pocket_dep) to capture disc edge
lip_base     = 1.5;   // Foot size: width in r and depth in z [mm]
lip_fillet   = 1.5;   // Concave fillet radius [mm]
                      //   set equal to lip_base for cleanest look (full arc, no straight outer face)
                      //   set smaller to leave a straight outer face on the foot

/* [Render] */
$fn = 128;

// === Derived ===
pocket_d    = disc_d + 2 * pocket_clr;
total_thick = base_thick + pocket_dep;
pocket_y    = -base_len / 2;   // centre of bottom semicircle

_wall        = base_r - pocket_d / 2;
_disc_prot   = disc_h - pocket_dep;
_lip_overlap = lip_protrude - _disc_prot;
echo(str("Overall: ", 2*base_r, " x ", 2*base_r+base_len, " x ", total_thick, " mm"));
echo(str("Pocket dia: ", pocket_d, " mm  |  wall: ", _wall, " mm"));
echo(str("Disc protrusion: ", _disc_prot, " mm  |  Lip protrusion: ", lip_protrude,
         " mm  |  Axial overlap: ", _lip_overlap, " mm"));
echo(str("Lip inner dia: ", pocket_d - 2*lip_w, " mm  (disc: ", disc_d,
         " -> radial capture: ", lip_w - pocket_clr, " mm/side)"));

// === Modules ===

// Stadium body - vertical orientation (long axis = Y)
module stadium(r, len, h) {
    hull() {
        translate([0,  len/2, 0]) cylinder(r=r, h=h);
        translate([0, -len/2, 0]) cylinder(r=r, h=h);
    }
}

// Cylindrical locating pocket - plain hole, no snap-fit
module pocket() {
    translate([0, pocket_y, base_thick])
        cylinder(d=pocket_d, h=pocket_dep + 0.01);
}

// Retention lip - 120 deg arc, two rotate_extrude pieces, arc spans 30->150 deg (+Y centre).
//
// Piece 1: main lip body - rectangle, inner face SQUARE, starts flush at z=0.
//
// Piece 2: foot with concave fillet -
//   2D: rectangle [ro..ro+lb] x [-lb..0]  MINUS  circle(r=fr) at [ro+lb, 0]
//   The subtracted circle scoops the outer-top corner of the foot concavely.
//   The resulting 2D shape is bounded by:
//     inner face  r=ro,    z: -lb to 0       (straight, vertical)
//     bottom      z=-lb,   r: ro to ro+lb    (straight, horizontal)
//     concave arc from [ro+lb, -lb] curving up-left to [ro+lb-fr, 0]
//     top face    z=0,     r: ro to ro+lb-fr (straight, horizontal, may be zero if fr=lb)
//
module retention_lip() {
    ri = pocket_d/2 - lip_w;
    ro = pocket_d/2;
    lp = lip_protrude;
    lb = lip_base;
    fr = min(lip_fillet, lb);   // clamp: fillet can't exceed foot size

    translate([0, pocket_y, total_thick])
        rotate([0, 0, 30]) {    // centres 120 deg arc on +Y (top of disc)

            // 1. Main lip body: square inner face, no embedding on disc side
            rotate_extrude(angle = 120, $fn = $fn)
                polygon([
                    [ri, 0 ],   // inner bottom - SQUARE, flush with adapter face
                    [ro, 0 ],   // outer bottom
                    [ro, lp],   // outer top
                    [ri, lp],   // inner top - SQUARE (disc contact face)
                ]);

            // 2. Foot + concave fillet via 2D difference before rotate_extrude
            rotate_extrude(angle = 120, $fn = $fn)
                difference() {
                    // Foot rectangle embedded in adapter
                    polygon([
                        [ro,    0 ],
                        [ro+lb, 0 ],
                        [ro+lb,-lb],
                        [ro,   -lb],
                    ]);
                    // Concave scoop: subtract circle at outer-top corner
                    // This removes a quarter-circle of radius fr from that corner,
                    // leaving a concave (hollow) arc instead of a sharp right angle.
                    translate([ro+lb, 0])
                        circle(r = fr, $fn = $fn);
                }
        }
}

// === Assembly ===
union() {
    difference() {
        stadium(base_r, base_len, total_thick);
        pocket();
    }
    retention_lip();
}
