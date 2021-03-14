/*
NEWER VERSION EXISTS HERE:
https://github.com/Seb105/Arma-Briefingtable/tree/main/example_mission/SebsBriefingTableStandaloneDemo.Altis
*/









if (!isServer) exitWith {};
/*
How to use:
Params:
0 - Table - any object really, but tables work best. Map will scale to fit entire marker area on table.
1 - Marker area - STRING of marker, i.e. "marker_0", will fit the LONGEST axis entirely on the table, always square.
2 - Terrain resolution - how many cubes each side to build it out of, so num of cubes is square of this. Higher values are laggy
3 - Scale override. By default it will fit on whatever table you pass it, but this will make it bigger thant he table if set to more than 1.
Example = [table, "marker_0", 20, 1] execVM "fn_modelVillage.sqf";

Warning: Bushes and stuff will still play sounds, so maybe use {enableEnvironment false;} to get rid of the noise.
*/

params ["_table", "_marker",["_terrainResolution",20],["_scaleOverride", 1]];
_table enableSimulationGlobal false;
private _tableObjects =  _table getVariable ["seb_tableobjects", []];
{deleteVehicle _x} forEach _tableObjects;

private _bbr = 2 boundingBoxReal _table;
private _p1 = _bbr#0;
private _p2 = _bbr#1;
private _tableWidth = abs ((_p2#0) - (_p1#0));
private _tableLength = abs ((_p2#1) - (_p1#1));
private _tableHeight = abs ((_p2#2) - (_p1#2));

private _markerPos = getMarkerPos _marker;
private _markerSize = getMarkerSize _marker;
private _maxSize = _markerSize#0 max _markerSize#1; // longest edge of marker

private _tableSize = ((_tableWidth min _tableLength) / 2) * _scaleOverride * 0.9;    // Gets shortest edge of table    
                                                            // Why do I have to divide by 2???????????????
private _scale = _tableSize/_maxSize; // fit longest edge of marker on table

private _squareDist = sqrt (2*_maxSize*_maxSize);
private _objects = (nearestTerrainObjects [_markerPos, [],  _squareDist, false, true]) inAreaArray _marker;
private _roads = (_markerPos nearRoads _squareDist) inAreaArray _marker; // doesn't fucking work
private _objects = _objects + _roads;



private _dummy = createVehicle ["Land_HelipadEmpty_F", _markerPos, [], 0, "CAN_COLLIDE"];
_dummy enableSimulation false;
_dummy setPosATL (getPosATL _dummy) vectorAdd [0, 0, 1];
_dummy setDir (markerDir _marker);

private _minHeight = 100000;
{
    _minHeight = _minHeight min (getPosASL _x)#2;
} forEach _objects;
private _zOffset = (getPosASL _dummy#2) - _minHeight;
private _vectorDiff = [0, 0, _tableHeight/2 + (_zOffset * _scale)]; // neatly fit all the stuff on the top of the table

{
    if !(_x isKindOf "Man") then {
        private _model = (getModelInfo _x)#1;
        if (_model != "") then {
            private _relCentre = _dummy worldToModel (ASLtoATL getPosWorld _x);
            private _relVectDir = _dummy vectorWorldToModel (vectorDir _x);
            private _relVectUp = _dummy vectorWorldToModel (vectorUp _x);
            private _tableObj = createSimpleObject [_model, [0, 0, 0], false];
            _tableObj setObjectScale _scale;
            private _scaledPos = _relCentre vectorMultiply _scale;
            private _newPos = (_table modelToWorldWorld (_scaledPos vectorAdd _vectorDiff));
            _tableObj = [[typeOf _x, _model, 0], _newPos, 0, false, true] call BIS_fnc_createSimpleObject;
            _tableObj setVectorDir (_table vectorModelToWorld _relVectDir);
            _tableObj setVectorUp (_table vectorModelToWorld _relVectUp);
            _tableObj setObjectScale _scale;
            _tableObjects pushBack _tableObj;
        };
    };
} forEach _objects;

private _step = 2/_terrainResolution;
private _cubeSize = _step * _tableSize * 1.2; // Give cubes a little overlap
for "_posX" from -1 to 1 step _step do {
    for "_posY" from -1 to 1 step _step do {
        private _tablePos = [_posX*_tableSize, _posY*_tableSize, 0];
        private _worldPos = (_dummy modelToWorld (_tablePos vectorMultiply 1/_scale)); // divide by scale to scale back up
        _tablePos set [2, -(_worldPos#2 * _scale + _cubeSize/2 + 0.5)]; // Z flip? wtf?. Also offset by _cubeOversize, which is normalised to 1 so moves cube down by its own length so top of cube is terrain

        private _texture = surfaceTexture _worldPos;
        private _normals = [];
        private _averageStep = _step/2;
        for "_normalX" from -2*_averageStep to 2*_averageStep step _averageStep do {
            for "_normalY" from -2*_averageStep to 2*_averageStep step _averageStep do {
                private _checkPos = _worldPos vectorAdd [_normalX, _normalY];
                _normals pushBack (surfaceNormal _checkPos);
            };
        };
        private _normal = [0, 0, 0];
        {
            _normal = _normal vectorAdd _x;
        } forEach _normals;
        _normal = _normal vectorMultiply (1/count _normals - 1);
        _normal = _normal vectorAdd vectorUp _table;
        private _groundObject =  createVehicle ["Land_VR_Shape_01_cube_1m_F", [0, 0, 0], [], 0, "CAN_COLLIDE"];
        _groundObject enableSimulationGlobal false;
        _groundObject setPosASL AGLtoASL (_table modelToWorld (_tablePos vectorAdd _vectorDiff));
        _groundObject setVectorUp _normal;
        _groundObject setVectorDir vectorDir _table;
        [_groundObject, _table] call BIS_fnc_attachToRelative;
        for "_selection" from 0 to 6 do {
            _groundObject setObjectMaterialGlobal [_selection, "\a3\data_f\default.rvmat"];
            _groundObject setObjectTextureGlobal [_selection, _texture];
        };
        _groundObject setObjectScale _cubeSize;
        _tableObjects pushBack _groundObject;
    };
};

_table setVariable ["seb_tableobjects", _tableObjects];
deleteVehicle _dummy;
