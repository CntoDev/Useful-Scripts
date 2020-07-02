/* 		Crew Vision Map System

This will create and update a map marker where the gunner & commander are looking for every crew member of a given vehicle.
It will also create a cone of vision, based on their current FOV.

HOW TO USE:
Add this script to your mission's folder, and in the init of your object add the following
myvehicle execVM "CrewVisionMap.sqf";

"myvehicle" must be the variable name of the vehicle you wish to initialise this script for. "this" cannot be used as an argument.
To initialise for more than one vehicle, simply copy the init code and change "myvehicle" to the name of your new vehicle.

DO NOT EXECUTE SERVER-ONLY, or it will not work.
*/

params ["_vehicle"];
	// Gives unique marker name to be used for all instances of this script. Each instance will reuse this marker as required, as the player can't be in two vehicles at once this is no problem.
	Seb_fnc_CrewVisionMap_GunnerMarkerName = "Seb_fnc_CrewVisionMap_GunnerMarker";
	Seb_fnc_CrewVisionMap_GunnerTargetPos = [0,0];
	Seb_fnc_CrewVisionMap_GunnerFOV = 90;
	
	Seb_fnc_CrewVisionMap_CommanderMarkerName = "Seb_fnc_CrewVisionMap_CommanderMarker";
	Seb_fnc_CrewVisionMap_CommanderTargetPos = [0,0];
	Seb_fnc_CrewVisionMap_CommanderFOV = 90;
	
	// Event handler for player getting into vehicle
	_vehicle addEventHandler ["GetIn", {
			params ["_parentVehicle", "_role", "_unit", "_turret"];
			// is the player the one who just got in?
			if (player isEqualTo _unit) then {
				[_parentVehicle,_role,_unit,_turret] spawn {
					params ["_parentVehicle", "_role", "_unit", "_turret"];
					// create the map markers and vision cone out of player sight for each crew position
					createMarkerLocal [Seb_fnc_CrewVisionMap_GunnerMarkerName,[-10000,-10000]];
					Seb_fnc_CrewVisionMap_GunnerMarkerName setMarkerTypeLocal "mil_destroy";
					Seb_fnc_CrewVisionMap_GunnerMarkerName setMarkerTextLocal " Gunner";
					Seb_fnc_CrewVisionMap_GunnerMarkerName setMarkerColorLocal "ColorBlue";
					
					createMarkerLocal [Seb_fnc_CrewVisionMap_CommanderMarkerName,[-10000,-10000]];
					Seb_fnc_CrewVisionMap_CommanderMarkerName setMarkerTypeLocal "mil_dot";
					Seb_fnc_CrewVisionMap_CommanderMarkerName setMarkerTextLocal " Commander";
					Seb_fnc_CrewVisionMap_CommanderMarkerName setMarkerColorLocal "ColorGreen";
					
					// creates vision cone polygon coords miles away so that if there is no gunner it does not produce error
					// alternative is to add an if statement to draw event handler
					Seb_fnc_CrewVisionMap_gunnerCone = [[-10000,-10000,-10000],[-10000,-10000,-10000],[-10000,-10000,-10000]];
					Seb_fnc_CrewVisionMap_commanderCone = [[-10000,-10000,-10000],[-10000,-10000,-10000],[-10000,-10000,-10000]];
					
					while {true} do {

						// these variables are used to draw cones for the commander and gunner
						_parentVehiclePos = getPos _parentVehicle;
						_parentVehiclePosX = _parentVehiclePos select 0;
						_parentVehiclePosY = _parentVehiclePos select 1;
					
						//GUNNER: if loop for providing info to crew
						// if player is gunner then broadcoast where they are looking to vehicle crew
						if (player isEqualTo gunner _parentVehicle) then {
								//gets crew
								_gunnerClientTargets = crew _parentVehicle;
								//this gets FOV of gunner at engine level, better than getObjectFOV. This is approximate and I have no idea how it works
								_gunnerApproxFov = (deg (getResolution select 5) / ([0.5,0.5] distance2D worldToScreen positionCameraToWorld [0,3,4]))*4;
								// gets x,y of where gunner is looking
								_gunnerTarget = screenToWorld [0.5,0.5];
								//broadcasts where gunner is looking and fov to crew
								[missionNamespace,["Seb_fnc_CrewVisionMap_GunnerTargetPos",_gunnerTarget]] remoteExec ["setVariable",_gunnerClientTargets];
								[missionNamespace,["Seb_fnc_CrewVisionMap_GunnerFOV",_gunnerApproxFov]] remoteExec ["setVariable",_gunnerClientTargets];
							};
						
						//COMMANDER: if loop for providing info to crew
						// if player is commander then broadcoast where they are looking to vehicle crew
						if (player isEqualTo commander _parentVehicle) then {
								//gets crew
								_commanderClientTargets = crew _parentVehicle;
								//this gets FOV of commander at engine level, better than getObjectFOV. This is approximate and I have no idea how it works
								_commanderApproxFov = (deg (getResolution select 5) / ([0.5,0.5] distance2D worldToScreen positionCameraToWorld [0,3,4]))*4;
								// gets x,y of where commander is looking
								_commanderTarget = screenToWorld [0.5,0.5];
								//broadcasts where commander is looking and fov to crew
								[missionNamespace,["Seb_fnc_CrewVisionMap_CommanderTargetPos",_commanderTarget]] remoteExec ["setVariable",_commanderClientTargets];
								[missionNamespace,["Seb_fnc_CrewVisionMap_CommanderFOV",_commanderApproxFov]] remoteExec ["setVariable",_commanderClientTargets];
							};
						
						//GUNNER: update map marker and build cone of vision info if there is a gunner
						if !(isNull (gunner _parentVehicle)) then {
							
							//update map marker position
							Seb_fnc_CrewVisionMap_GunnerMarkerName setMarkerPosLocal Seb_fnc_CrewVisionMap_GunnerTargetPos;
							
							// gets relavative positions of gunner vision
							
							_gunnerTargetPosX = Seb_fnc_CrewVisionMap_GunnerTargetPos select 0;
							_gunnerTargetPosY = Seb_fnc_CrewVisionMap_GunnerTargetPos select 1;
							_gunnerDistanceToTarget = Seb_fnc_CrewVisionMap_GunnerTargetPos distance2d _parentVehiclePos;
							//scale factor scales cone hypotenuse so that the cone reaches gunner target location
							_gunnerScaleFactor = (_gunnerDistanceToTarget /(cos (Seb_fnc_CrewVisionMap_GunnerFOV/2))/_gunnerDistanceToTarget);

							_gunnerOffsetX = ((_gunnerTargetPosX - _parentVehiclePosX) * _gunnerScaleFactor);
							_gunnerOffsetY = ((_gunnerTargetPosY - _parentVehiclePosY) * _gunnerScaleFactor);
							
							
							// places 2 points perpendicular to where player is looking, on line with FOV. In other words, this marks the edge of player FOV near where the player is looking, targetpos
							_GunnerConeL_x = ((cos (Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetX) - ((sin (Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetY) + _parentVehiclePosX;
							_GunnerConeL_y = ((sin (Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetX) + ((cos (Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetY) + _parentVehiclePosY;
							_GunnerConeL = [_GunnerConeL_x,_GunnerConeL_y,0];
							_GunnerConeR_x = ((cos (-Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetX) - ((sin (-Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetY) + _parentVehiclePosX;
							_GunnerConeR_y = ((sin (-Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetX) + ((cos (-Seb_fnc_CrewVisionMap_GunnerFOV/2)) * _gunnerOffsetY) + _parentVehiclePosY;
							_GunnerConeR = [_GunnerConeR_x,_GunnerConeR_y,0];
								
								// builds intermediate points of curved edge of vision by rotating edge point around aim position, probably a tad too computationally expensive but it makes  neat curve
							_GunnerConeArrayTemp = [_GunnerConeR,_parentVehiclePos,_GunnerConeL];
							{
							_GunnerConeC_x = (cos (_x)) * (_GunnerConeL_x - _gunnerTargetPosX) - (sin (_x)) * (_GunnerConeL_y - _gunnerTargetPosY) + _gunnerTargetPosX;
							_GunnerConeC_y = (sin (_x)) * (_GunnerConeL_x - _gunnerTargetPosX) + (cos (_x)) * (_GunnerConeL_y - _gunnerTargetPosY) + _gunnerTargetPosY;
							_gunnerConeC_1 = [_GunnerConeC_x,_GunnerConeC_y,0];
							_GunnerConeArrayTemp pushBack _gunnerConeC_1;
							} forEach [-15,-30,-45,-60,-75,-90,-105,-120,-135,-150,-165,-180];
							Seb_fnc_CrewVisionMap_gunnerCone = _GunnerConeArrayTemp;
							} else {
							// this else could be an if statement inside the true statement of the same code, this way it wouldnt run every loop but I cba
							Seb_fnc_CrewVisionMap_GunnerMarkerName setMarkerPosLocal [-10000,-10000];
							Seb_fnc_CrewVisionMap_gunnerCone = [[-10000,-10000,-10000],[-10000,-10000,-10000],[-10000,-10000,-10000]];
						};
						//COMMANDER: update map marker and build cone of vision info if there is a gunner
						if !(isNull (commander _parentVehicle)) then {
							
							//update map marker position
							Seb_fnc_CrewVisionMap_CommanderMarkerName setMarkerPosLocal Seb_fnc_CrewVisionMap_CommanderTargetPos;
							
							// gets relavative positions of commander vision
							
							_commanderTargetPosX = Seb_fnc_CrewVisionMap_CommanderTargetPos select 0;
							_commanderTargetPosY = Seb_fnc_CrewVisionMap_CommanderTargetPos select 1;
							_commanderDistanceToTarget = Seb_fnc_CrewVisionMap_CommanderTargetPos distance2d _parentVehiclePos;
							//scale factor scales cone hypotenuse so that the cone reaches commander target location
							_commanderScaleFactor = (_commanderDistanceToTarget /(cos (Seb_fnc_CrewVisionMap_CommanderFOV/2))/_commanderDistanceToTarget);

							_commanderOffsetX = ((_commanderTargetPosX - _parentVehiclePosX) * _commanderScaleFactor);
							_commanderOffsetY = ((_commanderTargetPosY - _parentVehiclePosY) * _commanderScaleFactor);
							
							
							// places 2 points perpendicular to where player is looking, on line with FOV. In other words, this marks the edge of player FOV near where the player is looking, targetpos)
							_CommanderConeL_x = ((cos (Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetX) - ((sin (Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetY) + _parentVehiclePosX;
							_CommanderConeL_y = ((sin (Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetX) + ((cos (Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetY) + _parentVehiclePosY;
							_CommanderConeL = [_CommanderConeL_x,_CommanderConeL_y,0];
							_CommanderConeR_x = ((cos (-Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetX) - ((sin (-Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetY) + _parentVehiclePosX;
							_CommanderConeR_y = ((sin (-Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetX) + ((cos (-Seb_fnc_CrewVisionMap_CommanderFOV/2)) * _commanderOffsetY) + _parentVehiclePosY;
							_CommanderConeR = [_CommanderConeR_x,_CommanderConeR_y,0];
							
							// builds intermediate points of curved edge of vision by rotating edge point around aim position, probably a tad too computationally expensive but it makes  neat curve
							_CommanderConeArrayTemp = [_CommanderConeR,_parentVehiclePos,_CommanderConeL];
							{
							_CommanderConeC_x = (cos (_x)) * (_CommanderConeL_x - _commanderTargetPosX) - (sin (_x)) * (_CommanderConeL_y - _commanderTargetPosY) + _commanderTargetPosX;
							_CommanderConeC_y = (sin (_x)) * (_CommanderConeL_x - _commanderTargetPosX) + (cos (_x)) * (_CommanderConeL_y - _commanderTargetPosY) + _commanderTargetPosY;
							_commanderConeC_1 = [_CommanderConeC_x,_CommanderConeC_y,0];
							_CommanderConeArrayTemp pushBack _commanderConeC_1;
							} forEach [-15,-30,-45,-60,-75,-90,-105,-120,-135,-150,-165,-180];
							
							Seb_fnc_CrewVisionMap_commanderCone = _CommanderConeArrayTemp;
							} else {
							// this else could be an if statement inside the true statement of the same code, this way it wouldnt run every loop but I cba
							Seb_fnc_CrewVisionMap_CommanderMarkerName setMarkerPosLocal [-10000,-10000];
							Seb_fnc_CrewVisionMap_commanderCone = [[-10000,-10000,-10000],[-10000,-10000,-10000],[-10000,-10000,-10000]];
						};
						// END OF GUNNER SECTION
						
						// checks if player has got out, exits while loop if true
						if !(_unit in _parentVehicle) exitWith {			
							deleteMarkerLocal Seb_fnc_CrewVisionMap_GunnerMarkerName;
							deleteMarkerLocal Seb_fnc_CrewVisionMap_CommanderMarkerName;
						};
						// code will execute twice per second
						sleep 0.5;
					};
				};
				// spawns vision cone
				[_parentVehicle,_role,_unit,_turret] spawn {
					params ["_parentVehicle", "_role", "_unit", "_turret"];
					
					//Map draw event handler
					Seb_fnc_CrewVisionMap_mapConeEventHandler = findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw", {
						params ["_control"];
						//checks if player is still in vehicle, exits and removes cone if player has got out.
						if (vehicle player isEqualTo player) exitWith {
							findDisplay 12 displayCtrl 51 ctrlRemoveEventHandler ["Draw",Seb_fnc_CrewVisionMap_mapConeEventHandler];			
						};
						// draws the actual cones
						_control drawPolygon [Seb_fnc_CrewVisionMap_gunnerCone, [0,0,1,1]];
						_control drawPolygon [Seb_fnc_CrewVisionMap_commanderCone, [0,1,0,1]];
					}];
					
					//GPS draw event handler
					private _GPSdisplay = uiNamespace getVariable "RscCustomInfoMiniMap";
					private _GPScontrol = _GPSdisplay displayCtrl 101;
					Seb_fnc_CrewVisionMap_gpsConeEventHandler = _GPScontrol ctrlAddEventHandler ["Draw", {
						params ["_control"];
						//checks if player is still in vehicle, exits and removes cone if player has got out.
						if (vehicle player isEqualTo player) exitWith {
							_GPScontrol ctrlRemoveEventHandler ["Draw",Seb_fnc_CrewVisionMap_gpsConeEventHandler];			
						};
						// draws the actual cones
						_control drawPolygon [Seb_fnc_CrewVisionMap_gunnerCone, [0,0,1,1]];
						_control drawPolygon [Seb_fnc_CrewVisionMap_commanderCone, [0,1,0,1]];
					}];
				};
			};
	}];