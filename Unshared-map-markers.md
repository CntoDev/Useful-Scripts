Unshared map markers
====================
This allows you to lock map markers to each player individually, so that they
are not shared with other players, simulating an actual paper map instead of
an all-seeing-all-knowing sattelite system. This can be useful for guerrila
missions, civilian missions, catastrophic/apocalypse scenarios, etc.

Optionally, you can prevent marker deletion to simulate an actual paper map
and a permanent marker pen.

Note that PLT/Squad/etc. markers are NOT included in this functionality,
only strictly user-placed markers. This also excludes anything Zeus-placed
or editor-placed, which will remain visible to all players.

If you wish to disable Plt/Squad/etc. tracking, disable it in the ACE3
Blue Force Tracking editor module.

How to use
----------
Put the code in an A3EE -> Execute Code editor module (Unscheduled environment)
or in `init.sqf`. Optionally, uncomment the marker-deletion-preventing feature.

```
if (isServer) then {
    addMissionEventHandler ["PlayerConnected", {
        params ["_id", "_uid", "_name", "_jip", "_owner"];
        [_id, {
            missionNamespace setVariable ["player_directplay_id", _this];
        }] remoteExec ["call", _owner];
    }];
};

if (hasInterface) then {
    0 = [] spawn {
        waitUntil { time > 0 };

        waitUntil { !isNil "player_directplay_id" };
        private _id = player_directplay_id;

        /* uncomment to disable delete key on map screen */
        //waitUntil { !isNull findDisplay 12 };
        //findDisplay 12 displayAddEventHandler ["KeyDown", {_this select 1 == 211}];

        /*
         * on every frame, delete user-placed markers that are not ours
         * (use parseNumber to round the nr in marker name to Number)
         */
        waitUntil {
            {
                if (parseNumber (_x select [15]) != _id) then {
                    deleteMarkerLocal _x;
                };
            } forEach (allMapMarkers select {
                _x find "_USER_DEFINED" == 0
            });
            false;
        };
    };
};
```
