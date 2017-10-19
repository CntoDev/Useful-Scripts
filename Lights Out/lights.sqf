/*
 * Author: CNTO
 * Toggles lights on and off around position. Run only on server. Compile it before use by putting this in init.sqf:
 * fnc_toggleLights = compile preprocessFileLineNumbers "lights.sqf";
 *
 * Arguments:
 * 0: Use true for lights on, false for lights off. <BOOLEAN>
 * 1: Position around which lights will be toggled. <POSITION>
 * 2: Radius around position where lights will be toggled. Defaults to 500m. <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [true, getMarkerPos "LightsMarker2", 1000] spawn fnc_toggleLights; 
 * Turns lights on 1000m around the position of marker "LightsMarker2".
 *
 * Public: Yes
 */
 
params ["_onoff", "_position", ["_distance", 500]];
_types = ["Lamps_Base_F", "PowerLines_base_F"];

private _damage_value = 0;

if (_onoff) then {
	_damage_value = 0;
} else {
	_damage_value = 0.97;
};

for [{_i=0},{_i < (count _types)},{_i=_i+1}] do
{
    // powercoverage is a marker I placed.
	_lamps = _position nearObjects [_types select _i, _distance];
	sleep 1;
	{_x setDamage _damage_value} forEach _lamps;
};