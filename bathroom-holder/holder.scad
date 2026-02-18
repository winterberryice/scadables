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
// The lip is a half-ring that protrudes FORWARD from the adapter face (in +Z).
// It covers the upper arc (~180°) of the disc opening, physically overlapping
// the top edge of the disc ("pastylka").  The disc cannot pull straight out
// because the upper edge is blocked by the lip.
//
// Disc insertion: tilt disc (bottom edge in first, the pocket is open below),
//                 rotate flat – top edge slides under the lip.
// Disc removal:   push bottom edge in to tilt disc, top edge pops out.
//
// Key constraint: lip_protrude MUST be greater than disc protrusion
//   (= disc_h - pocket_dep) so the lip actually covers the disc edge.
//   Default: disc protrudes 1.5 mm, lip protrudes 2.5 mm → 1 mm of overlap.
lip_w        = 2.5;   // Radial overhang inward from pocket wall [mm]
                      //   = how much disc edge is caught laterally. Try 2–3.5 mm.
lip_protrude = 2.5;   // How far lip sticks out from adapter front face [mm]
                      //   Must be > (disc_h - pocket_dep). Try 2.0–3.5 mm.

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

// Retention lip – upper half-ring protruding from the FRONT FACE of the adapter.
// Sits at Z = total_thick (front face) and extends to Z = total_thick + lip_protrude.
// Covers the upper 180° arc of the pocket opening.
// Visually: a half-pipe awning overhanging the top of the disc opening.
// Functionally: the disc's top edge cannot move in +Z (out from wall) because
//               the lip is physically in the way.
module retention_lip() {
    translate([0, pocket_y, total_thick]) {
        intersection() {
            // Half-ring: outer edge at pocket wall, inner edge lip_w inward
            difference() {
                cylinder(d=pocket_d,           h=lip_protrude);
                cylinder(d=pocket_d - 2*lip_w, h=lip_protrude + 0.01);
            }
            // Mask: upper half only (local Y ≥ 0 = high-Y side of disc)
            translate([-pocket_d, 0, -0.01])
                cube([2*pocket_d, pocket_d, lip_protrude + 0.02]);
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
