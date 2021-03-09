if (!isServer) exitWith {};
/*
How to use:
Params:
0 - Table - any object really, but tables work best. Map will scale to fit entire marker area on table.
1 - Marker area - STRING of marker, i.e. "marker_0", will fit the LONGEST axis entirely on the table, always square.
Example = [table, "marker_0"] execVM fn_modelVillage;
*/

params ["_table","_marker"];
enableEnvironment false;
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

private _tableSize = (_tableWidth min _tableLength) / 2;    // Gets shortest edge of table    
                                                            // Why do I have to divide by 2???????????????
private _scale = _tableSize/_maxSize; // fit longest edge of marker on table

private _squareDist = sqrt (2*_maxSize*_maxSize);
private _objects = (nearestTerrainObjects [_markerPos, [],  _squareDist, false, true]) inAreaArray _marker;
private _roads = (_markerPos nearRoads _squareDist) inAreaArray _marker; // doesn't fucking work
private _objects = _objects + _roads;

private _vectorDiff = [0, 0, _tableHeight]; // neatly fit all the stuff on the top of the table


private _dummy = createVehicle ["Land_HelipadEmpty_F", _markerPos, [], 0, "CAN_COLLIDE"];
_dummy enableSimulation false;
_dummy setPosATL (getPosATL _dummy) vectorAdd [0, 0, 1];
_dummy setDir (markerDir _marker);

{
    if !(_x isKindOf "Man") then {
        private _relCentre = _dummy worldToModel (ASLtoAGL getPosASL _x);
        private _relVectDir = _dummy vectorWorldToModel (vectorDir _x);
        private _relVectUp = _dummy vectorWorldToModel (vectorUp _x);
        private _model = (getModelInfo _x)#1;
        private _tableObj = createSimpleObject [_model, [0, 0, 0], false];
        _tableObj setObjectScale _scale;
        private _newPos = _relCentre vectorMultiply _scale;
        _tableObj setPosASL AGLtoASL (_table modelToWorld (_newPos vectorAdd _vectorDiff));
        _tableObj setVectorDir (_table vectorModelToWorld _relVectDir);
        _tableObj setVectorUp (_table vectorModelToWorld _relVectUp);
        _tableObj setObjectScale _scale;

        _tableObjects pushBack _tableObj;
        systemchat str (getPos _tableObj);
    };
} forEach _objects;

private _resolution = 20;
private _step = 2/_resolution;
for "_posX" from -1 to 1 step _step do {
    for "_posY" from -1 to 1 step _step do {
        private _tablePos = [_posX*_tableSize, _posY*_tableSize, 0];
        private _worldPos = (_dummy modelToWorld (_tablePos vectorMultiply 1/_scale)); // divide by scale to scale back up
        _tablePos set [2, -(_worldPos#2 * _scale + _step)]; // Z flip? wtf?. Also offset by step = 1m cube length so top of cube is terrain height
        
        private _texture = surfaceTexture _worldPos;
        private _normal =  [surfaceNormal _worldPos, 180, 2] call BIS_fnc_rotateVector3D;
        private _groundObject =  createVehicle ["Land_VR_Shape_01_cube_1m_F", [0, 0, 0], [], 0, "CAN_COLLIDE"];
        _groundObject enableSimulation false;
        _groundObject setObjectScale _step;
        _groundObject setPosASL AGLtoASL (_table modelToWorld (_tablePos vectorAdd _vectorDiff));
        _groundObject setVectorUp (_table vectorWorldToModel _normal);
        for "_selection" from 0 to 6 do {
            _groundObject setObjectMaterialGlobal [_selection, "\a3\data_f\default.rvmat"];
            _groundObject setObjectTextureGlobal [_selection, _texture];
        };
        _groundObject setObjectScale _step;
        _tableObjects pushBack _groundObject;
        systemchat str ((getPos _groundObject)#2);
    };
};

_table setVariable ["seb_tableobjects", _tableObjects];
deleteVehicle _dummy;
