import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/daily_reward_screen.dart';
import '../ludo/ludo_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
String _username = 'کاربر';
int _points = 0;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
try {
final supabase = SupabaseService.client;
final user = supabase.auth.currentUser;

if (user == null) {
if (!mounted) return;

setState(() {
_isLoading = false;
});

return;
}

final profile = await supabase
.from('profiles')
.select('username, display_name, points')
.eq('id', user.id)
.maybeSingle();

if (!mounted) return;

if (profile != null) {
final displayName =
profile['display_name']?.toString().trim() ?? '';

final username =
profile['username']?.toString().trim() ?? '';

setState(() {
_username = displayName.isNotEmpty
? displayName
: username.isNotEmpty
? username
: 'کاربر';

_points =
(profile['points'] as num?)?.toInt() ?? 0;

_isLoading = false;
});
} else {
setState(() {
_isLoading = false;
});
}
} catch (_) {
if (!mounted) return;

setState(() {
_isLoading = false;
});

_showMessage(
'دریافت اطلاعات حساب انجام نشد.',
);
}
}

Future<void> _logout() async {
try {
await SupabaseService.client.auth.signOut();

if (!mounted) return;

Navigator.of(context).pushNamedAndRemoveUntil(
'/',
(route) => false,
);
} catch (_) {
if (!mounted) return;

_showMessage(
'خروج از حساب انجام نشد.',
);
}
}

Future<void> _openWallet() async {
await Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const WalletScreen(),
),
);

if (!mounted) return;

await _loadProfile();
}

Future<void> _openProfile() async {
await Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const ProfileScreen(),
),
);

if (!mounted) return;

await _loadProfile();
}

Future<void> _openDailyReward() async {
await Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const DailyRewardScreen(),
),
);

if (!mounted) return;

await _loadProfile();
}

void _openLudo() {
Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const LudoLobbyScreen(),
),
);
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
),
);
}

void _showComingSoon(String gameName) {
_showMessage(
'$gameName به‌زودی قابل اجرا خواهد بود.',
);
}
@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
appBar: AppBar(
title: const Text(
'سکه‌چی',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
centerTitle: true,
actions: [
IconButton(
onPressed: () {
_showMessage(
'اعلان جدیدی وجود ندارد.',
);
},
tooltip: 'اعلان‌ها',
icon: const Icon(
Icons.notifications_outlined,
),
),
],
),

drawer: Drawer(
child: SafeArea(
child: Column(
children: [
UserAccountsDrawerHeader(
accountName: Text(
_username,
),
  accountEmail: Text(
    SupabaseService.client.auth.currentUser?.email ?? '',
  ),
    currentAccountPicture:
const CircleAvatar(
child: Icon(
Icons.person,
),
),
),

ListTile(
leading: const Icon(
Icons.person_outline,
),
title: const Text(
'پروفایل',
),
onTap: () {
Navigator.pop(context);
_openProfile();
},
),

ListTile(
leading: const Icon(
Icons.account_balance_wallet_outlined,
),
title: const Text(
'کیف پول و سکه‌ها',
),
subtitle: Text(
'موجودی: $_points سکه',
),
onTap: () {
Navigator.pop(context);
_openWallet();
},
),

ListTile(
leading: const Icon(
Icons.card_giftcard_outlined,
),
title: const Text(
'پاداش روزانه',
),
subtitle: const Text(
'دریافت ۵۰ سکه رایگان',
),
onTap: () {
Navigator.pop(context);
_openDailyReward();
},
),

ListTile(
leading: const Icon(
Icons.sports_esports_outlined,
),
title: const Text(
'منچ آنلاین',
),
subtitle: const Text(
'بازی با دوستان',
),
onTap: () {
Navigator.pop(context);
_openLudo();
},
),

ListTile(
leading: const Icon(
Icons.settings_outlined,
),
title: const Text(
'تنظیمات',
),
onTap: () {
Navigator.pop(context);
_showMessage(
'بخش تنظیمات به‌زودی فعال می‌شود.',
);
},
),

ListTile(
leading: const Icon(
Icons.info_outline,
),
title: const Text(
'درباره برنامه',
),
onTap: () {
Navigator.pop(context);

showAboutDialog(
context: context,
applicationName: 'سکه‌چی',
applicationVersion: '1.0.0',
applicationIcon:
const Icon(
Icons.casino,
size: 40,
),
children: const [
Text(
'سکه‌چی؛ پلتفرم بازی و سرگرمی.',
),
],
);
},
),

const Spacer(),

ListTile(
leading: const Icon(
Icons.logout,
),
title: const Text(
'خروج از حساب',
),
onTap: _logout,
),

const SizedBox(
height: 12,
),
],
),
),
),

body: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
: RefreshIndicator(
onRefresh: _loadProfile,
child: ListView(
padding: const EdgeInsets.all(16),
children: [

Card(
elevation: 0,
child: Padding(
padding:
const EdgeInsets.all(18),
child: Row(
children: [
const CircleAvatar(
radius: 30,
child: Icon(
Icons.person,
size: 30,
),
),

const SizedBox(
width: 14,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'سلام 👋',
style: TextStyle(
fontSize: 14,
),
),

const SizedBox(
height: 4,
),

Text(
_username,
style:
const TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
],
),
),

InkWell(
borderRadius:
BorderRadius.circular(
14,
),
onTap: _openWallet,
child: Container(
padding:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 9,
),
decoration:
BoxDecoration(
borderRadius:
BorderRadius.circular(
14,
),
color:
Theme.of(context)
.colorScheme
.primaryContainer,
),
child: Column(
children: [
const Icon(
Icons
.monetization_on_outlined,
size: 24,
),

const SizedBox(
height: 3,
),

Text(
'$_points',
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),

const Text(
'سکه',
style:
TextStyle(
fontSize: 10,
),
),
],
),
),
),
],
),
),
),

const SizedBox(
height: 24,
),

const Text(
'بازی‌ها',
style: TextStyle(
fontSize: 23,
fontWeight: FontWeight.bold,
),
),

const SizedBox(
height: 12,
),
  _GameCard(
    title: 'منچ',
    description:
    'بازی آنلاین و هیجان‌انگیز منچ',
    icon: Icons.casino_outlined,
    badge: 'آنلاین',
    onTap: _openLudo,
  ),

  const SizedBox(
    height: 12,
  ),

  _GameCard(
    title: 'مار و پله',
    description:
    'رقابت هیجان‌انگیز مار و پله',
    icon: Icons.stairs_outlined,
    onTap: () {
      _showComingSoon(
        'مار و پله',
      );
    },
  ),

  const SizedBox(
    height: 12,
  ),

  _GameCard(
    title: 'بازی رومیزی',
    description:
    'یک بازی جدید در راه است',
    icon: Icons.grid_4x4_outlined,
    badge: 'به‌زودی',
    onTap: () {
      _showComingSoon(
        'بازی رومیزی',
      );
    },
  ),

  const SizedBox(
    height: 24,
  ),

  Card(
    child: ListTile(
      leading: const Icon(
        Icons.card_giftcard,
      ),
      title: const Text(
        'پاداش روزانه',
        style: TextStyle(
          fontWeight:
          FontWeight.bold,
        ),
      ),
      subtitle: const Text(
        'هر ۲۴ ساعت ۵۰ سکه رایگان دریافت کنید.',
      ),
      trailing: const Icon(
        Icons.arrow_back_ios_new,
        size: 17,
      ),
      onTap: _openDailyReward,
    ),
  ),

  const SizedBox(
    height: 12,
  ),

  Card(
    child: ListTile(
      leading: const Icon(
        Icons.campaign_outlined,
      ),
      title: const Text(
        'اخبار و اطلاعیه‌ها',
        style: TextStyle(
          fontWeight:
          FontWeight.bold,
        ),
      ),
      subtitle: const Text(
        'آخرین اخبار سکه‌چی را مشاهده کنید.',
      ),
      trailing: const Icon(
        Icons.arrow_back_ios_new,
        size: 17,
      ),
      onTap: () {
        _showMessage(
          'بخش اخبار به‌زودی فعال می‌شود.',
        );
      },
    ),
  ),
],
),
),
),
);
}
}


class _GameCard extends StatelessWidget {

  final String title;
  final String description;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.badge,
  });


  @override
  Widget build(BuildContext context) {

    return Card(
      child: InkWell(
        borderRadius:
        BorderRadius.circular(12),
        onTap: onTap,

        child: Padding(
          padding:
          const EdgeInsets.all(16),

          child: Row(
            children: [

              CircleAvatar(
                radius: 28,
                child: Icon(
                  icon,
                  size: 28,
                ),
              ),


              const SizedBox(
                width: 14,
              ),


              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Row(
                      children: [

                        Flexible(
                          child: Text(
                            title,
                            style:
                            const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),


                        if (badge != null) ...[

                          const SizedBox(
                            width: 8,
                          ),


                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),

                            decoration:
                            BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(
                                8,
                              ),

                              color:
                              Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                            ),


                            child: Text(
                              badge!,

                              style:
                              const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),


                    const SizedBox(
                      height: 5,
                    ),


                    Text(
                      description,
                    ),
                  ],
                ),
              ),


              const Icon(
                Icons.arrow_back_ios_new,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}





