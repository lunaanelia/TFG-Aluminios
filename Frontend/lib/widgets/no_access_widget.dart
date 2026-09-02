import 'package:flutter/material.dart';

class NoAccessWidget extends StatelessWidget {
  const NoAccessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                    onPressed: (){Navigator.pop(context);},
                    icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF222B6F)),
                ),
              ],
            ),
            Spacer(),
            Text(
              "ACCESO RESTRINGIDO",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF222B6F),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40,),
            Text(
              "Su cuenta no tiene permisos para estar aquí.\nSi cree que es un error contacte con el administrador",
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 20,
                color: Color(0xFF222B6F),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 60,),
            const Icon(Icons.lock, size: 150, color: Color(0xFF222B6F)),
            SizedBox(height: 40,),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222B6F),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, 'login/'),
              child: const Text('Volver al Login'),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}