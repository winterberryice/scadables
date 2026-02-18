// ==========================================
// Bathroom Hook Holder - Adapter Base Plate
// ==========================================
//
// Problem:  small adhesive area → hook detaches from tile
// Solution: large stadium-shaped base plate with:
//           - circular pocket  → locates the hook disc (no glue)
//           - retention lip    → holds disc against peel force
//                                without any adhesive on the disc
//
// Orientation: Y = up/down, X = left/right, Z = thickness (into wall)
// Pocket at BOTTOM of stadium → adhesive above has maximum lever arm
//
// Print: flat on bed, pocket opening facing up (Z+)
// Mount: flat back glued to tile
// Disc insertion: tilt disc (bottom edge in first), rotate flat –
//                 top edge slides under the lip and is retained
// Disc removal:   push up on bottom edge to tilt out
// ==========================================

/* [Hook disc] */
disc_d = 50;   // Disc diameter [mm]
disc_h = 6;    // Disc thickness [mm] (informational – disc will protrude ~1.5 mm)

/* [Base plate shape] */
base_r     = 32;   // Semicircle radius [mm]  (must be >= disc_d/2 + pocket_wall)
base_len   = 45;   // Straight section length between semicircle centres [mm]
base_thick = 3.5;  // Back wall thickness (against tile) [mm]

/* [Locating pocket] */
pocket_clr  = 0.4;  // Pocket clearance – disc slides in freely [mm]
pocket_dep  = 4.5;  // Pocket depth [mm]  (disc protrudes = disc_h - pocket_dep)
pocket_wall = 5.0;  // Min. wall thickness around pocket [mm] (reference only)

/* [Retention lip] */
// 120° arc ring protruding FORWARD from the adapter face, centred on +Y (top of disc).
// 120° leaves 30° free on each side → easy tilt-in insertion.
//
// Cross-section is a plain rectangle (inner and outer faces square).
// The lip embeds lip_base mm INTO the adapter body for a solid print bond.
// A separate quarter-torus fillet smooths the one critical edge:
//   adapter front face → lip outer face (the "top" surface = lever-arm side).
//
// Disc insertion: tilt disc (bottom/side edge first), rotate flat,
//                 top edge slides under lip.  Disc removal: push bottom to tilt out.
lip_w        = 2.5;   // Radial overhang inward from pocket wall [mm]
lip_protrude = 2.5;   // How far lip sticks out BEYOND adapter face [mm]
                      //   must be > (disc_h − pocket_dep) to capture disc edge
lip_base     = 1.5;   // How far lip embeds INTO adapter body [mm] – print adhesion
lip_fillet   = 2.0;   // Fillet radius at adapter-face → lip transition [mm]

/* [Render] */
$fn = 128;

// === Derived ===
pocket_d    = disc_d + 2 * pocket_clr;
total_thick = base_thick + pocket_dep;
pocket_y    = -base_len / 2;   // centre of bottom semicircle

_wall       = base_r - pocket_d / 2;
_disc_prot  = disc_h - pocket_dep;       // how much disc sticks out from adapter face
_lip_overlap = lip_protrude - _disc_prot; // how much lip covers disc from the front
echo(str("Overall: ", 2*base_r, " x ", 2*base_r+base_len, " x ", total_thick, " mm"));
echo(str("Pocket dia: ", pocket_d, " mm  |  wall: ", _wall, " mm"));
echo(str("Disc protrusion: ", _disc_prot, " mm  |  Lip protrusion: ", lip_protrude, " mm  |  Axial overlap: ", _lip_overlap, " mm"));
echo(str("Lip inner dia: ", pocket_d - 2*lip_w, " mm  (disc: ", disc_d, " → radial capture: ", lip_w - pocket_clr, " mm/side)"));

// === Modules ===

// Stadium body – vertical orientation (long axis = Y)
module stadium(r, len, h) {
    hull() {
        translate([0,  len/2, 0]) cylinder(r=r, h=h);
        translate([0, -len/2, 0]) cylinder(r=r, h=h);
    }
}

// Cylindrical locating pocket – plain hole, no snap-fit
module pocket() {
    translate([0, pocket_y, base_thick])
        cylinder(d=pocket_d, h=pocket_dep + 0.01);
}

// Retention lip – 120° arc ring with embedded base and one smooth fillet edge.
//
// Two rotate_extrude pieces, both rotated 30° so the arc spans 30°→150° (+Y centre):
//
//   1. Main body: rectangle cross-section, extends lb below adapter face
//      (the embedding gives the printer a solid base to print on).
//      Inner face (disc side) is SQUARE.
//      Outer face (wall side) is SQUARE.
//
//   2. Fillet: quarter-torus at (r=ro, z=0) filling the concave corner between
//      the adapter front face and the lip outer face.  This is the only rounded edge.
//
// Cross-section schematic (r–z plane, local z):
//
//  ri       ro  ro+fr
//  |         |  /
//  | LIP     | / ← fillet arc (fills this corner)
//  |         |/
//  z=0 ──────╯────── adapter body continues at z=0
//  |         |
//  z=-lb (embedded in adapter)
//
// ri = pocket_d/2 − lip_w   (inner radius)
// ro = pocket_d/2            (outer radius = pocket wall)
module retention_lip() {
    ri = pocket_d/2 - lip_w;
    ro = pocket_d/2;
    lp = lip_protrude;
    lb = lip_base;
    fr = lip_fillet;

    translate([0, pocket_y, total_thick])
        rotate([0, 0, 30]) {   // centres 120° arc on +Y (top of disc)

            // 1. Main lip body: rectangle, embeds lb into adapter
            rotate_extrude(angle = 120, $fn = $fn)
                polygon([
                    [ri, -lb],   // inner bottom (inside adapter)
                    [ro, -lb],   // outer bottom (inside adapter)
                    [ro,  lp],   // outer top
                    [ri,  lp],   // inner top   ← SQUARE (disc contact face)
                ]);

            // 2. Fillet: quarter-torus at the adapter-face / lip-outer-face corner.
            //    Arc from [ro, fr] down to [ro+fr, 0] fills the concave notch.
            //    2D polygon: quarter-circle sector at origin, translated to r=ro.
            rotate_extrude(angle = 120, $fn = $fn)
                translate([ro, 0])
                    polygon(concat(
                        [[0, 0]],
                        [for (a = [0 : 3 : 90]) [fr * cos(a), fr * sin(a)]]
                    ));
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
