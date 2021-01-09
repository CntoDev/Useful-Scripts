/*
Removes AI long range optics, but not if they are snipers or marksmen.
As we don't get ACOGs they shouldn't either!

Place in init.sqf
*/
["CAManBase", "initPost", {
     private _man = _this#0;
     if !(local _man) exitWith {};
     private _role = [configOf _man, "displayName"] call BIS_fnc_returnConfigEntry;
     if (["sniper","marksman","Sniper","Marksman"] findIf {_x in _role} != -1) exitWith {};
     private _optic = (primaryWeaponItems _man)#2;
     private _opticCfg = (configfile >> "CfgWeapons" >> _optic >> "ItemInfo" >> "OpticsModes"); 
     private _opticVisionModes = [_opticCfg,2] call BIS_fnc_returnChildren; 
     private _opticVisionModeUseModelOptics = _opticVisionModes apply {getNumber (_x >> "useModelOptics")}; 
     private _opticUseModelOpticsFindNonZero = _opticVisionModeUseModelOptics findIf {_x != 0}; 
     private _cfgScope = getNumber (configfile >> "CfgWeapons" >> _optic >> "scope"); 
     private _opticExtremes = [_opticVisionModes,["opticsZoomMin"]] call BIS_fnc_configExtremes; 
     private _opticMaxZoom = (_opticExtremes#0)#0;
     if !(_opticMaxZoom >=0.25 && _cfgScope == 2 && _opticUseModelOpticsFindNonZero == -1) then {
       _man removePrimaryWeaponItem _optic;
     };
},true,[],true] call CBA_fnc_addClassEventHandler;