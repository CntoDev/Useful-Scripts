# Vanilla(-ish) AI reinforce script

This adds waypoints to idle groups, leading them towards the last known enemy
position. This is done only once per `COMBAT` (red face in Zeus UI) - a group
which exits combat (back to `AWARE` / yellow face) can then call for
reinforcements again once it again enters combat and spots an enemy.

The script is not perfect, but fairly simple and should work well for Zeus-less
or Zeus-light missions where a GM doesn't want to do everything all the time.

Groups in `CARELESS` or `STEALTH` will be left alone. Groups with waypoints
will also not be touched (to avoid conflicts with GM), except for groups which
have a `CYCLE` waypoint - these are considered idle patrols and will get their
current waypoints deleted, replaced with the one pointing the group towards
spotted enemies.

Vehicles will be directed to an *appropriate* position close to where the enemy
was spotted, ideally with eyes on that position. They'll try to avoid forests,
insides of buildings, the sea, etc.

Air and Sea assets are completely excluded - both from having reinforcements
called upon them, and for being considered as reinforcing elements. It's assumed
that the mission maker / GM wants these for something special.

Stationary groups (garrisoned with disabled `PATH` or `MOVE` or static weapons)
will just be alerted to the enemy's position (via `reveal`) and will receive no
waypoints.

## How to use

1. Place down A3AA -> Execute Code module and double click on it
1. Set "Execute on (MP)" to "Server only"
1. Un-check "Execute for JIP players"
1. Set "Environment" to "Unscheduled"
1. Copy/paste the following into the "Code" box
1. (Optionally tweak the alert/reinforcement radius, centered on the requestor.)

```sqf
// distance from which groups will come to help
alerter_radius = 1000;

[
    {
        allGroups;
    },
    {
        private _leader = leader _this;

        // call for help only once per COMBAT
        private _called_help = _this getVariable ["alerter_called_help", false];
        if (behaviour _leader != "COMBAT") exitWith {
            _this setVariable ["alerter_called_help", nil];
        };
        if (_called_help) exitWith {};

        // find a precise enemy position
        private ["_tgt", "_tgtpos"];
        {
            if (!(_x isKindOf "Land") || speed _x > 10) then { continue };
            (_leader targetKnowledge _x) params [
                "_kngrp", "_knunit", "_lastseen", "_lastendg", "_side", "_poserr", "_pos"
            ];
            if (_poserr < 1) exitWith {
                _tgt = _x;
                _tgtpos = _pos;
            };
        } forEach (_leader targets [true, 0, [], 10]);
        if (isNil "_tgt") exitWith {};

        // alert nearby friendly groups
        {
            private _helpgrp = group _x;
            if (side _leader != side _x) then { continue };
            if (!(behaviour _x in ["SAFE","AWARE","COMBAT"])) then { continue };
            // waypoints, but no CYCLE waypoint
            if (currentWaypoint _helpgrp < count waypoints _helpgrp && 
                {(waypoints _helpgrp) findIf { waypointType _x == "CYCLE" } == -1}) then { continue };

            if (_x isKindOf "CAManBase") then {
                // run all this only for a grp leader, if on foot
                if (leader _helpgrp != _x) then { continue };
                // skip soldiers in vehicles - vehicles are handled separately
                if (vehicle _x != _x) then { continue };
                if (behaviour _x in ["SAFE","STEALTH"]) then {
                    [_helpgrp, "AWARE"] remoteExec ["setBehaviour"];
                };
                if (formation _x != "WEDGE") then {
                    [_helpgrp, "WEDGE"] remoteExec ["setFormation"];
                };

            } else {
                // vehicle; use COMBAT for faster spotting + offroad movement
                // don't reveal the target, the vehicle would refuse to move
                if (behaviour _x != "COMBAT") then {
                    [_helpgrp, "COMBAT"] remoteExec ["setBehaviour"];
                };
            };

            if (speedMode _x != "FULL") then {
                [_helpgrp, "FULL"] remoteExec ["setSpeedMode"];
            };

            if (!(_x checkAIFeature "PATH") || !(_x checkAIFeature "MOVE") || _x isKindOf "StaticWeapon") then {
                // stationary, just reveal
                _helpgrp reveal _tgt;
                continue;
            };

            // delete existing WPs; add WP to the last known pos
            for "_i" from count waypoints _helpgrp - 1 to 0 step -1 do {
                deleteWaypoint [_helpgrp, _i];
            };
            if (!(_x isKindOf "CAManBase")) then {
                // as a vehicle, find a suitable parking place and go there
                // optimized for speed, takes ~ 0.8ms
                private _places = selectBestPlaces [_tgtpos, 100, "(1-forest)*(1-trees)*(1-sea)*(1-houses)", 40, 100];
                _places = _places apply { [_x#1,_x#0] };
                _places sort false;
                private _final = {
                    (_x select 1) params ["_xcord", "_ycord"];
                    private _surf = lineIntersectsSurfaces [_tgtpos, AGLtoASL [_xcord,_ycord,1], _tgt, objNull, true, 1, "FIRE"];
                    if (_surf isEqualTo []) exitWith { [_xcord,_ycord,0 ] };
                } forEach _places;
                if (isNil "_final") then {
                    _final = _tgtpos;
                };
                private _wp = _helpgrp addWaypoint [AGLtoASL _final, -1];
                _wp setWaypointCompletionRadius 0.5;
                _wp setWaypointCombatMode "RED";
            } else {
                // as infantry, just search and destroy around
                private _wp = _helpgrp addWaypoint [ASLtoAGL _tgtpos, 50];
                _wp setWaypointType "SAD";
                _wp setWaypointCombatMode "RED";
            };
        } forEach (_leader nearEntities [["CAManBase","Car","Tank","StaticWeapon"], alerter_radius]);

        _this setVariable ["alerter_called_help", true];
    },
    10
] call a3aa_fnc_balancePerFrame;
```
