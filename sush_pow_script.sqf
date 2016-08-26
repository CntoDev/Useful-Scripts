/*
	File: sush_pow_script.sqf
	Author: Sushi

	Description:
	Z wyznaczonej jednostki "tworzy" zakladnika którego gracze mogą uwolnić.

	Parameter(s):
	0: OBJECT - Nazw jednostki
	1 (optional): STRING - "imię" zakladnika

	Returns:
	Nothing
	
	Example:
	0 = [this,"Zakładnik 1"] execVM "sush_pow_script.sqf";
*/


//-->Fncs
sush_pow_fn_setBeh = {
	private _p = _this select 0;
	private _state = _this select 1;
	
	
	switch (_state) do {
		case 0: {
			_p setBehaviour "AWARE";
			_p disableAi "MOVE";
		};
		case 1: {
			_p setBehaviour "CARELESS";
			_p setCombatMode "BLUE";
			_p enableAi "MOVE";
		};
		case 2: {
			private _veh = _this select 2;
			_p enableAi "MOVE";
			_p assignAsCargo _veh;
			[_p] orderGetIn true;
		};
		case 3: {
			unassignVehicle _p;
			[_p] orderGetIn false;
			doGetOut _p;
			_p disableAi "MOVE";
		};
	};
};


sush_pow_fn_addActionGetOut = {
	private _veh = _this select 0;
	private _p = _this select 1;
	
	if(isNull _veh) exitWith {};
	private _actTxt = format ["<t color='#ff8133'>Order get out (%1)</t>", name _p];
	private _actionId = _veh addAction [_actTxt,sush_pow_fn_getOut,_p,6,true,true];
};

sush_pow_fn_remAction = {
		private _veh = _this select 0;
		private _id = _this select 1;
		
		_veh removeAction _id;
};

sush_pow_fn_getOut = {
	private _veh = _this select 0;
	private _p = _this select 3;
	private _id = _this select 2;
	
	
	[[_p,3,_veh],"sush_pow_fn_setBeh",false,false] spawn BIS_fnc_mp;
	[[_veh,_id],"sush_pow_fn_remAction",true,true] spawn BIS_fnc_mp;
	
};

sush_pow_fn_getIn = {
	private _veh = cursortarget;
	private _parm = _this select 3;
	private _p = _parm select 0;
	private _r = _parm select 1;
	private _id = _this select 2;
	private _rescState = _r getVariable ["sush_pow_resc",[_p]];
	
		
	[[_p,2,_veh],"sush_pow_fn_setBeh",false,false] spawn BIS_fnc_mp;
	_p setVariable ["sush_pow_state",2,true];
	_rescState = _rescState - [_p];
	_r setVariable ["sush_pow_resc",_rescState];
	
	_veh setVariable ["sush_pow_veh",true,true];
	player removeAction _id;
	
	waitUntil {_p in _veh};
	[[_veh,_p],"sush_pow_fn_addActionGetOut",true,true] spawn BIS_fnc_mp;
};

sush_pow_fn_changeStance = {
	private _p = _this select 0;
	private _r = _this select 1;
	private _cond  = _this select 2;
	
	while _cond do {
		
		switch (stance _r) do {
			case "STAND": { 
				if (unitPos _p == "MIDDLE") then { [[_p,"DOWN"],"setUnitPos",false,false,true] call BIS_fnc_mp; sleep 1; };
				[[_p,"UP"],"setUnitPos",false,false,true] call BIS_fnc_mp;
			};
			case "CROUCH": { 
				if (unitPos _p == "DOWN") then { [[_p,"UP"],"setUnitPos",false,false,true] call BIS_fnc_mp; sleep 1; };
				[[_p,"MIDDLE"],"setUnitPos",false,false,true] call BIS_fnc_mp;
			};
			case "PRONE": { [[_p,"DOWN"],"setUnitPos",false,false,true] call BIS_fnc_mp; };
		};
		private _stance = stance _r;
		waitUntil {stance _r != _stance};
	};
	if (True) exitwith {};
	
};

sush_pow_fn_followAction = {
		private _p = _this select 0;
		private _r = _this select 1;
		private _rescState = _r getVariable ["sush_pow_resc",[]];
		private _actCond = "(cursortarget isKindOf 'LandVehicle' || cursortarget isKindOf 'Helicopter' || cursortarget isKindOf 'Ship' || cursortarget isKindOf 'Plane') && (_this distance cursortarget < 5)";
		private _actTxt = format ["<t color='#ff8133'>Order get in (%1)</t>", name _p];
		private _actionId = _r addAction [_actTxt,sush_pow_fn_getIn,[_p,_r],6,true,true,"",_actCond];
		[[_p,1],"sush_pow_fn_setBeh",false,false] spawn BIS_fnc_mp;
		_p setVariable ["sush_pow_state",1,true];
		
		_rescState = _rescState + [_p];
		_r setVariable ["sush_pow_resc",_rescState];
		
		[_p,_r,{ _p getVariable ["sush_pow_state",0] == 1 && alive _r}] spawn sush_pow_fn_changeStance;
		
		while {_p getVariable ["sush_pow_state",0] == 1 && alive _r} do {	
			sleep 2;
			waitUntil { sleep 0.2; _p distance _r > 5 || !alive _r || _p getVariable ["sush_pow_state",0] != 1}; 
			[[_p,getPos _r],"move",false,false] spawn BIS_fnc_mp;
			
		};
		_r removeAction _actionId;
		if (!alive _r) then {
			[_p,_r] call sush_pow_fn_stopAction;
		};
};

sush_pow_fn_stopAction = {
		private _p = _this select 0;	
		private _r = _this select 1;
		private _rescState = _r getVariable ["sush_pow_resc",[_p]];
		[[_p,0],"sush_pow_fn_setBeh",false,false] spawn BIS_fnc_mp;
		_p setVariable ["sush_pow_state",2,true];
		
		_rescState = _rescState - [_p];
		_r setVariable ["sush_pow_resc",_rescState];
};


sush_pow_fn_takeAction = {
	private _p = _this select 0;
	private _r = _this select 1;
	private _pow_state = _p getVariable ["sush_pow_state",0]; //0- cuffed, 1-following, 2-waiting 
	
	switch (_pow_state) do {
		case 0: {
			[[_p,"Acts_AidlPsitMstpSsurWnonDnon_out"],"playMove",false,false] spawn BIS_fnc_mp;
			[_p,_r] call sush_pow_fn_followAction;
		};
		case 1: {
			[_p,_r] call sush_pow_fn_stopAction;
		};
		case 2: {
			[_p,_r] call sush_pow_fn_followAction;
		}
	};

};




//--> Main
//player createDiaryRecord ["Diary", ["Zakładnicy", "Wszystkie akcje związane z zakładnikami znajdują się w menu akcji pod scrollem. Dostępne akcje:<br/>-Uwolnij<br/>-Za mną<br/>-Czekaj<br/>-Wsiądź (dostępna na dwolnym pojeździe, zakładnik nie może być w trybie 'Czekaj')<br/>-Wysiądź<br/><br/>Uwolnieni zakładnicy dynamicznie przyjmują pozycje gracza (prone, crouch, stand)"]];

private _pow = _this select 0;
private _pow_state = _pow getVariable ["sush_pow_state",0]; //0-cuffed, 1-following, 2-waiting, 3-invehicle
private _actionId = _pow addAction ["<t color='#ff8133'>Release</t>",sush_pow_fn_takeAction,nil,6,true,true,"","_this distance _target < 3"];

if ((count _this) == 2 ) then { _pow setName (_this select 1);};

//private _actCond = "_obj1 = nearestObjects [_this, ['LandVehicle','Helicopter','Ship','Plane'], 10];  _this ";


if (isServer && _pow_state == 0) then {
	
	_pow playMove "Acts_AidlPsitMstpSsurWnonDnon_loop";
	_pow setVariable ["sush_pow_state",0,true];
	_pow disableAi "MOVE";
	[_pow] joinSilent grpNull;
};


waitUntil {
	_pow getVariable ["sush_pow_state",0] > 0
};

while {true} do {
	private _pow_state = _pow getVariable ["sush_pow_state",0]; //0- cuffed, 1-following, 2-waiting
	switch (_pow_state) do {
		case 1: {
			_pow setUserActionText [_actionId, "<t color='#ff8133'>Wait here</t>"];
		};
		case 2: {
			_pow setUserActionText [_actionId, "<t color='#ff8133'>Follow me</t>"];
		}
	};
	sleep 1;
};
