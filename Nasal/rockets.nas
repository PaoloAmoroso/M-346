
props.globals.initNode("/sim/is-MP-Aircraft", 0, "BOOL");

#GSh-23 cannon trigger

#initialize triggers
props.globals.initNode("/controls/armament/trigger1", 0, "BOOL");
setprop("/controls/armament/trigger1", 0);


props.globals.initNode("/controls/armament/trigger-S-13-L", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-S-13-R", 0, "BOOL");

#props.globals.initNode("/sim/multiplay/generic/int[8]", 0, "INT");

#ammo counter
props.globals.initNode("/controls/armament/rocketsLeft", 5, "INT");
props.globals.initNode("/controls/armament/rocketsCount", 5, "DOUBLE");
var reload = func {
	if( getprop("/gear/gear[0]/wow") and getprop("/gear/gear[1]/wow") and getprop("/gear/gear[2]/wow") and (getprop("/velocities/groundspeed-kt") < 2) ) {
		setprop("/controls/armament/rocketsLeft", 5);
		setprop("/controls/armament/rocketsCount", 5);
		screen.log.write("S-13 rockets reloaded (5 rockets per pod)", 1, 0.6, 0.1);
	}
	else {
		screen.log.write("You must be still on the ground to reaload! ", 1, 0.6, 0.1);
	}
}

#A resource friendly way of ammo counting: Instead of counting every bullet, I set an interpolate on float variant of ammo counter. But I need a timer to cut off fire when out of ammo. 

var outOfAmmo = maketimer(1.0, 
	func { 
		#print("Out of rockets! ");
		screen.log.write("Out of rockets! ", 1, 0.6, 0.1);
		setprop("/controls/armament/trigger-S-13-L", 0);
		setprop("/controls/armament/trigger-S-13-R", 0);
		setprop("/controls/armament/rocketsCount", 0);
		setprop("/controls/armament/rocketsLeft", 0);
	}
);
outOfAmmo.singleShot = 1;

#trigger control with ammo counting
var triggerControl = func {
	triggerState = getprop("controls/armament/trigger1");
	if(triggerState and getprop("/controls/armament/rocketsLeft") > 0) {
		var mounted2L = (getprop("/sim/weight[2]/payload-int") == 2);
		var mounted6R = (getprop("/sim/weight[6]/payload-int") == 2);
		
		if(mounted2L or mounted6R) {
			var fireTime = 0.75; #continuous fire for 0.15s intervals
			if(mounted2L) {
				setprop("/controls/armament/trigger-S-13-L", 1);
			}
			if(mounted6R) {
				setprop("/controls/armament/trigger-S-13-R", 1);
			}
			var rocketsLeft = getprop("/controls/armament/rocketsLeft");
			setprop("/controls/armament/rocketsCount", rocketsLeft);
			interpolate("/controls/armament/rocketsCount", 0, 
				fireTime*(rocketsLeft/5));
			outOfAmmo.restart(fireTime*(rocketsLeft/5));
		}
	}
	else {
		setprop("/controls/armament/trigger-S-13-L", 0);
		setprop("/controls/armament/trigger-S-13-R", 0);
		
		setprop("/controls/armament/rocketsLeft", 
			getprop("/controls/armament/rocketsCount"));#gets truncated
		interpolate("/controls/armament/rocketsCount", 
			getprop("/controls/armament/rocketsLeft"), 0);
		outOfAmmo.stop();
		#ammo count report on trigger release
		if(getprop("/controls/armament/report-ammo"))
			screen.log.write("S-13 rockets left: " ~ getprop("/controls/armament/rocketsLeft") ~ ((getprop("/sim/weight[2]/payload-int") == 2 and  getprop("/sim/weight[6]/payload-int") == 2)?" x2":""), 1, 0.6, 0.1);
	}
}

setlistener("controls/armament/trigger1", triggerControl);

