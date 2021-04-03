/*
IF YOU PLAN ON SPAWNING UNITS VIA ZEUS WITH A FIRE RUNNING:
YOU MUST USE WERTHLESS HEADLESS CLIENT SCRIPT!! IF YOU ATTEMPT TO ZEUS WITH A FIRE RUNNING BUT WITHOUT WERTHLESS HC SCRIPT THEN YOU WILL GET 2FPS!
HC SCRIPT MOVES AI FROM YOUR COMPUTER TO THE HC, GIVING YOU YOUR FPS BACK AFTER A SHORT TIME.
https://steamcommunity.com/sharedfiles/filedetails/?id=459317544

NEVER USE IN SINGLEPLAYER WITH AI UNITS PRESENT
EXECUTE ON SERVER ONLY:
[{[obj,1e39,1e39,false,2.5,35,650] execVM "Seb_fn_forestFire.sqf";}] remotExec ["call",2];

In order to set a number to unlimited in params, use 1e39.

Params:
0 = Starting point - object (required)
1 = Max fire spread distance from fire start. Optional - Number  - Default unlimited
2 = Max burning trees. Fire spread will pause while tree burns out and then automatically resume. Optional - Number - Default unlimtied. Script will pause until < this number
3 = Can burn buildings? Optional - Boolean - Default false
4 = Spread speed (in metres per second). Optional - Number - Default 2.5
5 = Max fire jump distance - Optional - Number - Default 35m
6 = Only spread if within this distance of players - Optional - Number - Default 650m

You may start multiple fires at once, however it will only use the parameters of the first fire. For example if you spawn one with a range of 650m, then one with 1000m, the second one will still used
650m.
*/
if (!isServer) exitWith {};
if (!canSuspend) exitWith {};
params ["_startObj",["_distanceFromStart",1e39],["_maxBurningTrees",1e39],["_canBurnBuildings",false],["_spreadSpeed",2.5],["_fireSpreadDist",35],["_playerSpreadDist",650]];


private _burnableObjectTypes = [];
if (_canBurnBuildings) then {
    _burnableObjectTypes = ["TREE","SMALL TREE","BUSH","HOUSE","FENCE","CHURCH","CHAPEL","TOURISM","BUSSTOP","FUELSTATION","BUILDING"];
} else {
    _burnableObjectTypes = ["TREE","SMALL TREE","BUSH"];
};

// Adds the centre of this fire to an array of fire centres, this is used to check distances to fire centres for the fire max range inside of a single while loop.
if (isNil "Seb_fireCentres") then {
    Seb_fireCentres = [];
};
Seb_fireCentres pushBackUnique (getPos _startObj);


if (isNil "Seb_burnedObjects") then{
    Seb_burnedObjects = [];
};

// builds array of nearby burnable objects to start the while loop
private _newLoopEligbleBurnObjects = nearestTerrainObjects [_startObj,_burnableObjectTypes,_fireSpreadDist,false,true];

// Creates an empty array of burning trees if there is not one already.
if (isNil "Seb_currentlyBurningObjects") then {
    Seb_currentlyBurningObjects = [];
};


// if Seb_currentlyBurningObjects is more than 0, then there is already a fire. Therefore, set the trees on fire, add them to the burning trees array,
// then terminate this script and let the while loop of the existing fire handle the spread. This stops multiple while loops being necessary
if (count Seb_currentlyBurningObjects > 0) exitWith {
    sleep 1;
    {
        private _treeToBurn = _x;
        _treeToBurn remoteExec ["CNTO_fnc_fireFunction"];
        Seb_burnedObjects pushBackUnique _treeToBurn;
        Seb_currentlyBurningObjects pushBackUnique _treeToBurn;
    } forEach _newLoopEligbleBurnObjects;
};

{
    private _treeToBurn = _x;
    _treeToBurn remoteExec ["CNTO_fnc_fireFunction"];
    Seb_burnedObjects pushBackUnique _treeToBurn;
    Seb_currentlyBurningObjects pushBackUnique _treeToBurn;
} forEach _newLoopEligbleBurnObjects;

// time = distance/speed. Arbitrarily multiplied by two as it's slow af.
private _spreadSleep = _fireSpreadDist/(_spreadSpeed*2);
private _eligbleBurnObjects = [];

//inversely proportional to radius of spread distance, this reduces the amount of objects checked as each tree has a objects overlap for less overhead.
private _spreadDensityPercent = ((10/count _newLoopEligbleBurnObjects)*100);

//while loop for fire spread. When no more objects are available to be burned, the script ends.
while {count Seb_currentlyBurningObjects > 0} do {
    private _startTime = time;
    private _spreadChance = 25-(rain*23);
    if (count Seb_currentlyBurningObjects < _maxBurningTrees) then {
        private _newEligbleBurnObjects = [];
        // private _startOfFireLoop = time;
        {
            private _treeToBurn = _x;
            if ((count _eligbleBurnObjects) < 150 OR random(100)<_spreadChance) then {
                _treeToBurn remoteExec ["CNTO_fnc_fireFunction"];
                Seb_burnedObjects pushBackUnique _treeToBurn;
                Seb_currentlyBurningObjects pushBackUnique _treeToBurn;
            };
        } forEach _eligbleBurnObjects;
        // systemChat str ["1. BURNING TREES",(time - _startOfFireLoop)];
        // private _timeStartOfNearbyTrees = time;
        private _treesToCheck = Seb_currentlyBurningObjects select {
            random(100)<_spreadDensityPercent
            &&
            { ((_x distance2D ([allPlayers,_x] call BIS_fnc_nearestPosition)) < _playerSpreadDist)
            &&
            ((_x distance2D ([Seb_fireCentres, _x] call BIS_fnc_nearestPosition)) < _distanceFromStart) }
        };
        {
            private _nearbyTrees = (nearestTerrainObjects [_x,_burnableObjectTypes,_fireSpreadDist,false]);
            {
                _newEligbleBurnObjects pushBackUnique _x;
            } forEach _nearbyTrees;
        } forEach _treesToCheck;
        // systemChat str ["2. NEW BURNING TREES",(time - _timeStartOfNearbyTrees),count _treesToCheck];
        // private _timeStartOfTreeSelection = time;
        _eligbleBurnObjects = _newEligbleBurnObjects select {!(_x in Seb_burnedObjects)};
        // systemChat str ["3. FILTER BURNING TREES",(time - _timeStartOfTreeSelection)];

    };
    // systemchat str [count Seb_currentlyBurningObjects,count _eligbleBurnObjects];
    private _lag = time - _startTime;
    sleep (_spreadSleep - _lag);

    // systemChat str ["ActualVsTarget",(time - _startTime),_spreadSleep];

};
// systemChat "Forest Fire: Exited while loop";
Seb_fireCentres = [];
