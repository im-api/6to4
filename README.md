<p align="center"> <img src="https://komarev.com/ghpvc/?username=6to4-tun-im-api&label=Page%20Views&color=0e75b6&style=flat" alt="im-api" /> </p>

# اسکریپت مدیریت تونل

این اسکریپت قابلیت‌هایی برای مدیریت تونل‌های 6to4 در سیستم‌های لینوکس فراهم می‌آورد. این اسکریپت شامل ایجاد، لیست کردن و حذف تونل‌ها، همچنین پایدار کردن تنظیمات تونل و پیکربندی سرویس `rc-local` برای راه‌اندازی سیستم است.

## ویژگی‌ها

- **ایجاد تونل**: افزودن تونل جدید 6to4 با آدرس‌های IPv4 و IPv6 مشخص.
- **لیست کردن تونل‌ها**: نمایش تمام تونل‌های فعال 6to4.
- **حذف تونل**: حذف یک تونل موجود.
- **پایدار کردن تنظیمات**: ذخیره تنظیمات تونل در `/etc/rc.local` برای پایدار بودن در طول راه‌اندازی مجدد.
- **پیکربندی سرویس `rc-local`**: راه‌اندازی سرویس `rc-local` برای اطمینان از اجرای `/etc/rc.local` در راه‌اندازی سیستم.

## پیش‌نیازها

- سیستم لینوکسی با نصب ابزارهای `bash`، `ip`، و `systemctl`.
- دسترسی ریشه (root) برای تغییر `/etc/rc.local` و ایجاد سرویس‌های systemd.

## نحوه استفاده

### 1. **دریافت آدرس IPv6**

برای ایجاد تونل 6to4، به یک آدرس IPv6 منحصر به فرد نیاز دارید. مراحل زیر را دنبال کنید:

1. به [تولیدکننده آدرس IPv6 منحصر به فرد](https://www.unique-local-ipv6.com) مراجعه کنید.
2. یک آدرس IPv6 منحصر به فرد تولید کنید.
3. آدرس IPv6 تولید شده را کپی کنید. از این آدرس برای پیکربندی تونل استفاده خواهید کرد.

### 2. **اجرای اسکریپت به طور مستقیم**

برای دانلود و اجرای اسکریپت، دستور زیر را اجرا کنید:

```bash
bash <(curl -H 'Cache-Control: no-cache' -sSL "https://raw.githubusercontent.com/im-api/6to4/main/6to4.sh?$(date +%s)" --ipv4)
```
## 3. گزینه‌های منو

هنگام اجرای اسکریپت، منویی با گزینه‌های زیر خواهید دید:

1. **ایران**: ایجاد یک تونل جدید با تنظیمات پیش‌فرض برای ایران.
2. **خارجی**: ایجاد یک تونل جدید با تنظیمات سفارشی برای نام منحصر به فرد.
3. **لیست تونل‌ها**: نمایش لیست تمام تونل‌های فعال.
4. **حذف تونل**: حذف یک تونل موجود.
5. **پایدار کردن تونل**: ذخیره تنظیمات تونل در `/etc/rc.local`.
6. **پیکربندی سرویس `rc-local`**: ایجاد یا پیکربندی سرویس `rc-local` برای راه‌اندازی سیستم.
7. **خروج**: خروج از اسکریپت.

## 4. ایجاد تونل

### گزینه 1: ایران

1. **انتخاب گزینه 1**: انتخاب "ایران" برای ایجاد یک تونل جدید با تنظیمات پیش‌فرض.
2. **ورود جزئیات**: آدرس IPv4 محلی، آدرس IPv4 راه دور و آدرس IPv6 پایه‌ای که دریافت کرده‌اید را وارد کنید.
   - مثال:
     - آدرس IPv4 محلی: `192.168.1.2`
     - آدرس IPv4 راه دور: `198.51.100.1`
     - آدرس IPv6 پایه: `fdcc:c4da:bc9b::`
3. **تأیید**: اسکریپت یک آدرس IPv6 منحصر به فرد تولید کرده و تونل را ایجاد خواهد کرد.

### گزینه 2: خارجی

1. **انتخاب گزینه 2**: انتخاب "خارجی" برای ایجاد تونل با تنظیمات سفارشی.
2. **ورود جزئیات**: آدرس IPv4 محلی، آدرس IPv4 راه دور، آدرس IPv6 پایه و نام منحصر به فردی برای رابط را وارد کنید.
   - مثال:
     - آدرس IPv4 محلی: `192.168.1.2`
     - آدرس IPv4 راه دور: `198.51.100.1`
     - آدرس IPv6 پایه: `fdcc:c4da:bc9b::`
     - نام رابط: `custom_tunnel`
3. **تأیید**: اسکریپت تونل را با جزئیات ارائه شده ایجاد خواهد کرد.

## 5. لیست کردن تونل‌ها

1. **انتخاب گزینه 3**: انتخاب "لیست تونل‌ها" برای نمایش تمام تونل‌های فعال 6to4.

## 6. حذف تونل

1. **انتخاب گزینه 4**: انتخاب "حذف تونل" برای حذف یک تونل موجود.
2. **انتخاب تونل**: اسکریپت تونل‌های موجود را لیست می‌کند. نام تونلی که می‌خواهید حذف کنید را وارد کنید.
3. **تأیید**: اسکریپت از شما تأیید می‌خواهد قبل از حذف تونل.

## 7. پایدار کردن تونل

1. **انتخاب گزینه 5**: انتخاب "پایدار کردن تونل" برای ذخیره تنظیمات تونل در `/etc/rc.local`.
2. **انتخاب تونل**: اسکریپت تونل‌های موجود را لیست می‌کند. نام تونلی که می‌خواهید پایدار کنید را وارد کنید.
3. **تأیید**: اسکریپت `/etc/rc.local` را با تنظیمات تونل به‌روزرسانی خواهد کرد.

## 8. پیکربندی سرویس `rc-local`

1. **انتخاب گزینه 6**: انتخاب "پیکربندی سرویس `rc-local`" برای راه‌اندازی سرویس `rc-local`.
2. **بررسی و ایجاد سرویس**: اسکریپت بررسی می‌کند که آیا فایل سرویس `rc-local` وجود دارد یا خیر. اگر وجود نداشته باشد، آن را ایجاد و پیکربندی می‌کند.
3. **بارگذاری مجدد و راه‌اندازی سرویس**: اسکریپت سرویس `rc-local` را بارگذاری و راه‌اندازی می‌کند تا اطمینان حاصل شود که `/etc/rc.local` در زمان راه‌اندازی اجرا می‌شود.

## 9. خروج از اسکریپت

1. **انتخاب گزینه 7**: انتخاب "خروج" برای بستن اسکریپت.

## یادداشت‌ها

- اطمینان حاصل کنید که فایل `/etc/rc.local` اجرایی است. اسکریپت سعی خواهد کرد آن را در صورت عدم وجود ایجاد کند.
- اسکریپت شامل پرسش‌های لازم و تأییدات برای اطمینان از عملیات صحیح است.

English
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
   ```
## Menu Options

When you run the script, you will see a menu with the following options:

- **Iran**: Create a new tunnel with default settings for Iran.
- **Foreign**: Create a new tunnel with custom settings for a unique name.
- **List Tunnels**: Display a list of all active tunnels.
- **Remove Tunnel**: Delete an existing tunnel.
- **Make Tunnel Permanent**: Save tunnel configuration to `/etc/rc.local`.
- **Configure `rc-local` Service**: Create or configure the `rc-local` service for system startup.
- **Exit**: Exit the script.

## Creating a Tunnel

### Option 1: Iran

- **Select Option 1**: Choose "Iran" to create a new tunnel with default settings.
- **Enter Details**: Provide the local IPv4 address, remote IPv4 address, and base IPv6 address you obtained.
  - Example:
    - Local IPv4 Address: `192.168.1.2`
    - Remote IPv4 Address: `198.51.100.1`
    - Base IPv6 Address: `fdcc:c4da:bc9b::`
- **Confirmation**: The script will generate a unique IPv6 address and create the tunnel.

### Option 2: Foreign

- **Select Option 2**: Choose "Foreign" to create a tunnel with custom settings.
- **Enter Details**: Provide the local IPv4 address, remote IPv4 address, base IPv6 address, and a unique name for the interface.
  - Example:
    - Local IPv4 Address: `192.168.1.2`
    - Remote IPv4 Address: `198.51.100.1`
    - Base IPv6 Address: `fdcc:c4da:bc9b::`
    - Interface Name: `custom_tunnel`
- **Confirmation**: The script will create the tunnel with the provided details.

## Listing Tunnels

- **Select Option 3**: Choose "List Tunnels" to display all active 6to4 tunnels.

## Removing a Tunnel

- **Select Option 4**: Choose "Remove Tunnel" to delete an existing tunnel.
- **Select Tunnel**: The script will list the existing tunnels. Enter the name of the tunnel you want to remove.
- **Confirmation**: The script will ask for confirmation before removing the tunnel.

## Making a Tunnel Permanent

- **Select Option 5**: Choose "Make Tunnel Permanent" to save the tunnel configuration to `/etc/rc.local`.
- **Select Tunnel**: The script will list existing tunnels. Enter the name of the tunnel you want to make permanent.
- **Confirmation**: The script will update `/etc/rc.local` with the tunnel configuration.

## Configuring the `rc-local` Service

- **Select Option 6**: Choose "Configure `rc-local` Service" to set up the `rc-local` service.
- **Check and Create Service**: The script will check if the `rc-local` service file exists. If not, it will create and configure it.
- **Reload and Start Service**: The script will reload the systemd daemon and start the `rc-local` service to ensure `/etc/rc.local` runs on system startup.

## Exiting the Script

- **Select Option 7**: Choose "Exit" to close the script.

## Notes

- Ensure that `/etc/rc.local` is executable. The script will attempt to create it if it does not exist.
- The script includes prompts and confirmations to ensure correct operations.
