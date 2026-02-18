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
// The lip is a half-ring of material on the UPPER side of the pocket opening.
// It overhangs the disc edge so the disc cannot pull straight out.
// Disc must be tilted to insert / remove (see mount instructions above).
lip_w = 2.5;   // Lip overhang over disc edge [mm]  – larger = stronger hold,
               //   harder to insert. Try 2.0–3.5 mm.

/* [Render] */
$fn = 128;

// === Derived ===
pocket_d    = disc_d + 2 * pocket_clr;
total_thick = base_thick + pocket_dep;
pocket_y    = -base_len / 2;   // centre of bottom semicircle

_wall = base_r - pocket_d / 2;
echo(str("Overall: ", 2*base_r, " x ", 2*base_r+base_len, " x ", total_thick, " mm"));
echo(str("Pocket dia: ", pocket_d, " mm  |  wall: ", _wall, " mm"));
echo(str("Lip inner dia: ", pocket_d - 2*lip_w, " mm  (disc: ", disc_d, " mm → overhang: ", lip_w - pocket_clr, " mm per side)"));
echo(str("Disc protrusion: ", disc_h - pocket_dep, " mm"));

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

// Retention lip – upper half-ring inside the pocket.
// Added back after the pocket is subtracted from the body.
// Covers 180° on the high-Y (upper) side of the pocket.
module retention_lip() {
    translate([0, pocket_y, base_thick]) {
        intersection() {
            // Full-depth ring, lip_w wide
            difference() {
                cylinder(d=pocket_d,           h=pocket_dep);
                cylinder(d=pocket_d - 2*lip_w, h=pocket_dep + 0.01);
            }
            // Mask: upper half only (local Y ≥ 0 = high-Y side)
            translate([-pocket_d, 0, -0.01])
                cube([2*pocket_d, pocket_d, pocket_dep + 0.02]);
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
