This script announces, on Global chat, whenever a player friendly-kills
another player, optionally killing the shooter. It doesn't work 100% of the
time due to ie. victim dying via ACE medical when the engine cannot know
the original shooter, but it works in most normal situations.

Put into init.sqf or in Execute Code editor module (scheduled env).

```
if (hasInterface) then {
    waitUntil { !isNull player };
    player addEventHandler ["Killed", {
        private _instigator = _this select 2;
        if (!isNull _instigator && (_instigator != player) && isPlayer _instigator
            && side player getFriend side _instigator >= 0.6) then {
            [player, format [
                "%1 friendly-killed %2", name _instigator, name player
            ]] remoteExec ["globalChat"];
            _instigator setDamage 1;
        };
    }];
};
```

To disable the killing (leave just message), remove the last `_instigator setDamage 1;` line.
