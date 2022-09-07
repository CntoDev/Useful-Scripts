## What it is

This is a script for automatically assigning waypoints to AI groups and vehicles when one group/soldier spots an enemy (player).

Basically - this is for people who just want to place down some AI groups and not have to micromanage from Zeus. It's not as involved or perfect as LAMBS in that regard, but at least it orders AI groups around so they don't just stay standing or patrolling like a bunch of ignorants.

It however still tries to be GM-friendly, so that you can co-GM alongside it, ie. overriding some of the waypoint placement manually.

It's a simple script that should cover most basic needs, but feel free to make improvements or design a more complex and smart logic.

https://www.youtube.com/watch?v=H6ARCyxFEh4

## How it behaves

Waypoints are given only to groups that don't have any waypoints, or are on a repeating patrol (have `CYCLE` in their waypoints) - this should work for most common use cases while avoiding manual one-time GM waypoints.

Groups in `STEALTH` (blue face) or `CARELESS` are never touched, assuming that the GM has special plans for them.

Soldiers with disabled `PATH` or `MOVE` (ie. garrisoned units) are also left without waypoints, since they can't move, but the spotted enemy is at least revealed to them, so they'll engage. Same with static weapons (HMGs).

Only one waypoint is given, per group, per the unit entering a `COMBAT` (red face) state. Meaning only groups that were previously unaware are directed towards players. This is to avoid re-designating waypoints during combat by wrestling with the GM for control.  
With the A3AA AI, groups that have been out of engagement for ~90 seconds count as out of combat.

...

The AI groups are directed approx. to the position the players were spotted at, AI vehicles attempt to find a position that is slightly further away from players, but has direct line-of-sight onto the last known player position, assuming the vehicle is going to have a mounted weapon.  
Empty vehicles are (obviously) not redirected, only crewed ones.

Spotted targets (players) going faster than 10km/h are ignored, assuming that the players would be gone from that position by the time the AI groups get to them.

## How to use

In editor, go to Modules, A3AA, Execute Code and place it down.

Change these:

* Execute on (MP): Server only
* Exec for JIP players: no (unchecked)
* Environment: Unscheduled

And paste the following into the big code box, adjusting `alerter_radius` (on the top) to your liking.

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
            if (count waypoints _helpgrp > 1 && {(waypoints _helpgrp) findIf { waypointType _x == "CYCLE" } == -1}) then { continue };

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
