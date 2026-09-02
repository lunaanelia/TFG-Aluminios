import 'package:flutter/material.dart';
import '../models/habitacion.dart';
import '../models/producto.dart';
import '../repository/product_repository.dart';

mixin ProductCommuns <T extends StatefulWidget> on State<T>{

  List<Caracteristica> caracteristicas = [];
  List<Habitacion> habitaciones = [];

  final ProductRepository productRepository = ProductRepository();

  Future<void> loadHabitaciones()async{
    try{
      final data = await productRepository.getHabitaciones();
      if(mounted){
        setState(() {
          habitaciones= data;
        });
      }
    }catch (e) {
      debugPrint("Error: $e");
    }
  }
  void addCaracteristica() {
    setState(() {
      caracteristicas.add(
          Caracteristica(
              nombre: '',
              opciones: [
                Opcion(
                  nombre: '',
                  descripcion: '',
                  precioExtra: 0.0,
                  habitacionesRecomendadas:[],
                )
              ]
          )
      );
    });
  }

  Widget buildCaracteristicaCard(Caracteristica carac) {
    return Card(
      key: ObjectKey(carac),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildOpcionTextField(
                    'Nombre Característica',
                        (v) => carac.nombre = v,
                    initialValue: carac.nombre,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined, color: Colors.redAccent),
                  onPressed: () => setState(() => caracteristicas.remove(carac)),
                )
              ],
            ),
            const SizedBox(height: 15),
            const Text("Opciones:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

            ..._buildOpcionesList(carac),

            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => carac.opciones?.add(Opcion(nombre: ''))),
                icon: const Icon(Icons.add_circle, color: Color(0xFF222B6F)),
                label: const Text("Añadir Opción", style: TextStyle(color: Color(0xFF222B6F))),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOpcionesList(Caracteristica carac) {
    return (carac.opciones ?? []).map((opcion) {
      debugPrint("Opcion: ${opcion.nombre}, Recomendadas: ${opcion.habitacionesRecomendadas}");
      return Container(
        key: ObjectKey(opcion),
        margin: const EdgeInsets.only(top: 10, bottom: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200)
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildOpcionTextField(
                    "Nombre opción",
                        (v) => opcion.nombre = v,
                    initialValue: opcion.nombre,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: _buildOpcionTextField(
                    "Precio Extra",
                        (val) {
                      opcion.precioExtra = double.tryParse(val.replaceAll(',', '.'));
                    },
                    isNumber: true,
                    icon: Icons.euro,
                    initialValue: opcion.precioExtra?.toString() ?? "",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => carac.opciones?.remove(opcion)),
                )
              ],
            ),

            SizedBox(height: 20,),

            Builder(
              builder: (context) {
                bool esMovil = MediaQuery.of(context).size.width < 768;
                Widget widgetDescripcion = _buildOpcionTextField(
                    "Descripción de la opción",
                        (v) => opcion.descripcion = v,
                    obligatorio: false,
                    maxLines: esMovil ? 2 : 3,
                    initialValue: opcion.descripcion
                );

                Widget widgetCheckboxes = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("¿Recomendada?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...habitaciones.map((hab) {
                      final int habId = hab.id ?? 0;
                      return _buildCheckboxItem(
                        hab.nombre!,
                        opcion.habitacionesRecomendadas.contains(habId),
                            (bool? seleccionado) {
                          setState(() {
                            if (seleccionado == true) {
                              for (var otraOpcion in carac.opciones!) {
                                otraOpcion.habitacionesRecomendadas.remove(habId);
                              }
                              opcion.habitacionesRecomendadas.add(habId);
                            } else {
                              opcion.habitacionesRecomendadas.remove(hab.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                );

                if (esMovil) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widgetDescripcion,
                      const SizedBox(height: 15),
                      widgetCheckboxes,
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: widgetDescripcion,
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        flex: 2,
                        child: widgetCheckboxes,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      );
    }).toList();
  }

   Widget buildTextField(
       TextEditingController controller,
       String label, {bool obligatorio = true,
         IconData? icon, bool isNumber = false,
         int maxLines = 1, String? initialValue}
       ) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: (value) {
        if (obligatorio && (value == null || value.isEmpty)) {
          return 'Obligatorio';
        }

        if (isNumber && double.tryParse(value!.replaceAll(',', '.')) == null) {
          return 'Precio no válido';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: icon != null  ? Icon(icon) : null,
      ),
    );
  }

  Widget _buildOpcionTextField(String label, Function(String) onChange, {bool obligatorio = true, bool isNumber = false, IconData? icon, int maxLines = 1, String? initialValue}) {
    return  TextFormField(
      initialValue: initialValue,
      cursorColor: Color(0xFF222B6F),
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: (value) {
        if (obligatorio && (value == null || value.isEmpty)) {
          return 'Obligatorio';
        }

        if (isNumber && double.tryParse(value!.replaceAll(',', '.')) == null) {
          return 'Precio no válido';
        }
        return null;
      },
      decoration: InputDecoration(
        suffixIcon: icon != null  ? Icon(icon) : null,
        border: OutlineInputBorder(),

        labelText: label,

      ),
      onChanged: onChange,
    );

  }

  Widget _buildCheckboxItem(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              side: const BorderSide(color: Color(0xFF4A4458), width: 2),
              activeColor: const Color(0xFF222B6F),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF222B6F),
            ),
          ),
        ],
      ),
    );
  }
}