import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'ludo_room_screen.dart';

class LudoLobbyScreen extends StatefulWidget {
  const LudoLobbyScreen({super.key});

  @override
  State<LudoLobbyScreen> createState() =>
      _LudoLobbyScreenState();
}

class _LudoLobbyScreenState extends State<LudoLobbyScreen> {
final SupabaseClient _supabase =
SupabaseService.client;

final TextEditingController _roomCodeController =
TextEditingController();

bool _isCreatingRoom = false;
bool _isJoiningRoom = false;

String get _userId {
return _supabase.auth.currentUser?.id ?? '';
}

@override
void dispose() {
_roomCodeController.dispose();
super.dispose();
}

Future<void> _createRoom() async {
if (_isCreatingRoom || _isJoiningRoom) return;

if (_userId.isEmpty) {
_showMessage('ابتدا وارد حساب شوید.');
return;
}

setState(() {
_isCreatingRoom = true;
});

try {
await _supabase
.from('ludo_players')
.delete()
.eq('user_id', _userId);

final roomCode =
_generateRoomCode();

final room = await _supabase
.from('ludo_rooms')
.insert({
'room_code': roomCode,
'host_id': _userId,
'status': 'waiting',
'max_players': 4,
'current_player': 0,
'dice': 0,
'game_state': {
'positions': {
'0': [-1, -1, -1, -1],
'1': [-1, -1, -1, -1],
'2': [-1, -1, -1, -1],
'3': [-1, -1, -1, -1],
}
}
})
.select()
.single();

final roomId =
room['id'].toString();

await _supabase
.from('ludo_players')
.insert({
'room_id': roomId,
'user_id': _userId,
'player_index': 0,
'player_name': 'بازیکن ۱',
'color': 'red',
'is_ready': true,
'is_connected': true,
});

if (!mounted) return;

setState(() {
_isCreatingRoom = false;
});

_openRoom(roomId);

} catch (e) {

if (!mounted) return;

setState(() {
_isCreatingRoom = false;
});

_showMessage(
'ساخت اتاق انجام نشد',
);
}
}


Future<void> _joinRoom() async {
if (_isCreatingRoom || _isJoiningRoom) return;

final code =
_roomCodeController.text.trim();

if (code.isEmpty) {
_showMessage(
'کد اتاق را وارد کنید.',
);
return;
}

setState(() {
_isJoiningRoom = true;
});

try {

final room = await _supabase
.from('ludo_rooms')
.select()
.eq(
'room_code',
code,
)
.maybeSingle();


if (room == null) {
throw Exception();
}


final roomId =
room['id'].toString();


await _supabase
.from('ludo_players')
.insert({
'room_id': roomId,
'user_id': _userId,
'player_index': 1,
'player_name': 'بازیکن',
'color': 'green',
'is_ready': true,
'is_connected': true,
});


if (!mounted) return;


setState(() {
_isJoiningRoom = false;
});


_openRoom(roomId);


} catch(e){

if (!mounted) return;

setState(() {
_isJoiningRoom=false;
});

_showMessage(
'ورود به اتاق انجام نشد.',
);
}
}


String _generateRoomCode(){

final number =
DateTime.now()
.millisecondsSinceEpoch %
900000;

return
(number + 100000)
.toString();
}
void _openRoom(String roomId) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => LudoRoomScreen(
roomId: roomId,
),
),
);
}


void _showMessage(String message) {

if (!mounted) return;

ScaffoldMessenger.of(context)
.showSnackBar(
SnackBar(
content: Text(message),
behavior:
SnackBarBehavior.floating,
),
);
}



@override
Widget build(
BuildContext context,
) {

final busy =
_isCreatingRoom ||
_isJoiningRoom;


return Directionality(
textDirection:
TextDirection.rtl,

child: Scaffold(

appBar: AppBar(

title:
const Text(
'منچ آنلاین',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),

centerTitle:
true,
),



body:

SafeArea(

child:

SingleChildScrollView(

padding:
const EdgeInsets.all(
20,
),


child:

Column(

children: [


const SizedBox(
height: 20,
),



Container(

width: 110,

height: 110,


decoration:
BoxDecoration(

shape:
BoxShape.circle,

color:
Theme.of(context)
.colorScheme
.primaryContainer,

),


child:
const Icon(

Icons.casino,

size: 65,

),

),



const SizedBox(
height: 20,
),



const Text(

'منچ آنلاین',

style:
TextStyle(

fontSize:
30,

fontWeight:
FontWeight.bold,

),

),



const SizedBox(
height: 10,
),



Text(

'اتاق بساز یا با کد وارد بازی شو.',

textAlign:
TextAlign.center,

style:
TextStyle(

color:
Colors.grey.shade700,

),

),



const SizedBox(
height: 30,
),



Card(

child:

Padding(

padding:
const EdgeInsets.all(
18,
),


child:

Column(

children: [


const Text(

'ساخت اتاق جدید',

style:
TextStyle(

fontSize:
20,

fontWeight:
FontWeight.bold,

),

),



const SizedBox(
height: 15,
),



SizedBox(

width:
double.infinity,

height:
55,


child:

FilledButton.icon(

onPressed:

busy
? null
: _createRoom,


icon:

_isCreatingRoom

? const SizedBox(

width:20,

height:20,

child:
CircularProgressIndicator(
strokeWidth:2,
),

)

: const Icon(
Icons.add_circle,
),



label:

Text(

_isCreatingRoom

? 'در حال ساخت...'

: 'ساخت اتاق',

),

),

),

],

),

),

),



const SizedBox(
height: 20,
),



const Row(

children: [

Expanded(
child:
Divider(),
),

Padding(

padding:
EdgeInsets.symmetric(
horizontal: 12,
),

child:
Text('یا'),

),


Expanded(
child:
Divider(),
),

],

),



const SizedBox(
height: 20,
),



Card(

child:

Padding(

padding:
const EdgeInsets.all(
18,
),


child:

Column(

children: [


const Text(

'ورود به اتاق',

style:
TextStyle(

fontSize:
20,

fontWeight:
FontWeight.bold,

),

),



const SizedBox(
height: 15,
),



TextField(

controller:
_roomCodeController,


textAlign:
TextAlign.center,


keyboardType:
TextInputType.number,


maxLength:
6,


decoration:

const InputDecoration(

hintText:
'کد ۶ رقمی',

border:
OutlineInputBorder(),

),

),



const SizedBox(
height: 10,
),



SizedBox(

width:
double.infinity,

height:
55,


child:

OutlinedButton.icon(

onPressed:

busy
? null
: _joinRoom,


icon:

_isJoiningRoom

? const SizedBox(

width:
20,

height:
20,

child:
CircularProgressIndicator(
strokeWidth:2,
),

)

:

const Icon(
Icons.login,
),



label:

Text(

_isJoiningRoom

? 'در حال ورود...'

: 'ورود به اتاق',

),

),

),

],

),

),

),
  const SizedBox(
    height: 25,
  ),


  const Row(

    mainAxisAlignment:
    MainAxisAlignment.center,

    children: [

      Icon(
        Icons.people_outline,
        size: 20,
      ),

      SizedBox(
        width: 6,
      ),

      Text(
        'هر اتاق حداکثر ۴ بازیکن دارد.',
        style:
        TextStyle(
          fontSize: 13,
        ),
      ),

    ],

  ),


],

),

),

),

),

);

}

}






