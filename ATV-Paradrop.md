From zeus, Execute Code, place on a helicopter or a plane, paste this code:
```
(_this select 1) addEventHandler ["GetOut", {
    params ["_veh", "_slot", "_unit"];
    if (_slot != "cargo" || !alive _unit) exitWith {};
    if (position _veh select 2 < 200) exitWith {};
    [_unit, {
        private _atvpos = position _this;
        _atvpos set [2, (_atvpos select 2) - 10];
        private _atv = createVehicle [selectRandom ["B_Quadbike_01_F", "O_Quadbike_01_F", "I_Quadbike_01_F"], _atvpos, [], 0, "NONE"];
        _unit moveInDriver _atv;
        private _para = createVehicle ["B_Parachute_02_F", position _atv, [], 0, "NONE"];
        _atv attachTo [_para, [0, 0, abs (boundingBox _atv select 0 select 2)]];
        [_atv, { { _x addCuratorEditableObjects [[_this],true] } forEach allCurators }] remoteExec ["call", 2];
    }] remoteExec ["call", _unit];
}];
```
Whenever any unit (player or AI) exits the vehicle more than 200m above ground
or sea, a new quadbike is spawned, the unit seated as its driver and a parachute
is created and the quadbike attached to it.
