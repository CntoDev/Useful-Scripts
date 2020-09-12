/*
This script adds grey box map markers over objects in a given 3Den layer, exactly like how buildings already part of the map are displayed.
USAGE: Move any object you want adding to the map to an 3den layer called "EdenMapObjects"
The, paste the following code in the mission init or the init of any permanent object:
*/

if (isServer) then {
	private _EdenObjectNum = 0;
	{
   	private _name = (["3DenObjectMarker",_EdenObjectNum] joinstring "_");
   	private _bbr = 0 boundingBoxReal _x;
   	private _p1 = _bbr select 0;
   	private _p2 = _bbr select 1;
   	private _maxWidth = abs ((_p2 select 0) - (_p1 select 0));
   	private _maxLength = abs ((_p2 select 1) - (_p1 select 1));
   	private _Direction = getDir _x;
   	createMarker [_name, _x];
   	_name setMarkerShape "RECTANGLE";
   	_name setMarkerBrush "SolidFull";
   	_name setMarkerSize [(_maxWidth / 2),(_maxLength / 2)];
   	_name setMarkerDir _Direction;
   	_name setMarkerAlpha 1;
   	_name setmarkerColor "ColorGrey";
   	_EdenObjectNum = _EdenObjectNum+1;
	} forEach ((getMissionLayerEntities "EdenMapObjects") select 0);
};
