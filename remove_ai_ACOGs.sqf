/*
Removes AI long range optics, but not if they are snipers or marksmen.
As we don't get ACOGs they shouldn't either!
Dynamically simulated units seem to not be updated until they become active.

Works for units created in editor or spawned via Zeus.

Place in initServer.sqf
*/
if !(isServer) exitWith {};
[] spawn {
    waitUntil {sleep 1; time>15};
    ["CAManBase", "initPost", {
        private _man = _this#0;
        if (primaryWeapon _man == "" or _man in playableUnits) exitWith {};
        private _role = [configOf _man, "displayName"] call BIS_fnc_returnConfigEntry;
        if (["sniper","marksman","Sniper","Marksman","spotter","Spotter"] findIf {_x in _role} != -1) exitWith {};
        private _optic = (primaryWeaponItems _man)#2;
        if (_optic == "") exitWith {};
        private _loadout = getUnitLoadout _man;
        private _weaponArr = _loadout#0;
        _weaponArr set [3, ""];
        _man setUnitLoadout _loadout;
    },true,[],true] call CBA_fnc_addClassEventHandler;
};