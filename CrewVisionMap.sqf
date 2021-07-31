/*         Crew Vision Map System
This will create and update a map marker where the gunner & commander are looking for every crew member of a given vehicle.
It will also create a cone of vision, based on their current FOV.
This is designed for multiplayer with player crew members only.
It will only work if the gunner or commander is a player.
HOW TO USE:
Add this script to your mission's folder, and in the init of your vehicle add the following:
this execVM "CrewVisionMap.sqf";
To initialise for more than one vehicle, simply copy that same init code to the new vehicle.
This will only work if the vehicle has a "gunner" OR "commander" slot, or both. If it only has 1 of those that's fine, it's just pointless to use if these slots do not exist.
Must be executed locally, do not wrap in ifServer.
*/

if !(hasInterface) exitWith {};
params ["_vehicle"];
// Event handler for player getting into vehicle

disableSerialization;

_vehicle addEventHandler ["GetIn", {
    params ["_vehicle", "_role", "_unit", "_turret"];
    if (player == _unit) then {
        // updates crew about gunner & commander FOV.
        private _sendInfoHandler = [{
            (_this select 0) params ["_vehicle"];
            if (vehicle player == player) then {
                [_handle] call CBA_fnc_removePerFrameHandler;
            } else {
                if (player == gunner _vehicle) then {
                    // get and send FOV
                    private _execTargets = crew _vehicle;
                    private _vfov = deg((call CBA_fnc_getFov) select 0);
                    private _aspRatio = "NUMBER" call CBA_fnc_getAspectRatio;
                    private _hfov = 2*atan(tan(_vfov/2)*_aspRatio);
                    [_vehicle,["Seb_CrewVisionMap_gunnerFOV",_hfov]] remoteExec ["setVariable",_execTargets];

                    // get and send target position
                    private _camPos = AGLtoASL (positionCameraToWorld [0, 0, 0]);
                    _target = [];
                    _target = (lineIntersectsSurfaces [_camPos,AGLToASL screenToWorld [0.5,0.5],player,vehicle player,true,1,"FIRE","VIEW"] select 0) select 0;
                    if (isNil "_target") then {_target = screenToWorld [0.5,0.5];};
                    [_vehicle,["Seb_CrewVisionMap_gunnerTarget",_target]] remoteExec ["setVariable",_execTargets];
                };
                if (player == commander _vehicle) then {
                    // get and send FOV
                    private _execTargets = crew _vehicle;
                    private _vfov = deg((call CBA_fnc_getFov) select 0);
                    private _aspRatio = "NUMBER" call CBA_fnc_getAspectRatio;
                    private _hfov = 2*atan(tan(_vfov/2)*_aspRatio);
                    [_vehicle,["Seb_CrewVisionMap_commanderFOV",_hfov]] remoteExec ["setVariable",_execTargets];

                    // get and send target position
                    private _camPos = AGLtoASL (positionCameraToWorld [0, 0, 0]);
                    _target = [];
                    _target = (lineIntersectsSurfaces [_camPos,AGLToASL screenToWorld [0.5,0.5],player,vehicle player,true,1,"FIRE","VIEW"] select 0) select 0;
                    if (isNil "_target") then {_target = screenToWorld [0.5,0.5];};
                    [_vehicle,["Seb_CrewVisionMap_commanderTarget",_target]] remoteExec ["setVariable",_execTargets];
                };
            };
        }, 0.25, [_vehicle]] call CBA_fnc_addPerFrameHandler;

        private _fnc_DrawCone = {
            disableSerialization;
            private _fnc_getCone = {
            params ["_vehicle","_roleFOV","_target"];

            // blank cone vertices. This draws a cone with 45deg angle at 100m distance.
            // This is then manipulated based on view direciton and elevation.
                private _coneArrayTemp = [
                    [0,         0,          0],
                    [-100,      100,        0],
                    [-96.593,   125.883,    0],
                    [-86.603,   150,        0],
                    [-70.711,   170.711,    0],
                    [-50,       186.603,    0],
                    [-25.882,   196.593,    0],
                    [0,         200,        0],
                    [25.882,    196.593,    0],
                    [50,        186.603,    0],
                    [70.711,    170.711,    0],
                    [86.603,    150,        0],
                    [96.593,    125.882,    0],
                    [100,       100,        0]
                ];

                private _distanceToTarget = _vehicle distance2D _target;
                if (_distanceToTarget > 15000) then {_distanceToTarget = 15000;};
                private _viewAzi = _vehicle getDir _target;
                private _vehPos = getPosASL _vehicle;
                // Fov ratio calculated by (tan(fov)*distance) divided by 100 as blank cone is set at 100m to target.
                private _fovRatio = tan(_roleFOV/2)*(_distanceToTarget/100);

                // Modifies the blank cone with properties from distance2d and FOV. Scales before rotation for less trig!, x dimension is FOV y is distance to target, then rotates.
                for "_i" from 0 to 13 do {
                    (_coneArrayTemp select _i) params ["_blankX","_blankY"];
                    // Declares Y
                    private _newY = _blankY;
                    // Scales Y dimension to match distance to target
                    private _newY = _newY * (_distanceToTarget/100);
                    // Scales the curved cone section so it isn't skewed and has a consistent radius. This took formula took way too long.
                    if (_i >= 2 && _i <= 12) then {_newY = ((_newY-_distanceToTarget)*(tan(_roleFOV/2))+_distanceToTarget)};
                    // Multiplies X dimensions by FOV ratio of blank cone TAN to actual TAN.
                    private _newX = _blankX * _fovRatio;
                    // Rotates X and Y coordinates. Needs to be a new var as X/Y being modified before completion creates skewing innacuracy.
                    private _newRotX = cos(-_viewAzi) * (_newX) - sin(-_viewAzi) * (_newY);
                    private _newRotY = sin(-_viewAzi) * (_newX) + cos(-_viewAzi) * (_newY);
                    // Applies offset so this new cone matches vehicle position.
                    private _newRotX = (_newRotX + (_vehPos select 0));
                    private _newRotY = (_newRotY + (_vehPos select 1));

                    _coneArrayTemp set [_i,[_newRotX,_newRotY,0]];s
                };
                _coneArrayFinal = +_coneArrayTemp;
                // return
                _coneArrayFinal
            };

            if (vehicle player ==  player) exitWith {
                _thisArgs ctrlRemoveEventHandler ["Draw",_thisID];
            };

            if ((isPlayer (gunner (vehicle player))) isEqualTo true) then {
                private _gunnerFOV =  (vehicle player) getVariable ["Seb_CrewVisionMap_gunnerFOV",45];
                private _gunnerTarget =  (vehicle player) getVariable ["Seb_CrewVisionMap_gunnerTarget",[0,0,0]];
                private _gunnerCone = [(vehicle player),_gunnerFOV,_gunnerTarget] call _fnc_getCone;
                _thisArgs drawPolygon [_gunnerCone, [0,0,1,1]];
                _thisArgs DrawIcon ["pictureExplosive",[0,0,1,1],_gunnerTarget,25,25,0,"Gunner",1];
            };

            if ((isPlayer (commander (vehicle player))) isEqualTo true) then {
                private _commanderFOV =  (vehicle player) getVariable ["Seb_CrewVisionMap_commanderFOV",45];
                private _commanderTarget =  (vehicle player) getVariable ["Seb_CrewVisionMap_commanderTarget",[0,0,0]];
                if (!isPlayer commander (vehicle player)) then {_commanderFOV = 45;};
                private _commanderCone = [(vehicle player),_commanderFOV,_commanderTarget] call _fnc_getCone;
                _thisArgs drawPolygon [_commanderCone, [0,1,0,1]];
                _thisArgs DrawIcon ["pictureExplosive",[0,1,0,1],_commanderTarget,25,25,0,"Commander",1];
            };
        };

        disableSerialization;
        //Map draw event handler
        private _mapControl = findDisplay 12 displayCtrl 51;
        [_mapControl,"Draw",_fnc_DrawCone,_mapControl] call CBA_fnc_addBISEventHandler;

        //GPS draw event handler
        private _GPSdisplay = uiNamespace getVariable "RscCustomInfoMiniMap";
        private _GPScontrol = _GPSdisplay displayCtrl 101;
        [_GPScontrol,"Draw",_fnc_DrawCone,_GPScontrol] call CBA_fnc_addBISEventHandler;
    };
}];
