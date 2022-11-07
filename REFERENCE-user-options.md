# User Options

User configuration functions to set variables to be used during installation

# Functions
* [aur_helper()](#aur_helper)
* [desktop_environment()](#desktop_environment)
* [disk_select()](#disk_select)
* [filesystem()](#filesystem)
* [install_type()](#install_type)
* [keymap()](#keymap)
* [set_btrfs()](#set_btrfs)
* [set_password()](#set_password)
* [timezone()](#timezone)
* [user_info()](#user_info)


## aur_helper()

Choose AUR helper.

### Output on stdout

* Output routed to install.log

### Output on stderr

* # @stderror Output routed to install.log

_Function has no arguments._

## desktop_environment()

Choose Desktop Environment

_Function has no arguments._

## disk_select()

Disk selection for drive to be used with installation.

_Function has no arguments._

## filesystem()

This function will handle file systems. At this movement we are handling only
btrfs and ext4. Others will be added in future.

_Function has no arguments._

## install_type()

Choose whether to do full or minimal installation.

_Function has no arguments._

## keymap()

Set user's keyboard mapping.

_Function has no arguments._

## set_btrfs()

Set btrfs subvolumes to be used during install

_Function has no arguments._

## set_password()

Read and verify user password before setting

_Function has no arguments._

## timezone()

Detects and sets timezone.

_Function has no arguments._

## user_info()

Gather username and password to be used for installation.

_Function has no arguments._


