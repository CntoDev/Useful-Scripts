/*
	spawns fire and smoke on the parent object, kills anyone that gets too close, and handles a little spread logic if it is the server.
*/

//--- used for fire
private _object = _this;
private _pos = [getPosWorld _object select 0, getPosWorld _object select 1, 0];
private _colorRed = 0.5;
private _colorGreen = 0.5;
private _colorBlue = 0.5;
private _timeout = 90;
private _particleLifeTime = (random(5)+5);
private _particleDensity = (random(0.5)+0.5);
private _particleSize = (random(8)+16);
private _particleSpeed = (random(0.5)+0.25);
private _effectSize = (random(2)+4);
private _orientation = (random(0.4)-0.2);
private _damage = 1;
private _damageRange = 25;

// used for smoke

private _smoke_colorRed = 0.5;
private _smoke_colorGreen = 0.5;
private _smoke_colorBlue = 0.5;
private _smoke_colorAlpha = 0.5;
private _smoke_particleLifeTime = 15;
private _smoke_particleDensity = (random(0.2)+0.1);
private _smoke_particleSize =  _particleSize;
private _smoke_particleSpeed =  1;
private _smoke_particleLifting =  2;
private _smoke_windEffect =  5;
private _smoke_effectSize = _effectSize;
private _smoke_expansion =  1;
private _smoke_height = ((boundingBox _object) select 2)*1.8;


//--- fire particle effect creation
private _emitter = "#particlesource" createVehicleLocal _pos;
_emitter setParticleParams [
	["\A3\data_f\ParticleEffects\Universal\Universal",16,10,32],
	"","billboard",1,_particleLifeTime,[0,0,0],
	[0,0,0.4*_particleSpeed],
	0,
	0.0565,
	0.05,
	0.03,
	[0.9*_particleSize,0],
	[[1*_colorRed,1*_colorGreen,1*_colorBlue,-0],
	[1*_colorRed,1*_colorGreen,1*_colorBlue,-1],
	[1*_colorRed,1*_colorGreen,1*_colorBlue,-1],
	[1*_colorRed,1*_colorGreen,1*_colorBlue,-1],
	[1*_colorRed,1*_colorGreen,1*_colorBlue,-1],
	[1*_colorRed,1*_colorGreen,1*_colorBlue,0]],
	[1],
	0.01,
	0.02,
	"",
	"",
	"",
	_orientation,
	false,
	-1,
	[[3,3,3,1]]
];

_emitter setParticleRandom [_particleLifeTime/4, [0.15*_effectSize,0.15*_effectSize,0],[0.2,0.2,0],0.4,0,[0,0,0,0],0,0,0.2];
if (_damage > 0) then {_emitter setParticleFire [0.6*_damage, _damageRange, 0.1];};
_emitter setDropInterval (1/_particleDensity);

//--- smoke particles
private _smoke = "#particlesource" createVehicleLocal [_pos select 0,_pos select 1,_smoke_height];
_smoke setParticleParams [["\A3\data_f\ParticleEffects\Universal\Universal_02",8,0,40,1],
"","billboard",1,_smoke_particleLifeTime,[0,0,0],
[0,0,2*_smoke_particleSpeed],
0,
0.05,
0.04*_smoke_particleLifting,0.05*_smoke_windEffect,
[1 *_smoke_particleSize + 1,1.8 * _smoke_particleSize + 15],
[[0.7*_smoke_colorRed,0.7*_smoke_colorGreen,0.7*_smoke_colorBlue,0.7*_smoke_colorAlpha],
[0.7*_smoke_colorRed,0.7*_smoke_colorGreen,0.7*_smoke_colorBlue,0.6*_smoke_colorAlpha],
[0.7*_smoke_colorRed,0.7*_smoke_colorGreen,0.7*_smoke_colorBlue,0.45*_smoke_colorAlpha],
[0.84*_smoke_colorRed,0.84*_smoke_colorGreen,0.84*_smoke_colorBlue,0.28*_smoke_colorAlpha],
[0.84*_smoke_colorRed,0.84*_smoke_colorGreen,0.84*_smoke_colorBlue,0.16*_smoke_colorAlpha],
[0.84*_smoke_colorRed,0.84*_smoke_colorGreen,0.84*_smoke_colorBlue,0.09*_smoke_colorAlpha],
[0.84*_smoke_colorRed,0.84*_smoke_colorGreen,0.84*_smoke_colorBlue,0.06*_smoke_colorAlpha],
[1*_smoke_colorRed,1*_smoke_colorGreen,1*_smoke_colorBlue,0.02*_smoke_colorAlpha],
[1*_smoke_colorRed,1*_smoke_colorGreen,1*_smoke_colorBlue,0*_smoke_colorAlpha]],
[1,0.55,0.35],
 0.1, 0.08*_smoke_expansion, "", "", ""];

_smoke setParticleRandom [_smoke_particleLifeTime/2, [0.5*_smoke_effectSize,0.5*_smoke_effectSize,0.2*_smoke_effectSize],
 [0.3,0.3,0.5],
 1, 0, [0,0,0,0.06],
 0, 0];
_smoke setDropInterval (1/_smoke_particleDensity);


//--- light (you only need a few lights for it to looks good so there is 1 in 20 chance the light is spawned)
private _light = "dummy";
if (random(20)<1) then {
	private _lightSize = (_particleSize + _effectSize)/2;
	_light = "#lightpoint" createVehicleLocal _pos;
	//_light setPos [_pos select 0,_pos select 1,(_pos select 2) + 0.5];
	_light setLightBrightness 1.0;
	_light setLightColor [1,0.65,0.4];
	_light setLightAmbient [0.15,0.05,0];
	_light setLightIntensity (50 + 100*_lightSize);
	_light setLightAttenuation [35,0,0.5,0];
	_light setLightDayLight true;
};

//--- timeout to delete fire & smoke

sleep _timeout;
// deletes light, fire and smoke
deleteVehicle _emitter;
deleteVehicle _smoke;
if !(_light isEqualTo "dummy") then {deleteVehicle _light;};

//some stuff that only needs to be done serverside
if (isServer) then {
	// trees do not have a cfgType, therefore typeOf returns blank. Houses and buildings don't so if type is "" then destroy!
	if (typeOf _object isEqualTo "") then {
		_object hideObjectGlobal true;
	} else {
		_object setDamage 1;
	};
	// removes this tree from the currently burning trees array so it is no longer able to spread fire
	Seb_currentlyBurningObjects deleteAt (Seb_currentlyBurningObjects find _object);
};
