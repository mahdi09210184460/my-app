
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class LudoScreen extends StatefulWidget {
final String roomId;

const LudoScreen({
super.key,
required this.roomId,
});

@override
State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
final Random _random = Random();

StreamSubscription<List<Map<String, dynamic>>>?
_roomSubscription;

bool _loading = true;
bool _rolling = false;
bool _saving = false;

String _myUserId = '';

int _myPlayerIndex = 0;
int _currentPlayer = 0;
int _dice = 0;

String _roomStatus = 'waiting';

int? _winnerIndex;

List<Map<String, dynamic>> _players = [];

final List<List<int>> _positions = [
[-1, -1, -1, -1],
[-1, -1, -1, -1],
[-1, -1, -1, -1],
[-1, -1, -1, -1],
];

@override
void initState() {
super.initState();
_initializeGame();
}

@override
void dispose() {
_roomSubscription?.cancel();
super.dispose();
}

Future<void> _initializeGame() async {
final user =
SupabaseService.client.auth.currentUser;

if (user == null) {
if (!mounted) return;

setState(() {
_loading = false;
});

_showMessage(
'ابتدا وارد حساب خود شوید.',
);

return;
}

_myUserId = user.id;

await _loadGame();

if (!mounted) return;

_listenToGame();
}

Future<void> _loadGame() async {
try {
final supabase =
SupabaseService.client;

final room = await supabase
    .from('ludo_rooms')
    .select(
'id, status, current_player, dice, game_state, winner',
)
    .eq(
'id',
widget.roomId,
)
    .maybeSingle();

if (room == null) {
throw Exception(
'اتاق بازی پیدا نشد.',
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

_readGameState(
room,
players,
);

setState(() {
_loading = false;
});
} catch (_) {
if (!mounted) return;

setState(() {
_loading = false;
});

_showMessage(
'دریافت اطلاعات بازی انجام نشد.',
);
}
}

void _listenToGame() {
_roomSubscription = SupabaseService.client
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

_readGameState(
room,
_players,
);

setState(() {});
},
onError: (_) {},
);
}

void _readGameState(
Map<String, dynamic> room,
List<Map<String, dynamic>> players,
) {
_roomStatus =
room['status']?.toString() ??
'waiting';

_currentPlayer =
(room['current_player'] as num?)
    ?.toInt() ??
0;

_dice =
(room['dice'] as num?)
    ?.toInt() ??
0;

_winnerIndex =
(room['winner'] as num?)?.toInt();

_players =
List<Map<String, dynamic>>.from(
players,
);

_findMyPlayer();

final state = room['game_state'];

if (state is Map) {
final positions =
state['positions'];

if (positions is Map) {
for (int player = 0;
player < 4;
player++) {
final value =
positions[player.toString()];

if (value is List) {
for (int piece = 0;
piece < 4;
piece++) {
if (piece < value.length) {
final position =
value[piece];

if (position is num) {
_positions[player][piece] =
position.toInt();
}
}
}
}
}
}
}
}

void _findMyPlayer() {
_myPlayerIndex = 0;

for (final player in _players) {
if (player['user_id']?.toString() ==
_myUserId) {
_myPlayerIndex =
(player['player_index'] as num?)
    ?.toInt() ??
0;
break;
}
}

if (_myPlayerIndex < 0 ||
_myPlayerIndex > 3) {
_myPlayerIndex = 0;
}
}

bool get _isGameFinished {
return _roomStatus == 'finished' ||
_winnerIndex != null;
}

bool get _isMyTurn {
return _roomStatus == 'playing' &&
!_isGameFinished &&
_currentPlayer == _myPlayerIndex;
}

bool get _canRoll {
return _isMyTurn &&
!_rolling &&
!_saving &&
_dice == 0;
}

Future<void> _rollDice() async {
if (!_canRoll) return;

setState(() {
_rolling = true;
});

await Future.delayed(
const Duration(
milliseconds: 450,
),
);

final value =
_random.nextInt(6) + 1;

if (!mounted) return;

setState(() {
_dice = value;
_rolling = false;
});

await _saveDice(value);

if (!mounted) return;

if (!_hasMovablePiece(
_myPlayerIndex,
value,
)) {
if (value != 6) {
await Future.delayed(
const Duration(
milliseconds: 700,
),
);

if (mounted) {
await _nextTurn();
}
} else {
setState(() {
_dice = 0;
});

await _saveDice(0);

_showMessage(
'هیچ مهره‌ای قابل حرکت نیست.',
);
}
}
}

bool _hasMovablePiece(
int player,
int dice,
) {
for (final position
in _positions[player]) {
if (position == -1) {
if (dice == 6) {
return true;
}
} else if (position < 56 &&
position + dice <= 56) {
return true;
}
}

return false;
}

Future<void> _movePiece(
int pieceIndex,
) async {
if (!_isMyTurn ||
_dice == 0 ||
_saving ||
_rolling ||
_isGameFinished) {
return;
}

if (pieceIndex < 0 ||
pieceIndex > 3) {
return;
}

final current =
_positions[_myPlayerIndex]
[pieceIndex];

int newPosition;

if (current == -1) {
if (_dice != 6) {
_showMessage(
'برای خارج کردن مهره باید ۶ بیاورید.',
);
return;
}

newPosition = 0;
} else {
newPosition =
current + _dice;

if (newPosition > 56) {
_showMessage(
'این مهره نمی‌تواند این مقدار حرکت کند.',
);
return;
}
}

setState(() {
_positions[_myPlayerIndex]
[pieceIndex] = newPosition;
});

await _handleCapture(
_myPlayerIndex,
newPosition,
);

await _saveGameState();

if (!mounted) return;

final won =
_checkWinner(
_myPlayerIndex,
);

if (won) {
await _finishGame(
_myPlayerIndex,
);
return;
}

if (_dice == 6) {
setState(() {
_dice = 0;
});

await _saveDice(0);

_showMessage(
'۶ آوردید! دوباره نوبت شماست.',
);
} else {
await _nextTurn();
}
}

bool _checkWinner(
int player,
) {
return _positions[player].every(
(position) => position == 56,
);
}

Future<void> _finishGame(
int winner,
) async {
if (_isGameFinished) return;

setState(() {
_winnerIndex = winner;
_roomStatus = 'finished';
_dice = 0;
});

try {
await SupabaseService.client
    .from('ludo_rooms')
    .update({
'status': 'finished',
'winner': winner,
'dice': 0,
}).eq(
'id',
widget.roomId,
);

await _saveGameState();

if (!mounted) return;

await _showWinnerDialog(
winner,
);
} catch (_) {
if (!mounted) return;

_showMessage(
'ثبت نتیجه بازی انجام نشد.',
);
}
}

Future<void> _showWinnerDialog(
int winner,
) async {
if (!mounted) return;

final isMe =
winner == _myPlayerIndex;

await showDialog<void>(
context: context,
barrierDismissible: false,
builder: (context) {
return AlertDialog(
title: Row(
children: [
const Icon(
Icons.emoji_events,
size: 34,
),
const SizedBox(
width: 10,
),
Text(
isMe
? 'شما برنده شدید! 🎉'
    : 'بازی تمام شد',
),
],
),
content: Column(
mainAxisSize:
MainAxisSize.min,
children: [
const SizedBox(
height: 10,
),
CircleAvatar(
radius: 42,
backgroundColor:
_playerColor(
winner,
),
child: const Icon(
Icons.emoji_events,
color: Colors.white,
size: 45,
),
),
const SizedBox(
height: 15,
),
Text(
'${_playerName(winner)} برنده بازی شد.',
textAlign:
TextAlign.center,
style:
const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(
height: 8,
),
Text(
isMe
? 'تبریک! هر ۴ مهره شما به خانه نهایی رسیدند.'
    : 'بازی به پایان رسید.',
textAlign:
TextAlign.center,
),
],
),
actions: [
FilledButton(
onPressed: () {
Navigator.of(
context,
).pop();

Navigator.of(
context,
).pop();
},
child: const Text(
'بازگشت به اتاق',
),
),
],
);
},
);
}

Future<void> _handleCapture(
int player,
int position,
) async {
if (position < 0 ||
position >= 52) {
return;
}

for (int otherPlayer = 0;
otherPlayer < 4;
otherPlayer++) {
if (otherPlayer == player) {
continue;
}

for (int piece = 0;
piece < 4;
piece++) {
if (_positions[otherPlayer]
[piece] ==
position) {
_positions[otherPlayer]
[piece] = -1;
}
}
}
}

Future<void> _saveDice(
int value,
) async {
try {
await SupabaseService.client
    .from('ludo_rooms')
    .update({
'dice': value,
}).eq(
'id',
widget.roomId,
);
} catch (_) {
if (!mounted) return;

_showMessage(
'ذخیره تاس انجام نشد.',
);
}
}

Future<void> _saveGameState() async {
if (_saving) return;

setState(() {
_saving = true;
});

try {
await SupabaseService.client
    .from('ludo_rooms')
    .update({
'game_state': {
'positions': {
'0': List<int>.from(
_positions[0],
),
'1': List<int>.from(
_positions[1],
),
'2': List<int>.from(
_positions[2],
),
'3': List<int>.from(
_positions[3],
),
},
},
}).eq(
'id',
widget.roomId,
);
} catch (_) {
if (mounted) {
_showMessage(
'ذخیره وضعیت بازی انجام نشد.',
);
}
} finally {
if (mounted) {
setState(() {
_saving = false;
});
}
}
}

Future<void> _nextTurn() async {
if (!_isMyTurn ||
_isGameFinished) {
return;
}

int nextPlayer =
(_currentPlayer + 1) % 4;

final connectedPlayers =
_connectedPlayerIndexes();

if (connectedPlayers.isNotEmpty) {
for (int i = 0; i < 4; i++) {
if (connectedPlayers
    .contains(nextPlayer)) {
break;
}

nextPlayer =
(nextPlayer + 1) % 4;
}
}

setState(() {
_dice = 0;
_currentPlayer =
nextPlayer;
});

try {
await SupabaseService.client
    .from('ludo_rooms')
    .update({
'dice': 0,
'current_player':
nextPlayer,
}).eq(
'id',
widget.roomId,
);
} catch (_) {
if (mounted) {
_showMessage(
'تغییر نوبت انجام نشد.',
);
}
}
}

List<int> _connectedPlayerIndexes() {
final result = <int>[];

for (final player in _players) {
final connected =
player['is_connected'] == true;

if (!connected) continue;

final index =
(player['player_index'] as num?)
    ?.toInt() ??
-1;

if (index >= 0 &&
index <= 3) {
result.add(index);
}
}

return result;
}

String _playerName(
int index,
) {
for (final player in _players) {
final playerIndex =
(player['player_index'] as num?)
    ?.toInt();

if (playerIndex == index) {
final name =
player['player_name']
    ?.toString()
    .trim();

if (name != null &&
name.isNotEmpty) {
return name;
}
}
}

return 'بازیکن ${index + 1}';
}

Color _playerColor(
int index,
) {
switch (index) {
case 0:
return Colors.red;
case 1:
return Colors.green;
case 2:
return Colors.amber.shade700;
case 3:
return Colors.blue;
default:
return Colors.grey;
}
}

String _turnText() {
if (_isGameFinished) {
if (_winnerIndex == null) {
return 'بازی تمام شده است';
}

return 'برنده: ${_playerName(_winnerIndex!)}';
}

if (_roomStatus != 'playing') {
return 'بازی هنوز شروع نشده است';
}

if (_isMyTurn) {
return 'نوبت شماست';
}

return 'نوبت ${_playerName(_currentPlayer)}';
}

String _diceText() {
if (_rolling) {
return '🎲';
}

if (_dice == 0) {
return '–';
}

return '$_dice';
}

Widget _buildDice() {
return GestureDetector(
onTap: _canRoll
? _rollDice
    : null,
child: AnimatedContainer(
duration:
const Duration(
milliseconds: 200,
),
width: 78,
height: 78,
decoration: BoxDecoration(
borderRadius:
BorderRadius.circular(18),
color:
Theme.of(context)
    .colorScheme
    .surfaceContainerHighest,
border: Border.all(
color: _canRoll
? Theme.of(context)
    .colorScheme
    .primary
    : Colors.transparent,
width: 2,
),
),
child: Center(
child: _rolling
? const SizedBox(
width: 28,
height: 28,
child:
CircularProgressIndicator(),
)
    : Text(
_diceText(),
style:
const TextStyle(
fontSize: 34,
fontWeight:
FontWeight.bold,
),
),
),
),
);
}

Widget _buildPlayerInfo() {
return Card(
elevation: 0,
child: Padding(
padding:
const EdgeInsets.symmetric(
horizontal: 16,
vertical: 12,
),
child: Row(
children: [
CircleAvatar(
backgroundColor:
_playerColor(
_myPlayerIndex,
),
child: const Icon(
Icons.person,
color: Colors.white,
),
),
const SizedBox(
width: 12,
),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
_playerName(
_myPlayerIndex,
),
style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 16,
),
),
const SizedBox(
height: 3,
),
Text(
_turnText(),
style:
TextStyle(
fontSize: 13,
color: _isMyTurn
? Theme.of(
context,
)
    .colorScheme
    .primary
    : null,
fontWeight:
_isMyTurn
? FontWeight.bold
    : FontWeight.normal,
),
),
],
),
),
_buildDice(),
],
),
),
);
}

Widget _buildBoard() {
return AspectRatio(
aspectRatio: 1,
child: Container(
padding:
const EdgeInsets.all(8),
decoration: BoxDecoration(
borderRadius:
BorderRadius.circular(24),
border: Border.all(
width: 2,
),
color:
Theme.of(context)
    .colorScheme
    .surface,
),
child: Column(
children: [
Expanded(
child: Row(
children: [
Expanded(
child:
_buildHomeArea(0),
),
Expanded(
child:
_buildTopPath(),
),
Expanded(
child:
_buildHomeArea(1),
),
],
),
),
Expanded(
child: Row(
children: [
Expanded(
child:
_buildLeftPath(),
),
Expanded(
child:
_buildCenterArea(),
),
Expanded(
child:
_buildRightPath(),
),
],
),
),
Expanded(
child: Row(
children: [
Expanded(
child:
_buildHomeArea(3),
),
Expanded(
child:
_buildBottomPath(),
),
Expanded(
child:
_buildHomeArea(2),
),
],
),
),
],
),
),
);
}

Widget _buildHomeArea(
int player,
) {
final color =
_playerColor(player);

return Container(
margin:
const EdgeInsets.all(4),
decoration: BoxDecoration(
color:
color.withOpacity(0.15),
borderRadius:
BorderRadius.circular(16),
border: Border.all(
color:
color.withOpacity(0.5),
),
),
child: Column(
children: [
Padding(
padding:
const EdgeInsets.only(
top: 5,
),
child: Text(
_playerName(player),
overflow:
TextOverflow.ellipsis,
style: TextStyle(
fontSize: 11,
fontWeight:
FontWeight.bold,
color: color,
),
),
),
Expanded(
child: Center(
child: Wrap(
alignment:
WrapAlignment.center,
spacing: 8,
runSpacing: 8,
children:
List.generate(
4,
(piece) =>
_buildPiece(
player,
piece,
36,
),
),
),
),
),
],
),
);
}

Widget _buildTopPath() {
  return Column(
    children: [
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(3 + index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(6 + index),
          ),
        ),
      ),
    ],
  );
}

Widget _buildBottomPath() {
  return Column(
    children: [
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(39 + index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(42 + index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(45 + index),
          ),
        ),
      ),
    ],
  );
}

Widget _buildLeftPath() {
  return Column(
    children: [
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(36 + index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(33 + index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(30 + index),
          ),
        ),
      ),
    ],
  );
}

Widget _buildRightPath() {
  return Column(
    children: [
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(9 + index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(12 + index),
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: List.generate(
            3,
                (index) => _buildPathCell(15 + index),
          ),
        ),
      ),
    ],
  );
}

Widget _buildCenterArea() {
return Container(
margin:
const EdgeInsets.all(4),
decoration: BoxDecoration(
borderRadius:
BorderRadius.circular(14),
gradient:
LinearGradient(
begin:
Alignment.topRight,
end:
Alignment.bottomLeft,
colors: [
_playerColor(0)
    .withOpacity(0.7),
_playerColor(1)
    .withOpacity(0.7),
_playerColor(2)
    .withOpacity(0.7),
_playerColor(3)
    .withOpacity(0.7),
],
),
),
child: const Center(
child: Icon(
Icons.star,
color: Colors.white,
size: 38,
),
),
);
}

Widget _buildPathCell(
int pathIndex,
) {
final pieces =
<Widget>[];

for (int player = 0;
player < 4;
player++) {
for (int piece = 0;
piece < 4;
piece++) {
final position =
_positions[player]
[piece];

if (position == pathIndex) {
pieces.add(
_buildPiece(
player,
piece,
20,
),
);
}
}
}

return Expanded(
child: Container(
margin:
const EdgeInsets.all(1),
decoration: BoxDecoration(
color:
Theme.of(context)
    .colorScheme
    .surfaceContainerHighest,
borderRadius:
BorderRadius.circular(4),
border: Border.all(
color:
Theme.of(context)
    .dividerColor
    .withOpacity(0.4),
),
),
child: pieces.isEmpty
? const SizedBox()
    : Center(
child: Wrap(
alignment:
WrapAlignment.center,
spacing: 1,
runSpacing: 1,
children: pieces,
),
),
),
);
}

Widget _buildPiece(
int player,
int piece,
double size,
) {
final movable =
player == _myPlayerIndex &&
_isMyTurn &&
_dice > 0 &&
_pieceCanMove(
player,
piece,
);

return GestureDetector(
onTap: movable
? () => _movePiece(
piece,
)
    : null,
child: AnimatedContainer(
duration:
const Duration(
milliseconds: 180,
),
width: size,
height: size,
decoration: BoxDecoration(
shape: BoxShape.circle,
color:
_playerColor(player),
border: Border.all(
color: movable
? Colors.white
    : Colors.black
    .withOpacity(0.2),
width: movable ? 3 : 1,
),
boxShadow: movable
? [
BoxShadow(
blurRadius: 6,
spreadRadius: 1,
color:
_playerColor(
player,
).withOpacity(0.5),
),
]
    : null,
),
child: Center(
child: Text(
'${piece + 1}',
style: TextStyle(
color: Colors.white,
fontSize:
size < 25 ? 8 : 11,
fontWeight:
FontWeight.bold,
),
),
),
),
);
}

bool _pieceCanMove(
int player,
int piece,
) {
if (_dice == 0 ||
_isGameFinished) {
return false;
}

final position =
_positions[player][piece];

if (position == -1) {
return _dice == 6;
}

return position + _dice <= 56;
}

Widget _buildBottomControls() {
return Card(
child: Padding(
padding:
const EdgeInsets.all(16),
child: Column(
children: [
if (_isGameFinished)
const Icon(
Icons.emoji_events,
size: 42,
),

if (_isGameFinished)
const SizedBox(
height: 8,
),

Text(
_turnText(),
style:
const TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 8,
),

Text(
_isGameFinished
? 'این بازی به پایان رسیده است.'
    : _dice == 0
? 'برای شروع نوبت، روی تاس بزنید.'
    : 'یکی از مهره‌های قابل حرکت را انتخاب کنید.',
textAlign:
TextAlign.center,
style:
const TextStyle(
fontSize: 13,
),
),

if (!_isGameFinished) ...[
const SizedBox(
height: 14,
),
SizedBox(
width:
double.infinity,
height: 50,
child:
FilledButton.icon(
onPressed:
_canRoll
? _rollDice
    : null,
icon:
const Icon(
Icons.casino,
),
label:
Text(
_canRoll
? 'انداختن تاس'
    : _dice > 0
? 'مهره را انتخاب کنید'
    : 'منتظر نوبت',
style:
const TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),
),
),
],
],
),
),
);
}

Widget _buildPlayersBar() {
return SizedBox(
height: 74,
child: ListView.separated(
scrollDirection:
Axis.horizontal,
itemCount: 4,
separatorBuilder:
(_, __) =>
const SizedBox(
width: 8,
),
itemBuilder:
(context, index) {
final active =
_currentPlayer == index &&
!_isGameFinished;

final winner =
_winnerIndex == index;

return Container(
width: 125,
padding:
const EdgeInsets.all(
9,
),
decoration:
BoxDecoration(
borderRadius:
BorderRadius.circular(
14,
),
border: Border.all(
color: winner
? _playerColor(
index,
)
    : active
? _playerColor(
index,
)
    : Colors.transparent,
width: 2,
),
color:
_playerColor(index)
    .withOpacity(
0.12,
),
),
child: Row(
children: [
CircleAvatar(
radius: 17,
backgroundColor:
_playerColor(
index,
),
child:
winner
? const Icon(
Icons
    .emoji_events,
color:
Colors.white,
size: 18,
)
    : Text(
'${index + 1}',
style:
const TextStyle(
color:
Colors.white,
fontWeight:
FontWeight.bold,
),
),
),
const SizedBox(
width: 7,
),
Expanded(
child:
Text(
_playerName(
index,
),
overflow:
TextOverflow
    .ellipsis,
style:
TextStyle(
fontSize: 12,
fontWeight:
active ||
winner
? FontWeight.bold
    : FontWeight.normal,
),
),
),
],
),
);
},
),
);
}

Future<bool> _onWillPop() async {
return await showDialog<bool>(
context: context,
builder:
(context) {
return AlertDialog(
title:
const Text(
'خروج از بازی',
),
content:
Text(
_isGameFinished
? 'آیا می‌خواهید به اتاق برگردید؟'
    : 'آیا می‌خواهید از صفحه بازی خارج شوید؟',
),
actions: [
TextButton(
onPressed:
() => Navigator.pop(
context,
false,
),
child:
const Text(
'ادامه بازی',
),
),
FilledButton(
onPressed:
() => Navigator.pop(
context,
true,
),
child:
const Text(
'خروج',
),
),
],
);
},
) ??
false;
}

void _showMessage(
String message,
) {
if (!mounted) return;

ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content:
Text(message),
behavior:
SnackBarBehavior.floating,
),
);
}

@override
Widget build(
BuildContext context,
) {
return WillPopScope(
onWillPop:
_onWillPop,
child: Directionality(
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
actions: [
IconButton(
onPressed:
_loadGame,
icon:
const Icon(
Icons.refresh,
),
tooltip:
'به‌روزرسانی',
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
_loadGame,
child:
ListView(
padding:
const EdgeInsets.all(
12,
),
children: [
_buildPlayersBar(),

const SizedBox(
height: 10,
),

_buildPlayerInfo(),

const SizedBox(
height: 12,
),

_buildBoard(),

const SizedBox(
height: 12,
),

_buildBottomControls(),

const SizedBox(
height: 15,
),

_buildGameInfo(),
],
),
),
),
),
);
}

Widget _buildGameInfo() {
return Card(
elevation: 0,
child:
Padding(
padding:
const EdgeInsets.all(
15,
),
child:
Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'قوانین بازی',
style:
TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(
height: 8,
),
const Text(
'• برای شروع نوبت روی تاس بزنید.',
),
const SizedBox(
height: 4,
),
const Text(
'• برای ورود مهره به مسیر باید ۶ بیاورید.',
),
const SizedBox(
height: 4,
),
const Text(
'• بعد از انداختن تاس، مهره قابل حرکت را انتخاب کنید.',
),
const SizedBox(
height: 4,
),
const Text(
'• با رسیدن هر ۴ مهره به خانه نهایی، برنده مشخص می‌شود.',
),
const SizedBox(
height: 4,
),
const Text(
'• بعد از مشخص شدن برنده، بازی دیگر قابل ادامه نیست.',
),
],
),
),
);
}
}














