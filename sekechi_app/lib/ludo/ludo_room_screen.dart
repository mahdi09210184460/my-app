
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'ludo_screen.dart';

class LudoRoomScreen extends StatefulWidget {
final String roomId;

const LudoRoomScreen({
super.key,
required this.roomId,
});

@override
State<LudoRoomScreen> createState() =>
_LudoRoomScreenState();
}

class _LudoRoomScreenState
extends State<LudoRoomScreen> {
bool _loading = true;
bool _starting = false;

String _roomStatus = 'waiting';
String _roomCode = '';

List<Map<String, dynamic>> _players = [];

StreamSubscription<List<Map<String, dynamic>>>?
_playersSubscription;

StreamSubscription<List<Map<String, dynamic>>>?
_roomSubscription;

@override
void initState() {
super.initState();
_loadRoom();
_listenToRoom();
_listenToPlayers();
}

@override
void dispose() {
_playersSubscription?.cancel();
_roomSubscription?.cancel();
super.dispose();
}

Future<void> _loadRoom() async {
try {
final supabase =
SupabaseService.client;

final room = await supabase
    .from('ludo_rooms')
    .select(
'id, room_code, status, current_player',
)
    .eq(
'id',
widget.roomId,
)
    .maybeSingle();

if (room == null) {
throw Exception(
'اتاق پیدا نشد.',
);
}

final players = await supabase
    .from('ludo_players')
    .select(
'id, user_id, player_index, player_name, color, is_connected',
)
    .eq(
'room_id',
widget.roomId,
)
    .order(
'player_index',
);

if (!mounted) return;

setState(() {
_roomStatus =
room['status']?.toString() ??
'waiting';

_roomCode =
room['room_code']?.toString() ??
'';

_players =
List<Map<String, dynamic>>.from(
players,
);

_loading = false;
});
} catch (_) {
if (!mounted) return;

setState(() {
_loading = false;
});

_showMessage(
'دریافت اطلاعات اتاق انجام نشد.',
);
}
}

void _listenToRoom() {
final supabase =
SupabaseService.client;

_roomSubscription = supabase
    .from('ludo_rooms')
    .stream(
primaryKey: ['id'],
)
    .eq(
'id',
widget.roomId,
)
    .listen(
(rows) {
if (!mounted || rows.isEmpty) {
return;
}

final room = rows.first;

final newStatus =
room['status']?.toString() ??
'waiting';

setState(() {
_roomStatus = newStatus;

_roomCode =
room['room_code']
    ?.toString() ??
'';
});

if (newStatus == 'playing') {
_openGameAutomatically();
}
},
onError: (_) {},
);
}

void _listenToPlayers() {
final supabase =
SupabaseService.client;

_playersSubscription = supabase
    .from('ludo_players')
    .stream(
primaryKey: ['id'],
)
    .eq(
'room_id',
widget.roomId,
)
    .order(
'player_index',
)
    .listen(
(rows) {
if (!mounted) return;

setState(() {
_players =
List<Map<String, dynamic>>.from(
rows,
);
});
},
onError: (_) {},
);
}

bool get _isHost {
final userId =
SupabaseService
    .client
    .auth
    .currentUser
    ?.id;

if (userId == null ||
_players.isEmpty) {
return false;
}

return _players.first['user_id']
    ?.toString() ==
userId;
}

Future<void> _startGame() async {
if (_starting) return;

if (_players.length < 2) {
_showMessage(
'برای شروع بازی حداقل ۲ بازیکن لازم است.',
);
return;
}

setState(() {
_starting = true;
});

try {
await SupabaseService.client
    .from('ludo_rooms')
    .update({
'status': 'playing',
'current_player': 0,
'dice': 0,
'game_state': {
'positions': {
'0': [-1, -1, -1, -1],
'1': [-1, -1, -1, -1],
'2': [-1, -1, -1, -1],
'3': [-1, -1, -1, -1],
},
},
}).eq(
'id',
widget.roomId,
);

if (!mounted) return;

_openGame();
} catch (_) {
if (!mounted) return;

setState(() {
_starting = false;
});

_showMessage(
'شروع بازی انجام نشد.',
);
}
}

void _openGameAutomatically() {
if (!mounted) return;

final route =
ModalRoute.of(context);

if (route == null) return;

Navigator.of(context).pushReplacement(
MaterialPageRoute(
builder: (_) => LudoScreen(
roomId: widget.roomId,
),
),
);
}

void _openGame() {
if (!mounted) return;

Navigator.of(context).pushReplacement(
MaterialPageRoute(
builder: (_) => LudoScreen(
roomId: widget.roomId,
),
),
);
}

Future<void> _leaveRoom() async {
final userId =
SupabaseService
    .client
    .auth
    .currentUser
    ?.id;

if (userId == null) {
if (mounted) {
Navigator.of(context).pop();
}
return;
}

try {
await SupabaseService.client
    .from('ludo_players')
    .delete()
    .eq(
'room_id',
widget.roomId,
)
    .eq(
'user_id',
userId,
);

if (!mounted) return;

Navigator.of(context).pop();
} catch (_) {
if (!mounted) return;

_showMessage(
'خروج از اتاق انجام نشد.',
);
}
}

void _showMessage(
String message,
) {
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

Color _playerColor(
int index,
) {
const colors = [
Colors.red,
Colors.green,
Colors.amber,
Colors.blue,
];

return colors[
index.clamp(0, 3)];
}

String _playerName(
Map<String, dynamic> player,
int index,
) {
final name =
player['player_name']
    ?.toString()
    .trim();

if (name != null &&
name.isNotEmpty) {
return name;
}

return 'بازیکن ${index + 1}';
}

@override
Widget build(
BuildContext context,
) {
return Directionality(
textDirection:
TextDirection.rtl,
child: Scaffold(
appBar: AppBar(
title: const Text(
'اتاق منچ',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
centerTitle: true,
actions: [
IconButton(
onPressed:
_loadRoom,
icon:
const Icon(
Icons.refresh,
),
),
],
),
body: _loading
? const Center(
child:
CircularProgressIndicator(),
)
    : RefreshIndicator(
onRefresh:
_loadRoom,
child:
ListView(
padding:
const EdgeInsets.all(
18,
),
children: [
_buildRoomCard(),

const SizedBox(
height: 22,
),

const Text(
'بازیکنان',
style:
TextStyle(
fontSize:
22,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 12,
),

_buildPlayers(),

const SizedBox(
height: 24,
),

_buildAction(),

const SizedBox(
height: 15,
),

_buildRules(),
],
),
),
),
);
}

Widget _buildRoomCard() {
return Card(
elevation: 0,
child: Padding(
padding:
const EdgeInsets.all(
20,
),
child: Column(
children: [
const Icon(
Icons.casino_rounded,
size: 65,
),

const SizedBox(
height: 12,
),

const Text(
'اتاق بازی منچ',
style:
TextStyle(
fontSize: 24,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 15,
),

if (_roomCode.isNotEmpty)
Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 18,
vertical: 12,
),
decoration:
BoxDecoration(
borderRadius:
BorderRadius.circular(
14,
),
color:
Theme.of(
context,
)
    .colorScheme
    .primaryContainer,
),
child:
Text(
'کد اتاق: $_roomCode',
style:
const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(
height: 15,
),

_statusWidget(),
],
),
),
);
}

Widget _statusWidget() {
if (_roomStatus ==
'playing') {
return const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons
    .play_circle_outline,
),
SizedBox(
width: 7,
),
Text(
'بازی در حال اجراست',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),
],
);
}

if (_roomStatus ==
'finished') {
return const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons
    .emoji_events_outlined,
),
SizedBox(
width: 7,
),
Text(
'بازی تمام شده است',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),
],
);
}

return Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
const Icon(
Icons
    .people_outline,
),
const SizedBox(
width: 7,
),
Text(
'${_players.length}/4 بازیکن',
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),
],
);
}

Widget _buildPlayers() {
if (_players.isEmpty) {
return const Card(
child: Padding(
padding:
EdgeInsets.all(25),
child: Column(
children: [
Icon(
Icons
    .person_off_outlined,
size: 50,
),
SizedBox(
height: 10,
),
Text(
'هنوز بازیکنی وارد اتاق نشده است.',
textAlign:
TextAlign.center,
),
],
),
),
);
}

return Column(
children: List.generate(
_players.length,
(index) {
final player =
_players[index];

final connected =
player['is_connected'] ==
true;

return Card(
margin:
const EdgeInsets.only(
bottom: 10,
),
child: ListTile(
leading:
CircleAvatar(
backgroundColor:
_playerColor(
index,
),
child:
const Icon(
Icons.person,
color:
Colors.white,
),
),
title:
Text(
_playerName(
player,
index,
),
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),
subtitle:
Text(
index == 0
? 'سازنده اتاق'
    : 'بازیکن ${index + 1}',
),
trailing:
Icon(
connected
? Icons
    .check_circle
    : Icons
    .radio_button_off,
color:
connected
? Colors.green
    : null,
),
),
);
},
),
);
}

Widget _buildAction() {
if (_roomStatus ==
'playing') {
return SizedBox(
width:
double.infinity,
height: 55,
child:
FilledButton.icon(
onPressed:
_openGame,
icon:
const Icon(
Icons.play_arrow,
),
label:
const Text(
'ورود به بازی',
style:
TextStyle(
fontSize:
17,
fontWeight:
FontWeight.bold,
),
),
),
);
}

if (_isHost) {
return SizedBox(
width:
double.infinity,
height: 55,
child:
FilledButton.icon(
onPressed:
_starting
? null
    : _startGame,
icon:
_starting
? const SizedBox(
width: 22,
height: 22,
child:
CircularProgressIndicator(),
)
    : const Icon(
Icons.play_arrow,
),
label:
Text(
_starting
? 'در حال شروع...'
    : 'شروع بازی',
style:
const TextStyle(
fontSize:
17,
fontWeight:
FontWeight.bold,
),
),
),
);
}

return const Card(
child: Padding(
padding:
EdgeInsets.all(16),
child: Row(
children: [
Icon(
Icons
    .hourglass_top,
),
SizedBox(
width: 10,
),
Expanded(
child: Text(
'منتظر سازنده اتاق برای شروع بازی باشید.',
),
),
],
),
),
);
}

Widget _buildRules() {
return Card(
child: Padding(
padding:
const EdgeInsets.all(
18,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'قوانین منچ',
style:
TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(
height: 12,
),
_rule(
Icons.casino_outlined,
'در هر نوبت ابتدا تاس می‌اندازید.',
),
_rule(
Icons.looks_6_outlined,
'برای خارج کردن مهره از خانه معمولاً باید ۶ بیاورید.',
),
_rule(
Icons.flash_on_outlined,
'زدن مهره حریف باعث برگشت آن به خانه می‌شود.',
),
_rule(
Icons
    .emoji_events_outlined,
'بازیکنی که زودتر مهره‌های خود را به پایان برساند برنده است.',
),
],
),
),
);
}

Widget _rule(
IconData icon,
String text,
) {
return Padding(
padding:
const EdgeInsets.only(
bottom: 10,
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Icon(
icon,
size: 21,
),
const SizedBox(
width: 10,
),
Expanded(
child: Text(
text,
style:
const TextStyle(
fontSize: 13,
),
),
),
],
),
);
}
}










