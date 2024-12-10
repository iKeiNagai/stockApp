import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Home'),),
      body: Center(
        child: Column(
          children: <Widget>[
            OutlinedButton(
              onPressed: (){
              },
              child: const Text('login')
              ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: (){}, 
              child: const Text('watchlist')
              ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: (){}, 
              child: const Text('newsfeed')
              ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: (){}, 
              child: const Text('profile')
              ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

}