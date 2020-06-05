/* This script causes all units in the array on line 15 to fire at random points in the sky, like ambient AA fire
To use, place this script in any object's init and call objects Flaks_0, Flaks_1, etc or build your own array and modify line 15 */

if (isServer) then {
	[] spawn {
		AntiAircraftFire = true; // set this to false later in the mission to stop the AA fire
			while {AntiAircraftFire} do {		
				{ 
				_AntiAirCraftx = round(random 400) -200 + (getPosAsl _x select 0); 
				_AntiAirCrafty = round(random 400) -200 + (getPosAsl _x select 1); // These 2 snippets select the random point. Change "400" to your diameter around the unit, and "-200" to -1/2 that.
				_firetarget = [_AntiAirCraftx,_AntiAirCrafty,200]; //this creates the target for them to fir at "200" is the altitude, can change.
				_x setVehicleAmmo 1; //ensures that units don't run out of ammo
				_x doSuppressiveFire _firetarget; //makes them fire
				uisleep 2; // Makes it slowly cycle through all AA cannons so they're not constantly getting new targest. Set to approx number of items in array/15
				} forEach [Flaks_0, Flaks_1, Flaks_2, Flaks_3, Flaks_4, Flaks_5, Flaks_6, Flaks_7, Flaks_8, Flaks_9, Flaks_10, Flaks_11, Flaks_12, Flaks_13, Lights_0, Lights_1, Lights_2, Lights_3, Lights_4, Lights_5, Lights_6, Lights_7, Lights_8, Lights_9, Lights_10, Lights_11];
			};
	};
};
