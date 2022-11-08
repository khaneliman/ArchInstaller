# Installer Helper

Contains the functions used to facilitate the installer

# Functions
* [end()](#end)
* [exit_on_error()](#exit_on_error)
* [logo()](#logo)
* [sequence()](#sequence)
* [set_option()](#set_option)
* [source_file()](#source_file)


## end()

Copy logs to installed system and exit script

### Output on stdout

* Output routed to install.log

### Output on stderr

* # @stderror Output routed to install.log

_Function has no arguments._

## exit_on_error()

Exits script if previous command fails

### Arguments

* **$1** (string): Exit code of previous command

### Arguments

* **$2** (string): Previous command

## logo()

Displays archinstaller logo

_Function has no arguments._

## sequence()

Sequence to call scripts

_Function has no arguments._

## set_option()

set options in setup.conf

### Arguments

* **$1** (string): Configuration variable.

### Arguments

* **$2** (string): Configuration value.

## source_file()

Sources file to be used by the script

### Arguments

* **$1** (File): to source


