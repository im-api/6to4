اسکریپت مدیریت تونل
این اسکریپت قابلیت‌هایی برای مدیریت تونل‌های 6to4 در سیستم‌های لینوکس فراهم می‌آورد. این اسکریپت شامل ایجاد، لیست کردن و حذف تونل‌ها، همچنین پایدار کردن تنظیمات تونل و پیکربندی سرویس rc-local برای راه‌اندازی سیستم است.

ویژگی‌ها
ایجاد تونل: افزودن تونل جدید 6to4 با آدرس‌های IPv4 و IPv6 مشخص.
لیست کردن تونل‌ها: نمایش تمام تونل‌های فعال 6to4.
حذف تونل: حذف یک تونل موجود.
پایدار کردن تنظیمات: ذخیره تنظیمات تونل در /etc/rc.local برای پایدار بودن در طول راه‌اندازی مجدد.
پیکربندی سرویس rc-local: راه‌اندازی سرویس rc-local برای اطمینان از اجرای /etc/rc.local در راه‌اندازی سیستم.
پیش‌نیازها
سیستم لینوکسی با نصب ابزارهای bash، ip، و systemctl.
دسترسی ریشه (root) برای تغییر /etc/rc.local و ایجاد سرویس‌های systemd.
نحوه استفاده
1. دریافت آدرس IPv6
برای ایجاد تونل 6to4، به یک آدرس IPv6 منحصر به فرد نیاز دارید. مراحل زیر را دنبال کنید:

به تولیدکننده آدرس IPv6 منحصر به فرد مراجعه کنید.
یک آدرس IPv6 منحصر به فرد تولید کنید.
آدرس IPv6 تولید شده را کپی کنید. از این آدرس برای پیکربندی تونل استفاده خواهید کرد.
2. اجرای اسکریپت به طور مستقیم
برای دانلود و اجرای اسکریپت، دستور زیر را اجرا کنید:

bash
Copy code
bash <(curl -H 'Cache-Control: no-cache' -sSL "https://raw.githubusercontent.com/im-api/6to4/main/6to4.sh?$(date +%s)" --ipv4)
3. گزینه‌های منو
هنگام اجرای اسکریپت، منویی با گزینه‌های زیر خواهید دید:

ایران: ایجاد یک تونل جدید با تنظیمات پیش‌فرض برای ایران.
خارجی: ایجاد یک تونل جدید با تنظیمات سفارشی برای نام منحصر به فرد.
لیست تونل‌ها: نمایش لیست تمام تونل‌های فعال.
حذف تونل: حذف یک تونل موجود.
پایدار کردن تونل: ذخیره تنظیمات تونل در /etc/rc.local.
پیکربندی سرویس rc-local: ایجاد یا پیکربندی سرویس rc-local برای راه‌اندازی سیستم.
خروج: خروج از اسکریپت.
4. ایجاد تونل
گزینه 1: ایران
انتخاب گزینه 1: انتخاب "ایران" برای ایجاد یک تونل جدید با تنظیمات پیش‌فرض.
ورود جزئیات: آدرس IPv4 محلی، آدرس IPv4 راه دور و آدرس IPv6 پایه‌ای که دریافت کرده‌اید را وارد کنید.
مثال:
آدرس IPv4 محلی: 192.168.1.2
آدرس IPv4 راه دور: 198.51.100.1
آدرس IPv6 پایه: fdcc:c4da:bc9b::
تأیید: اسکریپت یک آدرس IPv6 منحصر به فرد تولید کرده و تونل را ایجاد خواهد کرد.
گزینه 2: خارجی
انتخاب گزینه 2: انتخاب "خارجی" برای ایجاد تونل با تنظیمات سفارشی.
ورود جزئیات: آدرس IPv4 محلی، آدرس IPv4 راه دور، آدرس IPv6 پایه و نام منحصر به فردی برای رابط را وارد کنید.
مثال:
آدرس IPv4 محلی: 192.168.1.2
آدرس IPv4 راه دور: 198.51.100.1
آدرس IPv6 پایه: fdcc:c4da:bc9b::
نام رابط: custom_tunnel
تأیید: اسکریپت تونل را با جزئیات ارائه شده ایجاد خواهد کرد.
5. لیست کردن تونل‌ها
انتخاب گزینه 3: انتخاب "لیست تونل‌ها" برای نمایش تمام تونل‌های فعال 6to4.
6. حذف تونل
انتخاب گزینه 4: انتخاب "حذف تونل" برای حذف یک تونل موجود.
انتخاب تونل: اسکریپت تونل‌های موجود را لیست می‌کند. نام تونلی که می‌خواهید حذف کنید را وارد کنید.
تأیید: اسکریپت از شما تأیید می‌خواهد قبل از حذف تونل.
7. پایدار کردن تونل
انتخاب گزینه 5: انتخاب "پایدار کردن تونل" برای ذخیره تنظیمات تونل در /etc/rc.local.
انتخاب تونل: اسکریپت تونل‌های موجود را لیست می‌کند. نام تونلی که می‌خواهید پایدار کنید را وارد کنید.
تأیید: اسکریپت /etc/rc.local را با تنظیمات تونل به‌روزرسانی خواهد کرد.
8. پیکربندی سرویس rc-local
انتخاب گزینه 6: انتخاب "پیکربندی سرویس rc-local" برای راه‌اندازی سرویس rc-local.
بررسی و ایجاد سرویس: اسکریپت بررسی می‌کند که آیا فایل سرویس rc-local وجود دارد یا خیر. اگر وجود نداشته باشد، آن را ایجاد و پیکربندی می‌کند.
بارگذاری مجدد و راه‌اندازی سرویس: اسکریپت سرویس rc-local را بارگذاری و راه‌اندازی می‌کند تا اطمینان حاصل شود که /etc/rc.local در زمان راه‌اندازی اجرا می‌شود.
9. خروج از اسکریپت
انتخاب گزینه 7: انتخاب "خروج" برای بستن اسکریپت.
یادداشت‌ها
اطمینان حاصل کنید که فایل /etc/rc.local اجرایی است. اسکریپت سعی خواهد کرد آن را در صورت عدم وجود ایجاد کند.
اسکریپت شامل پرسش‌های لازم و تأییدات برای اطمینان از عملیات صحیح است.



English
Tunnel Management Script
This script provides functionality to manage 6to4 tunnels on a Linux system. It supports creating, listing, and removing tunnels, as well as making tunnel configurations permanent and configuring the rc-local service for system startup.

Features
Create a Tunnel: Add a new 6to4 tunnel with specified IPv4 and IPv6 addresses.
List Tunnels: Display all active 6to4 tunnels.
Remove a Tunnel: Delete an existing 6to4 tunnel.
Make Configuration Permanent: Save tunnel configuration to /etc/rc.local for persistence across reboots.
Configure rc-local Service: Set up the rc-local service to ensure /etc/rc.local is executed on system startup.
Prerequisites
Linux-based system with bash, ip, and systemctl utilities installed.
Root privileges to modify /etc/rc.local and create systemd services.
Usage
1. Obtain IPv6 Address
To create a 6to4 tunnel, you need a unique IPv6 address. Follow these steps:

Visit Unique Local IPv6 Generator.
Generate a unique IPv6 address.
Copy the generated IPv6 address. You will use this address for configuring your tunnel.
2. Run the Script Directly
To download and execute the script, run:

bash
Copy code
bash <(curl -H 'Cache-Control: no-cache' -sSL "https://raw.githubusercontent.com/im-api/6to4/main/6to4.sh?$(date +%s)" --ipv4)
3. Menu Options
When you run the script, you will see a menu with the following options:

Iran: Create a new tunnel with default settings for Iran.
Kharej: Create a new tunnel with custom settings for a unique name.
List tunnels: Display a list of all active tunnels.
Remove tunnel: Remove an existing tunnel.
Make tunnel permanent: Save tunnel configuration to /etc/rc.local.
Configure rc-local service: Create or configure the rc-local service for system startup.
Exit: Exit the script.
4. Create a Tunnel
Option 1: Iran
Select Option 1: Choose "Iran" to create a new tunnel with default settings.
Input Details: Enter the local IPv4 address, remote IPv4 address, and the base IPv6 address you obtained.
Example:
Local IPv4 address: 192.168.1.2
Remote IPv4 address: 198.51.100.1
Base IPv6 address: fdcc:c4da:bc9b::
Confirmation: The script will generate a unique IPv6 address and create the tunnel.
Option 2: Kharej
Select Option 2: Choose "Kharej" to create a tunnel with custom settings.
Input Details: Enter the local IPv4 address, remote IPv4 address, the base IPv6 address, and provide a unique name for the interface.
Example:
Local IPv4 address: 192.168.1.2
Remote IPv4 address: 198.51.100.1
Base IPv6 address: fdcc:c4da:bc9b::
Interface name: custom_tunnel
Confirmation: The script will create the tunnel with the provided details.
5. List Tunnels
Select Option 3: Choose "List tunnels" to display all active 6to4 tunnels.
6. Remove a Tunnel
Select Option 4: Choose "Remove tunnel" to delete an existing tunnel.
Select Tunnel: The script will list available tunnels. Enter the name of the tunnel you wish to remove.
Confirmation: The script will ask for confirmation before deleting the tunnel.
7. Make Tunnel Permanent
Select Option 5: Choose "Make tunnel permanent" to save the tunnel configuration to /etc/rc.local.
Select Tunnel: The script will list available tunnels. Enter the name of the tunnel you want to make permanent.
Confirmation: The script will update /etc/rc.local with the tunnel configuration.
8. Configure rc-local Service
Select Option 6: Choose "Configure rc-local service" to set up the rc-local service.
Check and Create Service: The script will check if the rc-local service file exists. If not, it will create and configure the service.
Reload and Start Service: The script will reload the systemd daemon and start the rc-local service to ensure /etc/rc.local is executed at boot.
9. Exit the Script
Select Option 7: Choose "Exit" to close the script.
Notes
Ensure the /etc/rc.local file is executable. The script will attempt to create it if it does not exist.
The script includes prompts for necessary information and confirmations to ensure proper operation.
