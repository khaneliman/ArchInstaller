# System Config

Contains the functions used to modify the system

# Functions
* [add_user()](#add_user)
* [cpu_config()](#cpu_config)
* [create_filesystems()](#create_filesystems)
* [display_manager()](#display_manager)
* [do_btrfs()](#do_btrfs)
* [format_disk()](#format_disk)
* [grub_config()](#grub_config)
* [locale_config()](#locale_config)
* [low_memory_config()](#low_memory_config)
* [mirrorlist_update()](#mirrorlist_update)
* [plymouth_config()](#plymouth_config)
* [snapper_config()](#snapper_config)


## add_user()

Adds user that was setup prior to installation

### Output on stdout

* Output routed to install.log

### Output on stderr

* # @stderror Output routed to install.log

_Function has no arguments._

## cpu_config()

Configures makepkg settings dependent on cpu cores

_Function has no arguments._

## create_filesystems()

Create the filesystem on the drive selected for installation

_Function has no arguments._

## display_manager()

Install and enable display manager depending on desktop environment chosen

_Function has no arguments._

## do_btrfs()

Perform the btrfs filesystem configuration

_Function has no arguments._

## format_disk()

Format disk before creatign filesystem

_Function has no arguments._

## grub_config()

Theme grub

_Function has no arguments._

## locale_config()

Set locale, timezone, and keymap

_Function has no arguments._

## low_memory_config()

Confgiure swap on low memory systems

_Function has no arguments._

## mirrorlist_update()

Update mirrorlist to improve download speeds

_Function has no arguments._

## plymouth_config()

Install plymouth splash

_Function has no arguments._

## snapper_config()

Configure snapper default setup

_Function has no arguments._


