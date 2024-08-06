# اسکریپت مدیریت تونل

این اسکریپت قابلیت‌های مدیریت تونل‌های 6to4 را در سیستم‌های لینوکس فراهم می‌کند. این اسکریپت از ایجاد، لیست کردن و حذف تونل‌ها پشتیبانی می‌کند و همچنین پیکربندی تونل‌ها را دائمی کرده و سرویس `rc-local` را برای راه‌اندازی سیستم پیکربندی می‌کند.

## ویژگی‌ها

- **ایجاد تونل**: افزودن تونل جدید 6to4 با آدرس‌های IPv4 و IPv6 مشخص.
- **لیست تونل‌ها**: نمایش تمام تونل‌های فعال 6to4.
- **حذف تونل**: حذف تونل موجود.
- **دائمی کردن پیکربندی**: ذخیره پیکربندی تونل در `/etc/rc.local` برای پایداری در هنگام راه‌اندازی مجدد.
- **پیکربندی سرویس `rc-local`**: راه‌اندازی یا پیکربندی سرویس `rc-local` برای اطمینان از اجرای `/etc/rc.local` در هنگام راه‌اندازی سیستم.

## پیش‌نیازها

- سیستم لینوکس با نصب ابزارهای `bash`، `ip` و `systemctl`.
- دسترسی ریشه برای تغییر `/etc/rc.local` و ایجاد سرویس‌های systemd.

## استفاده

1. **اجرای اسکریپت به‌طور مستقیم**

   برای دانلود و اجرای اسکریپت، دستور زیر را اجرا کنید:

   ```bash
   bash <(curl -H 'Cache-Control: no-cache' -sSL "https://raw.githubusercontent.com/im-api/6to4/main/6to4.sh?$(date +%s)" --ipv4)
گزینه‌های منو

1. ایران: ایجاد تونل جدید با تنظیمات پیش‌فرض برای ایران.
2. خارج: ایجاد تونل جدید با تنظیمات سفارشی برای نام منحصر به فرد.
3. لیست تونل‌ها: نمایش لیستی از تمام تونل‌های فعال.
4. حذف تونل: حذف یک تونل موجود.
5. دائمی کردن تونل: ذخیره پیکربندی تونل در /etc/rc.local.
6. پیکربندی سرویس rc-local: ایجاد یا پیکربندی سرویس rc-local برای راه‌اندازی سیستم.
7. خروج: خروج از اسکریپت.
یادداشت‌ها
اطمینان حاصل کنید که فایل /etc/rc.local اجرایی است. اسکریپت سعی خواهد کرد آن را ایجاد و پیکربندی کند اگر وجود نداشته باشد.
سرویس rc-local باید فعال و راه‌اندازی شود تا تغییرات در /etc/rc.local در هنگام راه‌اندازی سیستم اعمال شود.
مجوز
این اسکریپت تحت مجوز MIT ارائه شده است. برای جزئیات، به فایل LICENSE مراجعه کنید.

# Tunnel Management Script

This script provides functionality to manage 6to4 tunnels on a Linux system. It supports creating, listing, and removing tunnels, as well as making tunnel configurations permanent and configuring the `rc-local` service for system startup.

## Features

- **Create a Tunnel**: Add a new 6to4 tunnel with specified IPv4 and IPv6 addresses.
- **List Tunnels**: Display all active 6to4 tunnels.
- **Remove a Tunnel**: Delete an existing 6to4 tunnel.
- **Make Configuration Permanent**: Save tunnel configuration to `/etc/rc.local` for persistence across reboots.
- **Configure `rc-local` Service**: Set up the `rc-local` service to ensure `/etc/rc.local` is executed on system startup.

## Prerequisites

- Linux-based system with `bash`, `ip`, and `systemctl` utilities installed.
- Root privileges to modify `/etc/rc.local` and create systemd services.

## Usage

1. **Run the Script Directly**

   To download and execute the script, run:

   ```bash
   bash <(curl -H 'Cache-Control: no-cache' -sSL "https://raw.githubusercontent.com/im-api/6to4/main/6to4.sh?$(date +%s)" --ipv4)
Menu Options

1. Iran: Create a new tunnel with default settings for Iran.
2. Kharej: Create a new tunnel with custom settings for a unique name.
3. List tunnels: Display a list of all active tunnels.
4. Remove tunnel: Remove an existing tunnel.
5. Make tunnel permanent: Save tunnel configuration to /etc/rc.local.
6. Configure rc-local service: Create or configure the rc-local service for system startup.
7. Exit: Exit the script.



This script is provided under the MIT License.