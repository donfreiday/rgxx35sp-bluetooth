Spent an evening hacking in support for my Bluetooth headphones on muOS/RGXX35SP, putting this out there in hopes it'll help someone.

This isn't a proper solution, there's no user-facing configuration tools or anything and I just stole the binaries I needed from Knulli :)

I hacked in a script for the SP to start bluetooth on boot. I've taken zero time to understand how muOS is supposed to work so this is definitely wrong.

I also have a script to automatically switch the audio sink but it's specific to my headphones.

### For the bold

If you want **make a backup** and you can try this with `./install.sh <ip of device>`. I accept no responsibility for the consequences

### Firmware

We need the realtek BT firmware for the SP, rtl8821c, in `/lib/firmware/rtlbt`.

### Load realtek BT kernel module

```
modprobe /lib/modules/4.9.170/kernel/drivers/bluetooth/rtl_btlpm.ko
```

### Bringing up the HCI (host controller interface) device

`rtk_hciattach` uploads firmware and configures the HCI device.
Various hci tools are in /bin, hciconfig etc. Useful for debugging.

```
rtk_hciattach -n -s 115200 /dev/ttyS1 rtk_h5 > rtk_hciattach.log 2>&1 &
```

you can check that this worked with:
```
[~]# hciconfig
hci0:	Type: Primary  Bus: UART
	BD Address: 68:8F:C9:0B:0D:B5  ACL MTU: 1021:8  SCO MTU: 255:12
	DOWN 
	RX bytes:1101 acl:0 sco:0 events:31 errors:0
	TX bytes:819 acl:0 sco:0 commands:30 errors:0
```

### Bluez 

We need bluetoothd and dbus configuration.
The DBUS config is in `/etc/dbus-1/system.d/bluetooth.conf`

```
/usr/libexec/bluetooth/bluetoothd -n -d > bluetoothd.log 2>&1 &
```

Are we having fun on our journey up the linux BT stack? I'm not.

### Pipewire

We need the plugin in /usr/lib/spa-0.2.

But wait there's more:
```
[~]# ldd /usr/lib/spa-0.2/bluez5/libspa-bluez5.so
	linux-vdso.so.1 (0x0000007fa9785000)
	libm.so.6 => /lib/libm.so.6 (0x0000007fa9603000)
	libdbus-1.so.3 => /usr/lib/libdbus-1.so.3 (0x0000007fa95ae000)
	libsbc.so.1 => /usr/lib/libsbc.so.1 (0x0000007fa95a1000)
	libbluetooth.so.3 => not found
```

So we need that too.
also need to update pipewire.conf

### Bluez, again

```
bluetoothctl power on
```

At this point you can connect your headphones

```
bluetoothctl
scan on
scan off
devices
# find your headphones
trust <HEADPHONES MAC>
pair <HEADPHONES MAC>
connect <HEADPHONES MAC>
#ctrl+d to exit bluetoothctl
```

### Wireplumber

Set the audio sink (output):

```
wpctl status
wpctl set-default 62 # sink id
```


