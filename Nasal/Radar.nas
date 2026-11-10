# ===============================================================
#                   Air and Terrain Mode Radar
#                    for Leonardo M-346 Master
#                      AMOROSO Paolo 11/2026
# ===============================================================
MPjoin = func(n) {
  var base = n.getValue();
  setprop("instrumentation/radar/" ~ base ~ "/radar/y-shift", 0);
  setprop("instrumentation/radar/" ~ base ~ "/radar/x-shift", 0);
  setprop("instrumentation/radar/" ~ base ~ "/radar/rotation", 0);
  setprop("instrumentation/radar/" ~ base ~ "/radar/in-range", 0);
  setprop("instrumentation/radar/" ~ base ~ "/radar/h-offset", 180);
  setprop("instrumentation/radar/" ~ base ~ "/joined", 1);
}

MPleave = func(n) {
  var base = n.getValue();
  setprop("instrumentation/radar/" ~ base ~ "/radar/in-range", 0);
  setprop("instrumentation/radar/" ~ base ~ "/joined", 0);
}

MPradarProperties = func {
  var targetList = props.globals.getNode("ai/models/").getChildren("multiplayer");

  foreach (d; props.globals.getNode("ai/models/").getChildren("aircraft")) {
    append(targetList, d);
  }

  var selected = getprop("instrumentation/radar/selected");
  var range = getprop("instrumentation/radar/range");
  var displaymode = getprop("instrumentation/radar/display-mode");

  if (selected == 2) {
    if (range == 10) {
      setprop("instrumentation/radar/range", 20);
      setprop("instrumentation/radar/range-factor", 0.002);
      range = 20;
    } elsif (range == 20) {
      setprop("instrumentation/radar/range-factor", 0.003246);
    } else {
      setprop("instrumentation/radar/range-factor", 0.001623);
    }

  } elsif (selected == 3 or selected == 4) {
    if (range == 40) {
      setprop("instrumentation/radar/range", 20);
      setprop("instrumentation/radar/range-factor", 0.001888);
      range = 20;
    } elsif (range == 20) {
      setprop("instrumentation/radar/range-factor", 0.001888);
    } else {
      setprop("instrumentation/radar/range-factor", 0.003776);
    }
  }

  var factor = getprop("instrumentation/radar/range-factor");
  if (factor == nil) factor = 1.0;

var arcOffset = 0;
var targetFineOffset = 0.020;

if (displaymode == "ARC") {
  arcOffset = -(16.0 * range / 30.0) * factor;
  arcOffset -= targetFineOffset;
}

  foreach (m; targetList) {

    var name = m.getName();
    var index = m.getIndex();

    var path = "instrumentation/radar/ai/models/" ~
               name ~ "[" ~ index ~ "]/";

    var sourcePath = "ai/models/" ~
                     name ~ "[" ~ index ~ "]/";

    if (getprop(path ~ "joined") == 1 or name == "aircraft") {

      var yNode = m.getNode("radar/y-shift", 0);
      var xNode = m.getNode("radar/x-shift", 0);
      var rotNode = m.getNode("radar/rotation", 0);
      var hOffNode = m.getNode("radar/h-offset", 0);
      var inRangeNode = m.getNode("radar/in-range", 0);

      var yVal = yNode != nil and yNode.getValue() != nil
                 ? yNode.getValue() : 0;

      var xVal = xNode != nil and xNode.getValue() != nil
                 ? xNode.getValue() : 0;

      var rotVal = rotNode != nil and rotNode.getValue() != nil
                   ? rotNode.getValue() : 0;

      var hOffVal = hOffNode != nil and hOffNode.getValue() != nil
                    ? hOffNode.getValue() : 0;

      var inRangeVal = inRangeNode != nil and inRangeNode.getValue() != nil
                       ? inRangeNode.getValue() : 0;

      setprop(path ~ "radar/y-shift",
              yVal * factor + arcOffset);

      setprop(path ~ "radar/x-shift",
              xVal * factor);

      setprop(path ~ "radar/rotation", rotVal);
      setprop(path ~ "radar/h-offset", hOffVal);

      if (selected == 2) {

        var xShift = getprop(path ~ "radar/x-shift");

        if (xShift < -0.04 or xShift > 0.04) {
          setprop(path ~ "radar/in-range", 0);
        } else {
          setprop(path ~ "radar/in-range", inRangeVal);
        }

      } else {
        setprop(path ~ "radar/in-range", inRangeVal);
      }
    }
  }

  settimer(MPradarProperties, 0.05);
}

# =====================
#  Boresight Detecting
# =====================
locking=0;
found=-1;

boreSightLock = func {
  if (getprop("instrumentation/radar/selected") == 1) {
    targetList= props.globals.getNode("ai/models/").getChildren("multiplayer");

    foreach (d; props.globals.getNode("ai/models/").getChildren("aircraft")) {
      append(targetList,d);
    }

    foreach (m; targetList) {
      var string = "instrumentation/radar/ai/models/"~m.getName()~"["~m.getIndex()~"]";
      var string1 = "ai/models/"~m.getName()~"["~m.getIndex()~"]";
      if (getprop(string1~"radar/in-range")) {

        hOffset = getprop(string1~"radar/h-offset");
        vOffset = getprop(string1~"radar/v-offset");

        #really should be a cone, but is a square pyramid to avoid trigonemetry
        if(hOffset < 3 and hOffset > -3 and vOffset < 3 and vOffset > -3) {
          if (locking == 11) {
            setprop(string~"radar/boreLock",2);
            setprop("instrumentation/radar/lock",2);
            setprop("sim[0]/hud/current-color",1);
            locking -= 1;
          } elsif (locking ==1 or locking ==3 or locking ==5 or locking ==7 or locking ==9 ) {
            setprop("instrumentation/radar/lock",1);
            setprop(string1~"radar/boreLock",1);
          } else {
            setprop("instrumentation/radar/lock",0);
            setprop(string~"radar/boreLock",1);
          }

          if (found != m.getIndex()) {
            found=m.getIndex();
            locking=0;
          } else {
            locking += 1;
          }
          settimer(boreSightLock, 0.2);
          return;
        }
      }
    }
    setprop(string~"radar/boreLock",0);
    locking=0;
    setprop("sim[0]/hud/current-color",0);
  }

  locking=0;
  setprop("sim[0]/hud/current-color",0);
  found =-1;
  setprop("instrumentation/radar/lock",0);

  settimer(boreSightLock, 0.2);
}

setlistener("ai/models/model-added", MPjoin);
setlistener("ai/models/model-removed", MPleave);
settimer(MPradarProperties,1.0);
settimer(boreSightLock, 1.0);

#================================================================
#                      Terrain Radar Mode
#================================================================
print("*** LOADING TERRAIN-MAP ***");

var row          = 0;
var RAD2DEG      = 57.2957795;
var DEG2RAD      = 0.016774532925;
var TM_Path      = "/instrumentation/terrain-map/pixels/";

# Function to get Elevation at latitude and longitude
var TM_get_elevation = func (lat, lon) {
  var info = geodinfo(lat, lon);

  if (info == nil ) {
    var elevation = -1;                            # Unknown
  } elsif (info[1] == nil) {
    var elevation = info[0] * 3.2808399;           # Building
  } elsif (info[1].solid == 0) {
    var elevation = 0;                             # Water
  } else {
    var elevation = info[0] * 3.2808399;           # other
  }

  return elevation;
}

var terrain_map = {

  init : func {
    me.UPDATE_INTERVAL = 0.025;
    me.loopid = 0;
    me.reset();
  },

  update : func {

    var poslon      = getprop("/position/longitude-deg");
    var poslat      = getprop("/position/latitude-deg");
    var heading     = getprop("/orientation/heading-magnetic-deg");

    var range       = getprop("/instrumentation/radar/range");
    var displaymode = getprop("/instrumentation/radar/display-mode");


    # First get all the points (16x16)
    for (var col = 0; col <= 30; col += 2) {

      var projlon = poslon + ((-1 * (col-16) * (range/30) * math.sin(DEG2RAD * (heading - 90))) / 60);
      var projlat = poslat + ((-1 * (col-16) * (range/30) * math.cos(DEG2RAD * (heading - 90))) / 60);

      if (displaymode == 'ARC') {                                                             # just represent ahead
        var pointlon = projlon + ((row * (range/30) / 60) * math.sin(DEG2RAD * heading));
        var pointlat = projlat + ((row * (range/30) / 60) * math.cos(DEG2RAD * heading));
      } else {                                                                                 # Represent ahead and back
        var pointlon = projlon + (((row-16) * (range/30) / 60) * math.sin(DEG2RAD * heading));
        var pointlat = projlat + (((row-16) * (range/30) / 60) * math.cos(DEG2RAD * heading));
      }

      var elevation = TM_get_elevation(pointlat, pointlon);

      setprop(TM_Path ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", elevation);
    }

    # Interpolate the rest of the points in each column

    for (var col = 1; col <= 29; col += 2) {
      var elevprev = getprop(TM_Path ~ "row[" ~ row ~ "]/col[" ~ (col - 1) ~ "]/elevation-ft");
      var elevnext = getprop(TM_Path ~ "row[" ~ row ~ "]/col[" ~ (col + 1) ~ "]/elevation-ft");
      var elevation = (elevprev + elevnext) / 2;

      setprop(TM_Path ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", elevation);
    }

    row += 1;

    if (row == 31) {
      row = 0;
    }
  },

  reset : func {
    me.loopid += 2;
    me._loop_(me.loopid);
  },
  _loop_ : func(id) {
    id == me.loopid or return;
    me.update();
    settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
  }
};

###  Main loop ###
setlistener("sim/signals/fdm-initialized", func {
  terrain_map.init();
  print("Terrain Map READY");
});

#================================================================
#              FORWARD LOOKING TERRAIN RADAR Mode
#================================================================

print("*** FORWARD LOOKING TERRAIN RADAR INIT ***");

var FL_DEG2RAD  = 0.01745329252;
var FL_TERRAIN  = "/instrumentation/terrain-map/pixels/";

var FL_MAX_ROW      = 30;
var FL_MAX_COL      = 30;
var FL_RAY_STEPS    = 6;        
var FL_MAX_RANGE_NM = 10;
var FL_FT_PER_NM    = 6076;

var FL_row        = 0;
var FL_active     = 0;   

var FL_get_elevation = func(lat, lon) {
    var info = geodinfo(lat, lon);
    if (info == nil) return -1;
    if (info[1] == nil) return info[0] * 3.2808399; 
    if (info[1].solid == 0) return 0;
    return info[0] * 3.2808399;
}

var FL_update = func {

    if (getprop("/instrumentation/terrain-map/forward-looking") != 1)
        return;

    var lat     = getprop("/position/latitude-deg");
    var lon     = getprop("/position/longitude-deg");
    var heading = getprop("/orientation/heading-magnetic-deg");
    var pitch   = getprop("/orientation/pitch-deg");
    var alt_ft  = getprop("/position/altitude-ft");

    var range_nm = getprop("/instrumentation/terrain-map/range");
    if (range_nm == nil) range_nm = FL_MAX_RANGE_NM;

    var antenna_tilt = getprop("/instrumentation/terrain-map/tilt-deg");
    if (antenna_tilt == nil) antenna_tilt = 0;

    var row = FL_row;
    var dist_nm_row = (row + 1) * (range_nm / (FL_MAX_ROW + 1));

    for (var col = 0; col <= FL_MAX_COL; col += 2) {

        var lateral_nm = (col - FL_MAX_COL/2) * (range_nm / FL_MAX_COL);

        var base_lat = lat + (lateral_nm * math.cos(FL_DEG2RAD * (heading + 90)) / 60);
        var base_lon = lon + (lateral_nm * math.sin(FL_DEG2RAD * (heading + 90)) / 60);

        var hit = -1;

        for (var s = 1; s <= FL_RAY_STEPS; s += 1) {

            var frac    = s / FL_RAY_STEPS;
            var dist_nm = dist_nm_row * frac;
            var dist_ft = dist_nm * FL_FT_PER_NM;
            var total_tilt = pitch + antenna_tilt;
            var ray_alt = alt_ft + math.tan(FL_DEG2RAD * total_tilt) * dist_ft;
            
            var testlat = base_lat + (dist_nm * math.cos(FL_DEG2RAD * heading) / 60);
            var testlon = base_lon + (dist_nm * math.sin(FL_DEG2RAD * heading) / 60);

            var terr = FL_get_elevation(testlat, testlon);

            if (terr >= ray_alt and terr >= 0) {
                hit = terr;
                break;
            }
        }

        setprop(FL_TERRAIN ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", hit);
    }

    for (var col = 1; col < FL_MAX_COL; col += 2) {
        var a = getprop(FL_TERRAIN ~ "row[" ~ row ~ "]/col[" ~ (col-1) ~ "]/elevation-ft");
        var b = getprop(FL_TERRAIN ~ "row[" ~ row ~ "]/col[" ~ (col+1) ~ "]/elevation-ft");
        setprop(FL_TERRAIN ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", (a + b) / 2);
    }

    FL_row += 1;
    if (FL_row > FL_MAX_ROW) FL_row = 0;
}

var FL_loop = func {
    FL_update();
    settimer(FL_loop, 0.02);
}

var FL_syncLoop = func {
    FL_syncTerrainMap();
    settimer(FL_syncLoop, 0.3);
}

setlistener("sim/signals/fdm-initialized", func {
    print("Forward Looking Terrain Radar READY");
    FL_loop();
    FL_syncLoop();
});

#================================================================
#                 AIR-TO-AIR TWS SLEW RADAR
#================================================================

var AA_ROWS = 31;
var AA_COLS = 31;

var AA_UPDATE_PERIOD = 0.50;

var AA_FOV_AZ_DEG = 60.0;
var AA_FOV_EL_DEG = 30.0;

var AA_MODEL_CATEGORIES = [
    "aircraft",
    "multiplayer",
    "tanker",
    "carrier",
    "ship",
    "groundvehicle",
    "escort",
    "ballistic"
];

var AA_PREVIOUS = [];
var AA_RUNNING = 0;

var AA_nodeValue = func(model, path) {

    var node = model.getNode(path);

    if (node == nil) return nil;

    return node.getValue();
};

var AA_get = func(path, defaultValue) {

    var value = getprop(path);

    if (value == nil) return defaultValue;

    return value;
};

var AA_init = func {

    AA_PREVIOUS = [];

    for (var i = 0; i < AA_ROWS * AA_COLS; i += 1) {

        var row = math.floor(i / AA_COLS);
        var col = i - row * AA_COLS;

        var path = "/instrumentation/radar/air-to-air/pixels/row[" ~ row ~
                   "]/col[" ~ col ~ "]/target-distance";

        setprop(path, 0);

        append(AA_PREVIOUS, 0);
    }
};

var AA_update = func {

    if (!AA_RUNNING) return;

    var nextValues = [];
    var nearest = [];

    for (var i = 0; i < AA_ROWS * AA_COLS; i += 1) {

        append(nextValues, 0);
        append(nearest, 1.0e20);
    }

    var ownLat = AA_get("/position/latitude-deg", nil);
    var ownLon = AA_get("/position/longitude-deg", nil);
    var ownAlt = AA_get("/position/altitude-ft", nil);

    var heading = AA_get("/orientation/heading-deg", 0);
    var pitch = AA_get("/orientation/pitch-deg", 0);
    var roll = AA_get("/orientation/roll-deg", 0);

    var antennaHeading = AA_get(
        "/instrumentation/radar/air-to-air/heading-deg", 0);

    var antennaTilt = AA_get(
        "/instrumentation/radar/air-to-air/tilt-deg", 0);

    var radarRange = AA_get("/instrumentation/radar[0]/range", 80);


    if (ownLat == nil or ownLon == nil or ownAlt == nil or radarRange <= 0) {

        settimer(AA_update, AA_UPDATE_PERIOD);

        return;
    }

    var d2r = math.pi / 180.0;

    var psi = heading * d2r;
    var theta = pitch * d2r;
    var phi = roll * d2r;

    var antAz = antennaHeading * d2r;
    var antEl = antennaTilt * d2r;

    var fN = math.cos(theta) * math.cos(psi);
    var fE = math.cos(theta) * math.sin(psi);
    var fU = math.sin(theta);

    var rN0 = -math.sin(psi);
    var rE0 =  math.cos(psi);
    var rU0 = 0;

    var uN0 = -math.sin(theta) * math.cos(psi);
    var uE0 = -math.sin(theta) * math.sin(psi);
    var uU0 =  math.cos(theta);

    var rN = math.cos(phi) * rN0 - math.sin(phi) * uN0;
    var rE = math.cos(phi) * rE0 - math.sin(phi) * uE0;
    var rU = math.cos(phi) * rU0 - math.sin(phi) * uU0;

    var uN = math.sin(phi) * rN0 + math.cos(phi) * uN0;
    var uE = math.sin(phi) * rE0 + math.cos(phi) * uE0;
    var uU = math.sin(phi) * rU0 + math.cos(phi) * uU0;

    var bF = [
        math.cos(antEl) * math.cos(antAz),
        math.cos(antEl) * math.sin(antAz),
        math.sin(antEl)
    ];

    var bR = [
        -math.sin(antAz),
         math.cos(antAz),
         0
    ];

    var bU = [
        -math.sin(antEl) * math.cos(antAz),
        -math.sin(antEl) * math.sin(antAz),
         math.cos(antEl)
    ];

    var latFactor = 60.0;
    var lonFactor = 60.0 * math.cos(ownLat * d2r);

    var feetPerNM = 6076.11549;

    var AA_modelsFound = 0;
    var AA_modelsValid = 0;
    var AA_modelsPosition = 0;
    var AA_modelsInRange = 0;
    var AA_modelsInFOV = 0;

    var root = props.globals.getNode("/ai/models");

    if (root != nil) {

        foreach (var category; AA_MODEL_CATEGORIES) {

            var models = root.getChildren(category);

            foreach (var model; models) {

                AA_modelsFound += 1;

                var valid = AA_nodeValue(model, "valid");

                if (valid != nil and valid == 0) continue;

                AA_modelsValid += 1;

                var targetLat = AA_nodeValue(
                    model, "position/latitude-deg");

                var targetLon = AA_nodeValue(
                    model, "position/longitude-deg");

                var targetAlt = AA_nodeValue(
                    model, "position/altitude-ft");


                if (targetLat == nil or
                    targetLon == nil or
                    targetAlt == nil) continue;

                AA_modelsPosition += 1;

                var deltaLat = targetLat - ownLat;
                var deltaLon = targetLon - ownLon;

                if (deltaLon > 180) {
                    deltaLon -= 360;
                } elsif (deltaLon < -180) {
                    deltaLon += 360;
                }

                var north = deltaLat * latFactor;
                var east = deltaLon * lonFactor;

                var up = (targetAlt - ownAlt) / feetPerNM;

                var distanceNM = math.sqrt(
                    north * north +
                    east * east +
                    up * up
                );

                if (distanceNM > radarRange) continue;

                AA_modelsInRange += 1;

                var bodyF = north * fN + east * fE + up * fU;
                var bodyR = north * rN + east * rE + up * rU;
                var bodyU = north * uN + east * uE + up * uU;


                var beamF = bodyF * bF[0] +
                            bodyR * bF[1] +
                            bodyU * bF[2];

                var beamR = bodyF * bR[0] +
                            bodyR * bR[1] +
                            bodyU * bR[2];

                var beamU = bodyF * bU[0] +
                            bodyR * bU[1] +
                            bodyU * bU[2];

                if (beamF <= 0) continue;

                var azimuth = math.atan2(beamR, beamF) / d2r;
                var elevation = math.atan2(beamU, beamF) / d2r;


                if (math.abs(azimuth) > AA_FOV_AZ_DEG) continue;
                if (math.abs(elevation) > AA_FOV_EL_DEG) continue;

                AA_modelsInFOV += 1;

                var col = math.floor(
                    ((azimuth + AA_FOV_AZ_DEG) /
                    (2 * AA_FOV_AZ_DEG)) * AA_COLS
                );

                var row = math.floor(
                    ((elevation + AA_FOV_EL_DEG) /
                    (2 * AA_FOV_EL_DEG)) * AA_ROWS
                );


                col = math.max(0, math.min(AA_COLS - 1, col));
                row = math.max(0, math.min(AA_ROWS - 1, row));


                var cell = row * AA_COLS + col;

                if (distanceNM < nearest[cell]) {

                    nearest[cell] = distanceNM;

                    var signal = 15000 * (1.0 - distanceNM / radarRange);

                    nextValues[cell] = math.max(0, signal);
                }

            }
        }
    }

    for (var i = 0; i < AA_ROWS * AA_COLS; i += 1) {

        if (nextValues[i] != AA_PREVIOUS[i]) {

            var row = math.floor(i / AA_COLS);
            var col = i - row * AA_COLS;

            var path = "/instrumentation/radar/air-to-air/pixels/row[" ~ row ~
                       "]/col[" ~ col ~ "]/target-distance";

            setprop(path, nextValues[i]);

            AA_PREVIOUS[i] = nextValues[i];
        }
    }

    setprop("/instrumentation/radar/air-to-air/debug/models-found",
            AA_modelsFound);

    setprop("/instrumentation/radar/air-to-air/debug/models-valid",
            AA_modelsValid);

    setprop("/instrumentation/radar/air-to-air/debug/models-position",
            AA_modelsPosition);

    setprop("/instrumentation/radar/air-to-air/debug/models-in-range",
            AA_modelsInRange);

    setprop("/instrumentation/radar/air-to-air/debug/models-in-fov",
            AA_modelsInFOV);


    settimer(AA_update, AA_UPDATE_PERIOD);
};

var AA_start = func {

    if (AA_RUNNING) return;

    AA_init();

    AA_RUNNING = 1;

    settimer(AA_update, AA_UPDATE_PERIOD);
};

var AA_stop = func {

    AA_RUNNING = 0;
};

AA_start();
