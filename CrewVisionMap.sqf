/* 		Crew Vision Map System

This will create and update a map marker where the gunner & commander are looking for every crew member of a given vehicle.
It will also create a cone of vision, based on their current FOV.

It will only work if that crew member is a player.

HOW TO USE:
Add this script to your mission's folder, and in the init of your vehicle add the following:
this execVM "CrewVisionMap.sqf";

To initialise for more than one vehicle, simply copy that same init code to the new vehicle.

This will only work if the vehicle has a "gunner" OR "commander" slot, or both. If it only has 1 of those that's fine, it's just pointless to use these slots do not exist.

DO NOT EXECUTE SERVER-ONLY, or it will not work.
*/
if !(hasInterface) exitWith {};
params ["_vehicle"];
	// Gives unique marker name to be used for all instances of this script. Each instance will reuse this marker as required, as the player can't be in two vehicles at once this is no problem.
	Seb_fnc_CrewVisionMap_gunnerMarkerName = "Seb_fnc_CrewVisionMap_gunnerMarker";
	Seb_fnc_CrewVisionMap_gunnerTargetPos = [0,0,0];
	Seb_fnc_CrewVisionMap_gunnerFOV = 90;
	
	Seb_fnc_CrewVisionMap_commanderMarkerName = "Seb_fnc_CrewVisionMap_commanderMarker";
	Seb_fnc_CrewVisionMap_commanderTargetPos = [0,0,0];
	Seb_fnc_CrewVisionMap_commanderFOV = 90;
	

	
	// Event handler for player getting into vehicle
_vehicle addEventHandler ["GetIn", {
	// initialising all vars to be used a re-used later
	
	// blank cone to be manipulated based on FOV and distancetoTarget, This cone is 90deg at 100m. Instead of calculating a new cone each frame, this one will be manipulated
	Seb_fnc_CrewVisionMap_BlankCone = [
	[0,0,0],
	[-100,100,0],
	[-96.5925826289068,125.881904510252,0],
	[-86.6025403784439,150,0],
	[-70.7106781186548,170.710678118655,0],
	[-50,186.602540378444,0],
	[-25.8819045102521,196.592582628907,0],
	[-6.12323399573677E-15,200,0],
	[25.8819045102521,196.592582628907,0],
	[50,186.602540378444,0],
	[70.7106781186547,170.710678118655,0],
	[86.6025403784439,150,0],
	[96.5925826289068,125.881904510252,0],
	[100,100,0]
	];

	params ["_parentVehicle", "_role", "_unit", "_turret"];
	// is the player the one who just got in?
	if (player ==  _unit) then {
		// This "spawn" handles logic for updating crew about gunner info
		[_parentVehicle,_role,_unit,_turret] spawn {
			params ["_parentVehicle", "_role", "_unit", "_turret"];
				while {true} do {
				
				//GUNNER: while loop for providing info to crew
				// if player is gunner then broadcoast where they are looking to vehicle crew
				if (player ==  gunner _parentVehicle) then {
					//gets crew
					_gunnerClientTargets = crew _parentVehicle;
					//this gets FOV of gunner at engine level, better than getObjectFOV. This is approximate and I have no idea how it works
					_gunnerApproxFov = (deg (getResolution select 5) / ([0.5,0.5] distance2D worldToScreen positionCameraToWorld [0,3,4]))*4;
						
					// declares gunnerTarget in case below returns null and therefore _gunnerTarget is not declared inside if statement which does not work
					_gunnerTarget = [];
					// gets x,y of where gunner is looking. Checks if intersecting objects are in the way are returns that object's pos if true. Error is that it will return centre of object not centre of intersect.
					_gunnerTarget = (lineIntersectsSurfaces [eyepos Player,ATLToASL screenToWorld [0.5,0.5],player,vehicle player,true,1,"GEOM","VIEW"] select 0) select 0;
					// for some reason the above can sometimes return nil when looking at terrain. This detects & fixes that. Luckily this returns what the above should.
					if (isNil "_gunnerTarget") then {_gunnerTarget = screenToWorld [0.5,0.5];};
					//broadcasts where gunner is looking and fov to crew
					[missionNamespace,["Seb_fnc_CrewVisionMap_gunnerTargetPos",_gunnerTarget]] remoteExec ["setVariable",_gunnerClientTargets];
					[missionNamespace,["Seb_fnc_CrewVisionMap_gunnerFOV",_gunnerApproxFov]] remoteExec ["setVariable",_gunnerClientTargets];
					// this code executes twice per second
					sleep 0.5;
					// checks if player has got out, exits while loop if true
					if !(_unit in _parentVehicle) exitWith {};
				};
				
				//COMMANDER: while loop for providing info to crew
				// if player is gunner then broadcoast where they are looking to vehicle crew
				if (player ==  commander _parentVehicle) then {
					//gets crew
					_commanderClientTargets = crew _parentVehicle;
					//this gets FOV of commander at engine level, better than getObjectFOV. This is approximate and I have no idea how it works
					_commanderApproxFov = (deg (getResolution select 5) / ([0.5,0.5] distance2D worldToScreen positionCameraToWorld [0,3,4]))*4;
						
					// declares commanderTarget in case below returns null and therefore _commanderTarget is not declared inside if statement which does not work
					_commanderTarget = [];
					// gets x,y of where commander is looking. Checks if intersecting objects are in the way are returns that object's pos if true. Error is that it will return centre of object not centre of intersect.
					_commanderTarget = (lineIntersectsSurfaces [eyepos Player,ATLToASL screenToWorld [0.5,0.5],player,vehicle player,true,1,"GEOM","VIEW"] select 0) select 0;
					// for some reason the above can sometimes return nil when looking at terrain. This detects & fixes that. Luckily this returns what the above should.
					if (isNil "_commanderTarget") then {_commanderTarget = screenToWorld [0.5,0.5];};
					//broadcasts where commander is looking and fov to crew
					[missionNamespace,["Seb_fnc_CrewVisionMap_commanderTargetPos",_commanderTarget]] remoteExec ["setVariable",_commanderClientTargets];
					[missionNamespace,["Seb_fnc_CrewVisionMap_commanderFOV",_commanderApproxFov]] remoteExec ["setVariable",_commanderClientTargets];
					// this code executes twice per second
					sleep 0.5;
					// checks if player has got out, exits while loop if true
					if !(_unit in _parentVehicle) exitWith {};
				};
			};
		};
		
		
		// This "spawn" handles logic for drawing markers and cones and stuff
		[_parentVehicle,_role,_unit,_turret] spawn {
			params ["_parentVehicle", "_role", "_unit", "_turret"];
			// create the map markers and vision cone out of player sight for each crew position
			createMarkerLocal [Seb_fnc_CrewVisionMap_gunnerMarkerName,[-10000,-10000,-10000]];
			Seb_fnc_CrewVisionMap_gunnerMarkerName setMarkerTypeLocal "mil_destroy";
			Seb_fnc_CrewVisionMap_gunnerMarkerName setMarkerTextLocal " Gunner";
			Seb_fnc_CrewVisionMap_gunnerMarkerName setMarkerColorLocal "ColorBlue";
			
			createMarkerLocal [Seb_fnc_CrewVisionMap_commanderMarkerName,[-10000,-10000,-10000]];
			Seb_fnc_CrewVisionMap_commanderMarkerName setMarkerTypeLocal "mil_box";
			Seb_fnc_CrewVisionMap_commanderMarkerName setMarkerTextLocal "Commander";
			Seb_fnc_CrewVisionMap_commanderMarkerName setMarkerColorLocal "ColorGreen";
			Seb_fnc_CrewVisionMap_commanderMarkerName setMarkerDirLocal 45;
			
			// creates vision cone polygon coords miles away so that if there is no gunner it does not produce error
			// alternative is to add an if statement to draw event handler
			Seb_fnc_CrewVisionMap_gunnerCone = +Seb_fnc_CrewVisionMap_BlankCone;
			Seb_fnc_CrewVisionMap_commanderCone = +Seb_fnc_CrewVisionMap_BlankCone;
			
			// first loop of interpolation will throw an error if there are no "old" variables, this creates the old loop and marker coords as some dummy values that are overwritten immediately
			// Gunner dummy interpolation values
			_gunnerConeOld = +Seb_fnc_CrewVisionMap_BlankCone;
			Seb_fnc_CrewVisionMap_gunnerConeInterpTemp = +Seb_fnc_CrewVisionMap_BlankCone;
			_gunnerMarkerPosOld = [0,0,0];
			
			// Commander dummy interpolation values
			_commanderConeOld = +Seb_fnc_CrewVisionMap_BlankCone;
			Seb_fnc_CrewVisionMap_commanderConeInterpTemp = +Seb_fnc_CrewVisionMap_BlankCone;
			_commanderMarkerPosOld = [0,0,0];
			
			//Provides vehicle's X and Y coords, used to draw cones for the commander and gunner
			_parentVehiclePos = getPos _parentVehicle;
			_parentVehiclePos params ["_parentVehiclePosX", "_parentVehiclePosY"];
			
			// while loop for constantly updating cone and map marker info
			while {true} do {

				//GUNNER: update map marker and build cone of vision info if there is a gunner
				if !(isNull (gunner _parentVehicle)) then {
					
					// Resets cone for new calc loop
					_gunnerConeArrayTemp = +Seb_fnc_CrewVisionMap_BlankCone;			
					// Calculates distance to target
					_gunnerDistanceToTarget = _parentVehicle distance2D Seb_fnc_CrewVisionMap_gunnerTargetPos;			
					// Calculates direction to target
					_gunnerDirectionToTarget = _parentVehicle getDir Seb_fnc_CrewVisionMap_gunnerTargetPos;
					// Fov ratio calculated by (tan(fov)*distance) divided by 100 as blank cone is set at 100m to target.
					_gunnerFovRatio = tan(Seb_fnc_CrewVisionMap_gunnerFOV/2)*(_gunnerDistanceToTarget/100);

					// Modifies the blank cone with properties from distance2d and FOV. Scales before rotation for less trig!, x dimension is FOV y is distance to target, then rotates.
					for "_i" from 0 to 13 do {
						private _gunnerSelector = _i;
						(_gunnerConeArrayTemp select _gunnerSelector) params ["_gunnerBlankX","_gunnerBlankY"];
						// Declares Y
						_gunnerNewY = _gunnerBlankY;
						// Scales Y dimension to match distance to target
						_gunnerNewY = _gunnerNewY * (_gunnerDistanceToTarget/100);
						// Scales the curved cone so it isn't skewed and has a consistent radius. This took formula took way too long.
						if (_gunnerSelector >= 2 && _gunnerSelector <= 12) then {_gunnerNewY = ((_gunnerNewY-_gunnerDistanceToTarget)*(tan(Seb_fnc_CrewVisionMap_gunnerFOV/2))+_gunnerDistanceToTarget)};
	
						// Multiplies X dimensions by FOV ratio of blank cone TAN to actual TAN.
						_gunnerNewX = _gunnerBlankX * _gunnerFovRatio;
						
						// Rotates X and Y coordinates. Needs to be a new var as X/Y being modified before completion creates skewing innacuracy.
						_gunnerNewRotX = cos(-_gunnerDirectionToTarget) * (_gunnerNewX) - sin(-_gunnerDirectionToTarget) * (_gunnerNewY);
						_gunnerNewRotY = sin(-_gunnerDirectionToTarget) * (_gunnerNewX) + cos(-_gunnerDirectionToTarget) * (_gunnerNewY);
						
						// Applies offset so this new cone matches vehicle position.
						_gunnerNewRotX = (_gunnerNewRotX + _parentVehiclePosX);
						_gunnerNewRotY = (_gunnerNewRotY + _parentVehiclePosY);	
						
						_gunnerConeArrayTemp set [_gunnerSelector,[_gunnerNewRotX,_gunnerNewRotY,0]];
					};
					
					//value for map marker to interpolate to
					_gunnerMarkerNew = Seb_fnc_CrewVisionMap_gunnerTargetPos;
					
					// updates cone at 25fps-ish by interpolating from old to new.
					// i is 12 as 24 fps update rate, with a marker that changes pos twice per second.
					for "_i" from 1 to 12 do {
						// alpha is amount done of interpolation as a ratio of completed frames to total frames.
						private _alpha = _i/12;
						// turns out arma has an interpolate fnc so I dont have to make my own thats pretty neat actually
						// update map marker position based on interpolation
						Seb_fnc_CrewVisionMap_gunnerMarkerInterpolate = [_gunnerMarkerPosOld,_gunnerMarkerNew,_alpha] call BIS_fnc_easeInOutVector;
						Seb_fnc_CrewVisionMap_gunnerMarkerName setMarkerPosLocal Seb_fnc_CrewVisionMap_gunnerMarkerInterpolate;
						// interpolates each cone array item (0 to 13) for smooth transitions using alpha from frames passed since last update of marker between the 2fps aimpoints.
						for "_i" from 0 to 13 do {
							private _gunnerInterpSelector = _i;
							
							_gunnerConeInterpolateValue = [_gunnerConeOld select _gunnerInterpSelector,_gunnerConeArrayTemp select _gunnerInterpSelector,_alpha] call BIS_fnc_easeInOutVector;
							Seb_fnc_CrewVisionMap_gunnerConeInterpTemp set [_gunnerInterpSelector,_gunnerConeInterpolateValue];
						};
						// sends mid-interpolation info to the draw handler
						Seb_fnc_CrewVisionMap_gunnerCone = +Seb_fnc_CrewVisionMap_gunnerConeInterpTemp;	
						
						// sleep is 1/24, as i loop is 1/12+1 for something updating twice per second = 25fps interpolation
						sleep 0.04;
						
						
						
					};
					// old gunner cone array and position to interpolate FROM next loop
					_gunnerMarkerPosOld = _gunnerMarkerNew;
					_gunnerConeOld = seb_fnc_CrewVisionMap_gunnerCone;
				} else {
					// this else could be an if statement inside the true statement of the same code, this way it wouldnt run every loop but I cba
					Seb_fnc_CrewVisionMap_gunnerMarkerName setMarkerPosLocal [-10000,-10000,-10000];
					Seb_fnc_CrewVisionMap_gunnerCone = [[-10000,-10000,-10000],[-10000,-10000,-10000],[-10000,-10000,-10000]];
				};
				// END OF GUNNER SECTION
				
				//COMMANDER: update map marker and build cone of vision info if there is a commander
				if !(isNull (commander _parentVehicle)) then {
					
					// Resets cone for new calc loop
					_commanderConeArrayTemp = +Seb_fnc_CrewVisionMap_BlankCone;			
					// Calculates distance to target
					_commanderDistanceToTarget = _parentVehicle distance2D Seb_fnc_CrewVisionMap_commanderTargetPos;			
					// Calculates direction to target
					_commanderDirectionToTarget = _parentVehicle getDir Seb_fnc_CrewVisionMap_commanderTargetPos;
					// Fov ratio calculated by (tan(fov)*distance) divided by 100 as blank cone has dimensions of x100.
					_commanderFovRatio = tan(Seb_fnc_CrewVisionMap_commanderFOV/2)*(_commanderDistanceToTarget/100);

					// Modifies the blank cone with properties from distance2d and FOV. Scales before rotation for less trig!, x dimension is FOV y is distance to target, then rotates.
					for "_i" from 0 to 13 do {
						private _commanderSelector = _i;
						(_commanderConeArrayTemp select _commanderSelector) params ["_commanderBlankX","_commanderBlankY"];
						// Declares Y
						_commanderNewY = _commanderBlankY;
						// Scales Y dimension to match distance to target
						_commanderNewY = _commanderNewY * (_commanderDistanceToTarget/100);
						// Scales the curve cone so it isn't skewed and has a consistent radius. This took formula took way too long.
						if (_commanderSelector >= 2 && _commanderSelector <= 12) then {_commanderNewY = ((_commanderNewY-_commanderDistanceToTarget)*(tan(Seb_fnc_CrewVisionMap_commanderFOV/2))+_commanderDistanceToTarget)};
	
						// Multiplies X dimensions by FOV ratio of blank cone TAN to actual TAN.
						_commanderNewX = _commanderBlankX * _commanderFovRatio;
						
						// Rotates X and Y coordinates. Needs to be a new var as X/Y being modified before completion creates skewing innacuracy.
						_commanderNewRotX = cos(-_commanderDirectionToTarget) * (_commanderNewX) - sin(-_commanderDirectionToTarget) * (_commanderNewY);
						_commanderNewRotY = sin(-_commanderDirectionToTarget) * (_commanderNewX) + cos(-_commanderDirectionToTarget) * (_commanderNewY);
						
						// Applies offset so this new cone matches vehicle position.
						_commanderNewRotX = (_commanderNewRotX + _parentVehiclePosX);
						_commanderNewRotY = (_commanderNewRotY + _parentVehiclePosY);	
						
						_commanderConeArrayTemp set [_commanderSelector,[_commanderNewRotX,_commanderNewRotY,0]];
					};
					
					//value for map marker to interpolate to
					_commanderMarkerNew = Seb_fnc_CrewVisionMap_commanderTargetPos;
					
					// updates cone at 25fps-ish by interpolating from old to new.
					// i is 12 as 24 fps update rate, with a marker that changes pos twice per second.
					for "_i" from 1 to 12 do {
						// alpha is amount done of interpolation as a ratio of completed frames to total frames.
						private _alpha = _i/12;
						// turns out arma has an interpolate fnc so I dont have to make my own thats pretty neat actually
						// update map marker position based on interpolation
						Seb_fnc_CrewVisionMap_commanderMarkerInterpolate = [_commanderMarkerPosOld,_commanderMarkerNew,_alpha] call BIS_fnc_easeInOutVector;
						Seb_fnc_CrewVisionMap_commanderMarkerName setMarkerPosLocal Seb_fnc_CrewVisionMap_commanderMarkerInterpolate;
						// interpolates each cone array item (0 to 13) for smooth transitions using alpha from frames passed since last update of marker between the 2fps aimpoints.
						for "_i" from 0 to 13 do {
							private _commanderInterpSelector = _i;
							
							_commanderConeInterpolateValue = [_commanderConeOld select _commanderInterpSelector,_commanderConeArrayTemp select _commanderInterpSelector,_alpha] call BIS_fnc_easeInOutVector;
							Seb_fnc_CrewVisionMap_commanderConeInterpTemp set [_commanderInterpSelector,_commanderConeInterpolateValue];
						};
						// sends mid-interpolation info to the draw handler
						Seb_fnc_CrewVisionMap_commanderCone = +Seb_fnc_CrewVisionMap_commanderConeInterpTemp;	
						
						// sleep is 1/24, as i loop is 1/12+1 for something updating twice per second = 25fps interpolation
						sleep 0.04;
						
						
						
					};
					// old commander cone array and position to interpolate FROM next loop
					_commanderMarkerPosOld = _commanderMarkerNew;
					_commanderConeOld = seb_fnc_CrewVisionMap_commanderCone;
				} else {
					// this else could be an if statement inside the true statement of the same code, this way it wouldnt run every loop but I cba
					Seb_fnc_CrewVisionMap_commanderMarkerName setMarkerPosLocal [-10000,-10000,-10000];
					Seb_fnc_CrewVisionMap_commanderCone = [[-10000,-10000,-10000],[-10000,-10000,-10000],[-10000,-10000,-10000]];
				};
				// checks if player has got out, exits while loop if true
				if !(_unit in _parentVehicle) exitWith {			
					deleteMarkerLocal Seb_fnc_CrewVisionMap_gunnerMarkerName;
				};	
			};
		};
		// spawns vision cone
		[_parentVehicle,_role,_unit,_turret] spawn {
			params ["_parentVehicle", "_role", "_unit", "_turret"];
			disableSerialization;
			
			//Map draw event handler
			Seb_fnc_CrewVisionMap_mapConeEventHandler = findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw", {
				params ["_control"];
				//checks if player is still in vehicle, exits and removes cone if player has got out.
				if (vehicle player ==  player) exitWith {
					findDisplay 12 displayCtrl 51 ctrlRemoveEventHandler ["Draw",Seb_fnc_CrewVisionMap_mapConeEventHandler];			
				};
				// draws the actual cones
				// Gunner
				_control drawPolygon [Seb_fnc_CrewVisionMap_gunnerCone, [0,0,1,1]];
				// _control drawEllipse [Seb_fnc_CrewVisionMap_gunnerMarkerInterpolate,25,25,0,[0,0,1,1],"#(rgb,8,8,3)color(0,0,1,0.5)"];
				
				// Commander
				_control drawPolygon [Seb_fnc_CrewVisionMap_commanderCone, [0,1,0,1]];
			}];
			
			//GPS draw event handler
			private _GPSdisplay = uiNamespace getVariable "RscCustomInfoMiniMap";
			private _GPScontrol = _GPSdisplay displayCtrl 101;
			Seb_fnc_CrewVisionMap_gpsConeEventHandler = _GPScontrol ctrlAddEventHandler ["Draw", {
				params ["_control"];
				//checks if player is still in vehicle, exits and removes cone if player has got out.
				if (vehicle player ==  player) exitWith {
					_GPScontrol ctrlRemoveEventHandler ["Draw",Seb_fnc_CrewVisionMap_gpsConeEventHandler];			
				};
				// draws the actual cones
				_control drawPolygon [Seb_fnc_CrewVisionMap_gunnerCone, [0,0,1,1]];
				
				// Commander
				_control drawPolygon [Seb_fnc_CrewVisionMap_commanderCone, [0,1,0,1]];
			}];
		};
	};
}];
