# گزارش نهایی امنیت و آماده‌سازی انتشار (مرحله هشتم)

این گزارش شامل بررسی‌های امنیتی انجام شده، اصلاحات اعمال شده و لیست دستورات SQL پیشنهادی برای تنظیم نهایی دیتابیس Supabase است.

## ۱. بررسی امنیت دیتابیس (RLS & RPC)

تمامی تراکنش‌های مالی و حساس از طریق تابعی به نام `handle_coin_transaction` در سمت سرور (RPC) انجام می‌شود. این موضوع امنیت موجودی کاربران را تضمین می‌کند.

### اسکریپت SQL پیشنهادی (جهت اجرا در Supabase):

```sql
-- ۱. تنظیم دسترسی به جدول پروفایل
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "کاربران فقط پروفایل خود را ببینند" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "مدیر مجاز به تغییر همه پروفایل‌هاست" ON public.profiles
    FOR ALL USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ۲. تنظیم دسترسی به تراکنش‌های سکه (فقط خواندنی برای کاربر)
ALTER TABLE public.coin_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "مشاهده تراکنش‌های شخصی" ON public.coin_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- ۳. جلوگیری از تغییر مستقیم موجودی توسط کلاینت
-- نکته: فقط تابع handle_coin_transaction با دسترسی SECURITY DEFINER مجاز به تغییر فیلد points باشد.

-- ۴. امنیت سفارشات
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ثبت و مشاهده سفارش توسط کاربر" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ایجاد سفارش جدید توسط کاربر" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## ۲. تست سیستم سکه و تراکنش‌ها

- **هدیه ثبت‌نام:** در سطح دیتابیس با قید (Constraint) بر روی `type` و `user_id` در جدول تراکنش‌ها می‌توان از تکرار آن جلوگیری کرد.
- **تراکنش‌های بازی:** در `GameService` بررسی موجودی قبل از شروع بازی لحاظ شده است.
- **امنیت خرید:** در `ShopService` مکانیزم "بازگشت وجه در صورت خطا" (Refund logic) پیاده‌سازی شده است.

## ۳. بررسی پنل مدیریت

- تمامی متدهای `AdminService` در اولین گام تابع `isAdmin()` را اجرا می‌کنند که نقش کاربر را مستقیماً از دیتابیس استعلام می‌کند.
- دکمه ورود به پنل مدیریت در داشبورد فقط برای کاربرانی با `role == 'admin'` نمایش داده می‌شود.

## ۴. آماده‌سازی برای انتشار (Release)

### اصلاحات انجام شده:
- **نام نمایشی:** نام اپلیکیشن در فایل مانیفست اندروید به **"سکه‌چی"** تغییر یافت.
- **تم و ظاهر:** تمامی هشدارها و کدهای Deprecated (مانند `withOpacity`) اصلاح شدند.
- **فونت و زبان:** تمامی صفحات برای حالت RTL و فونت فارسی بهینه‌سازی شدند.

### موارد باقی‌مانده قبل از خروجی APK:
1. جایگزینی فایل‌های آیکون در مسیر `android/app/src/main/res/mipmap-*`.
2. تنظیم `signingConfigs` در فایل `build.gradle` برای امضای دیجیتال اپلیکیشن.
3. اجرای دستور: `flutter build apk --release`

## ۵. نتیجه آنالیز نهایی
- **flutter analyze:** با موفقیت (بدون خطای متوقف‌کننده) اجرا شد.
- **تست نفوذ:** مسیرهای مدیریتی برای کاربران عادی مسدود گردید.
