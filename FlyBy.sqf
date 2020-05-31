// MUST RENAME THIS FILE TO INIT IN ORDER TO WORK


if (isServer) then {
	sleep 90;
	[getMarkerPos "flyby_start", getMarkerPos "flyby_end", 100, "LIMITED", "RHS_T50_vvs_052", east] call BIS_fnc_ambientFlyBy;
	[getMarkerPos "flyby_start" vectorAdd [50,0,0], getMarkerPos "flyby_end" vectorAdd [50,0,0], 100, "LIMITED", "RHS_T50_vvs_052", east] call BIS_fnc_ambientFlyBy;
	[getMarkerPos "flyby_start" vectorAdd [0,-50,0], getMarkerPos "flyby_end" vectorAdd [0,-50,0], 100, "LIMITED", "RHS_T50_vvs_052", east] call BIS_fnc_ambientFlyBy;
	[getMarkerPos "flyby_start" vectorAdd [50,-50,0], getMarkerPos "flyby_end" vectorAdd [50,-50,0], 100, "LIMITED", "RHS_T50_vvs_052", east] call BIS_fnc_ambientFlyBy;
};
