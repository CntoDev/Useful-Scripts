/*
Draws a profile to the map of how many objects are within viewing distance of that area. Can roughly be considered to correspond to FPS.

Params: 
_gridSize = size of resulting grid on map. 250m seems to be a sweet spot of useful result and fast running. (m)
_viewDistance = search radius for objects. Probably best to set to the view distance of the player for useful results (m)

Example:
[250, 1000] call fnc_perfProfileMap;
*/
_this spawn {
	params ["_gridSize","_viewDistance"];
	/*
	Objects per map:
	https://community.bistudio.com/wiki/nearestTerrainObjects

	Land area sizes (does not include oceans):
	Altis land area size: 270km**2
	Tanoa land area Size: 100km**2
	*/
	private _altisAvgObjectsPerKm2 = 6715;
	private _tanoaAvgObjectsPerKm2 = 16911;

	private _searchArea = pi*(_viewDistance/1000)^2;
	private _relDensityMin = _altisAvgObjectsPerKm2 * _searchArea;
	private _relDensityMax = _tanoaAvgObjectsPerKm2 * _searchArea;

	private _worldSize = worldSize;

	private _start = _gridSize/2;
	private _end = _worldSize-_start;

	for "_posX" from _start to _end step _gridSize do {
		systemChat str (_posX/_worldSize)*100;
		for "_posY" from _start to _end step _gridSize do {
			private _pos = [_posX,_posY];
			private _numObjects = count (nearestTerrainObjects [_pos, [], _viewDistance, false, true]);
			private _alpha  = linearConversion [_relDensityMin, _relDensityMax, _numObjects, 0, 1, true];
			private _marker = createMarker [str _pos, _pos];
			_marker setMarkerShape "RECTANGLE";
			_marker setMarkerColor "ColorRed";
			_marker setMarkerSize [_gridSize/2, _gridSize/2];
			_marker setMarkerAlpha _alpha;	
		};
	};
};