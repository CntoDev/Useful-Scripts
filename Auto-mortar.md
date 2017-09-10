Auto mortar script
==================

Put this code in init field of a mortar unit and group it with a spotter unit,
so that the spotter is the group leader. When the spotter unit gets engaged
or otherwise spots an enemy unit, the linked mortar will fire at the location
of the enemy unit, as approximated by the spotter.

Multiple motar units can be in the same group with one spotter. Similarly,
any other unrelated units can be in the same group (soldiers, vehicles, etc.),
to help the leader spot enemies. Note that it's still the group leader calling
the shots, so a subordinate spotter still has to actually report the unit to
its leader (meaning you can shoot them before they do).

Also, the leader can change freely over time and the mortar can be re-assigned
to a new group on the fly, using that group's leader as spotter.

See the comments in the code to better understand it / tune the values.
```
0 = this spawn {
    waitUntil {
        comment "wait 20-40 seconds between checking";
        sleep (20 + random 20);

        comment "if we're dead/deleted, stop this loop";
        if (!alive _this) exitWith {};

        comment "only if we're mortar - if we exited, stop this loop";
        if (!(vehicle _this isKindOf "StaticMortar")) exitWith {};

        private _leader = leader group _this;

        comment "2000m around the leader, seen within last 60secs";
        private _targets = _leader targets [true, 2000, [], 60];

        comment "transform targets into estimated positions";
        _targets = _targets apply { _leader getHideFrom _x };

        comment "only positions that we can reach";
        _targets = _targets select {
            _x inRangeOfArtillery [[_this], currentMagazine _this];
        };

        comment "if any targets passed all checks, pick one at random";
        if (count _targets > 0) then {
            private _tgt = selectRandom _targets;

            comment "fire 1-3 rounds from currently selected magazine";
            _this commandArtilleryFire [_tgt, currentMagazine _this, ceil random 3];

            comment "cool down a bit, wait 30-60 seconds after firing";
            sleep (30 + random 30);
        };
    };
};
```

To use this script from Zeus on a new mortar unit, use "Execute code" module
and replace `this` on the first line for `(_this select 1)`.
