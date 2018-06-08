import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocation/geolocation.dart';

void main() async {

  Map _data = await getJson();
  List _quakeData = _data['features'];

  final GeolocationResult result = await Geolocation.isLocationOperational();
  if(result.isSuccessful) {

    Geolocation.currentLocation(accuracy: LocationAccuracy.best).listen((result2) {
      if(result2.isSuccessful) {
        double latitude = result2.location.latitude;
        double longitude = result2.location.longitude;

        _quakeData = sortDataByDist(_quakeData, latitude, longitude);
      }
    });
  } else {
    _quakeData = sortDataByDist(_quakeData, 47.6062, -122.3321);
  }

  runApp(MaterialApp(
    title: 'Quake App',
    home: Scaffold(
      appBar: AppBar(
        title: Text('Earthquakes Today: ${_quakeData.length}'),
        backgroundColor: Colors.blueGrey.shade300,
        centerTitle: true,
      ),
      body: Center(
        child: ListView.builder(
          itemCount: _quakeData.length,
          padding: EdgeInsets.all(10.0),
          itemBuilder: (BuildContext context, int position) {
            return Card(
              child: ListTile(
                title: Text('${
                    DateFormat('EEE, MMM d, h:mm a')
                        .format(
                        new DateTime.fromMillisecondsSinceEpoch(_quakeData[position]['properties']['time'])
                    )}, ${_quakeData[position]['distance'].toStringAsFixed(1)} km away'),
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade900,
                  child: Text('${_quakeData[position]['properties']['mag']}',
                    style: TextStyle(
                      fontSize: 15.0,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                subtitle: Text('${_quakeData[position]['properties']['title']}',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.blueGrey.shade900,
                  ),),
                  onTap: (){
                  _showOnTapMessage(context, '${_quakeData[position]['properties']['title']}\ncoords: ${_quakeData[position]['geometry']['coordinates'][1].toStringAsFixed(2)}, ${_quakeData[position]['geometry']['coordinates'][0].toStringAsFixed(2)}, depth: ${_quakeData[position]['geometry']['coordinates'][2].toStringAsFixed(2)}\n${_quakeData[position]['distance'].toStringAsFixed(1)} km away', '${_quakeData[position]['properties']['url']}');
                }
              )
            );
          },
        ),
      ),
    ),
  ));
}

void _showOnTapMessage(BuildContext context, String message, String moreInfoUrl) async {
  var alert = AlertDialog(
    title: Text('app'),
    content: Text(message),
    actions: <Widget>[
      FlatButton(
        onPressed: (){print('ok pressed'); Navigator.pop(context);},
        child: Text('OK!'),
      ),
      FlatButton(
        onPressed: (){print('more info pressed'); _launchURL(moreInfoUrl);},
        child: Text('More Info'),
      )
    ],
  );
  showDialog(context: context, builder: (context) => alert);
}

_launchURL(String url) async {
  debugPrint("launching Url");
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
Future<Map> getJson() async{
  var apiUrl = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';
  http.Response response = await http.get(apiUrl);
  return json.decode(response.body);
}

List sortDataByDist(List<dynamic> data, double lat1, double long1){

  double R = 6371.0;
  List<double> distances = new List(data.length);
  double latRad1 = degToRad(lat1);

  for(var i=0; i < data.length; i++){
      double lat2 = data[i]['geometry']['coordinates'][1];
      double long2 = data[i]['geometry']['coordinates'][0];

      double dLat = degToRad(lat2 - lat1);
      double dLong = degToRad(long2 - long1);
      double latRad2 = degToRad(lat2);
      double a = pow(sin(dLat/2), 2) + pow(sin(dLong/2), 2) * cos(latRad1) * cos(latRad2);
      double c = 2 * asin(sqrt(a));

      distances[i] = R * c;
      data[i]['distance'] = R * c;
  }

  data.sort((a,b) => a['distance'].compareTo(b['distance']));

  return data;
}

double degToRad(double degree){
  return (degree * pi / 180.0) % (2*pi);
}