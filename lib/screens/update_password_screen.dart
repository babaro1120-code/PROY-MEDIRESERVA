import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/medireserva_ui.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;
  @override State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}
class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _key = GlobalKey<FormState>(); final _p = TextEditingController(); final _c = TextEditingController(); bool _busy=false; String? _error;
  @override void dispose(){_p.dispose();_c.dispose();super.dispose();}
  Future<void> _save() async { if(!_key.currentState!.validate()) return; setState(()=>_busy=true); try { await AuthService(Supabase.instance.client).updatePassword(_p.text); if(mounted){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente.'))); widget.onFinished(); }} on AuthException catch(e){if(mounted)setState(()=>_error=e.message);} catch(_){if(mounted)setState(()=>_error='No fue posible actualizar la contraseña.');} finally{if(mounted)setState(()=>_busy=false);} }
  @override Widget build(BuildContext context)=>MediReservaPage(title:'Nueva contraseña',step:'',child:Form(key:_key,child:Column(children:[
    const Text('Define una nueva contraseña para tu cuenta.',textAlign:TextAlign.center,style:TextStyle(color:kMediMuted,fontSize:13.6)),const SizedBox(height:18.2),
    TextFormField(controller:_p,obscureText:true,validator:(v)=>v==null||v.length<6?'Mínimo 6 caracteres':null,decoration:const InputDecoration(labelText:'Nueva contraseña',border:OutlineInputBorder())),const SizedBox(height:11.7),
    TextFormField(controller:_c,obscureText:true,validator:(v)=>v!=_p.text?'Las contraseñas no coinciden':null,decoration:const InputDecoration(labelText:'Confirmar contraseña',border:OutlineInputBorder())),
    if(_error!=null)Padding(padding:const EdgeInsets.only(top:9),child:Text(_error!,style:const TextStyle(color:Colors.red,fontSize:12.8))),const SizedBox(height:15.6),MediButton(label:_busy?'Guardando...':'Guardar contraseña',onPressed:_busy?null:_save)
  ])));
}
