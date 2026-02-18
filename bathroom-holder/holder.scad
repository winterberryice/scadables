// ==========================================
// Bathroom Hook Holder - Adapter Base Plate
// ==========================================
//
// Problem:  small adhesive area → hook detaches from tile
// Solution: large stadium-shaped base plate with snap-fit groove
//           for the round hook disc
//
// Orientation: Y = up/down, X = left/right, Z = thickness
// Groove at the BOTTOM → adhesive above the groove has a longer
//   lever arm to resist the peel moment (weight on hook tries
//   to pull the top of the plate away from the tile)
//
// Print: flat on bed, groove facing up (Z+)
// Mount: flat back side glued to tile,
//        hook disc pressed into groove from the front (snaps in)
// ==========================================

/* [Hook disc] */
disc_d = 50;   // Disc diameter [mm]
disc_h = 6;    // Disc thickness [mm] (informational only)

/* [Base plate shape] */
// Stadium: two semicircles (top + bottom) joined by a rectangle, vertical Y axis
base_r     = 32;   // Semicircle radius [mm]  (must be >= disc_d/2 + groove_wall)
base_len   = 45;   // Distance between semicircle centers (straight section) [mm]
base_thick = 3.5;  // Back wall thickness (against tile) [mm]

/* [Snap-fit groove] */
groove_clr  = 0.4;  // Groove clearance – 0=friction only, 0.4=normal snap [mm]
groove_dep  = 4.5;  // Groove depth [mm]
groove_wall = 5.0;  // Min. wall thickness around groove [mm]

snap_h   = 1.2;  // Snap tooth height [mm]
snap_lip = 0.6;  // Snap tooth protrusion – smaller = easier to press in [mm]

// Groove Y position:
//   0          = centre of stadium
//  -base_len/2 = centre of bottom semicircle (maximum lever arm above)
groove_y = -base_len/2;

/* [Render] */
$fn = 128;

// === Derived values ===
groove_d    = disc_d + 2 * groove_clr;
total_thick = base_thick + groove_dep;

_wall_at_groove = base_r - groove_d/2;
echo(str("Overall dimensions: ", 2*base_r, " x ", 2*base_r + base_len, " x ", total_thick, " mm"));
echo(str("Groove dia: ", groove_d, " mm  |  wall: ", _wall_at_groove, " mm  (min: ", groove_wall, " mm)"));
echo(str("Groove Y offset: ", groove_y, " mm from centre"));

// === Modules ===

// Stadium shape – vertical (long axis = Y)
module stadium(r, len, h) {
    hull() {
        translate([0,  len/2, 0]) cylinder(r=r, h=h);
        translate([0, -len/2, 0]) cylinder(r=r, h=h);
    }
}

// Snap-fit groove centred at (cx, cy):
//   - main pocket: disc sits here with clearance
//   - snap tooth at the opening: converging cone → narrow ring → diverging cone
//     disc compresses the walls slightly as it passes and clicks into the pocket
module snap_groove(cx, cy) {
    translate([cx, cy, base_thick]) {

        // Main pocket
        cylinder(d=groove_d, h=groove_dep + 0.01);

        // Snap tooth at opening (Z = total_thick)
        // Profile: ↘ narrowest ↗  (saw-tooth cross-section)
        translate([0, 0, groove_dep - 2*snap_h]) {
            cylinder(d1=groove_d,
                     d2=groove_d - 2*snap_lip,
                     h=snap_h);
            translate([0, 0, snap_h])
                cylinder(d1=groove_d - 2*snap_lip,
                         d2=groove_d,
                         h=snap_h);
        }
    }
}

// === Assembly ===
difference() {
    stadium(base_r, base_len, total_thick);
    snap_groove(0, groove_y);
}
