#!/bin/bash

# Command "Display Properties".

# Import file manager variables (scroll down for info).
$fm_import

# Localization, requirements, variables, files and functions.
. "$fm_cmd_dir/init.inc.sh"

########################################################################
##
## Main script code.
##
########################################################################

getTrashedFiles
getTrashSize

# Human readable trash size. I could use "du -bhs", but it rounds up, and passed
# 10, no decimal is used (for example, 14.1 is rounded up 15). Therefore, I do it
# by hand to have a better result. Note that Bash doesn't handle floating point
# arithmetic, so I use integer divison and modulo (I could use the command "bc",
# but it would add another depedency).

quotient=$trashSize

# 0 => B
# 1 => KiB
# 2 => MiB
# and so on
unitIndex=-1

while ((quotient > 0)); do
	((quotient = quotient / 1024))
	((++unitIndex))
done

if ((unitIndex > 0)); then
	((divisorInBytes = 1024**unitIndex))
	((quotient1      = trashSize         / $divisorInBytes))
	((remainder1     = trashSize         % $divisorInBytes))
	((quotient2      = (remainder1 * 10) / $divisorInBytes))
	((remainder2     = (remainder1 * 10) % $divisorInBytes))
	((quotient3      = (remainder2 * 10) / $divisorInBytes))
	((remainder3     = (remainder2 * 10) % $divisorInBytes))
	
	# Rounding the first decimal.
	if ((quotient3 >= 5)); then
		if [[ $quotient2 == 9 ]]; then
			((++quotient1))
			quotient2=0
		else
			((++quotient2))
		fi
	fi
	
	decimalSeparator=.
	
	# Make the decimal separator to follow locale.
	if type locale > /dev/null 2>&1; then
		lcNumeric=$(locale -k LC_NUMERIC)
		
		if [[ $lcNumeric =~ decimal_point=\"(.)\" ]]; then
			decimalSeparator=${BASH_REMATCH[1]}
		fi
	fi
	
	humanReadableSize=$quotient1$decimalSeparator$quotient2
else
	unitIndex=0 # In case we have a negative index.
	humanReadableSize=$trashSize
fi

printf "${msg[PROP_TITLE]}\n\n"
printf "${msg[PROP_NUMBER]}\n" "${#trashedFiles[@]}"
printf "${msg[PROP_SIZE]}" "$humanReadableSize" "${msg[UNIT_$unitIndex]}"

if ((unitIndex > 0)); then
	printf " ${msg[PROP_SIZE_B]}" "$trashSize"
fi

exit $?

# Example variables available for use: (imported by $fm_import)
# These variables represent the state of the file manager when command is run.
# These variables can also be used in command lines and in the Smartbar.

# "${fm_files[@]}"          selected files              ( same as %F )
# "$fm_file"                first selected file         ( same as %f )
# "${fm_files[2]}"          third selected file

# "${fm_filenames[@]}"      selected filenames          ( same as %N )
# "$fm_filename"            first selected filename     ( same as %n )

# "$fm_pwd"                 current directory           ( same as %d )
# "${fm_pwd_tab[4]}"        current directory of tab 4
# $fm_panel                 current panel numberOfFiles (1-4)
# $fm_tab                   current tab numberOfFiles

# "${fm_panel3_files[@]}"   selected files in panel 3
# "${fm_pwd_panel[3]}"      current directory in panel 3
# "${fm_pwd_panel3_tab[2]}" current directory in panel 3 tab 2
# ${fm_tab_panel[3]}        current tab numberOfFiles in panel 3

# "${fm_desktop_files[@]}"  selected files on desktop (when run from desktop)
# "$fm_desktop_pwd"         desktop directory (eg '/home/user/Desktop')

# "$fm_device"              selected device (eg /dev/sr0)  ( same as %v )
# "$fm_device_udi"          device ID
# "$fm_device_mount_point"  device mount point if mounted (eg /media/dvd) (%m)
# "$fm_device_label"        device volume label            ( same as %l )
# "$fm_device_fstype"       device fs_type (eg vfat)
# "$fm_device_size"         device volume size in bytes
# "$fm_device_display_name" device display name
# "$fm_device_icon"         icon currently shown for this device
# $fm_device_is_mounted     device is mounted (0=no or 1=yes)
# $fm_device_is_optical     device is an optical drive (0 or 1)
# $fm_device_is_table       a partition table (usually a whole device)
# $fm_device_is_floppy      device is a floppy drive (0 or 1)
# $fm_device_is_removable   device appears to be removable (0 or 1)
# $fm_device_is_audiocd     optical device contains an audio CD (0 or 1)
# $fm_device_is_dvd         optical device contains a DVD (0 or 1)
# $fm_device_is_blank       device contains blank media (0 or 1)
# $fm_device_is_mountable   device APPEARS to be mountable (0 or 1)
# $fm_device_nopolicy       udisks no_policy set (no automount) (0 or 1)

# "$fm_panel3_device"       panel 3 selected device (eg /dev/sdd1)
# "$fm_panel3_device_udi"   panel 3 device ID
# ...                       (all these are the same as above for each panel)

# "fm_bookmark"             selected bookmark directory     ( same as %b )
# "fm_panel3_bookmark"      panel 3 selected bookmark directory

# "fm_task_type"            currently SELECTED task type (eg 'run','copy')
# "fm_task_name"            selected task name (custom menu item name)
# "fm_task_pwd"             selected task working directory ( same as %t )
# "fm_task_pid"             selected task pid               ( same as %p )
# "fm_task_command"         selected task command

# "$fm_command"             current command
# "$fm_value"               menu item value             ( same as %a )
# "$fm_user"                original user who ran this command
# "$fm_cmd_name"            menu name of current command
# "$fm_cmd_dir"             command files directory (for read only)
# "$fm_cmd_data"            command data directory (must create)
#                                 To create:   mkdir -p "$fm_cmd_data"
# "$fm_plugin_dir"          top plugin directory
# tmp="$(fm_new_tmp)"       makes new temp directory (destroy when done)
#                                 To destroy:  rm -rf "$tmp"

# $fm_import                command to import above variables (this
#                           variable is exported so you can use it in any
#                           script run from this script)


# Script Example 1:

#   # show MD5 sums of selected files
#   md5sum "${fm_files[@]}"


# Script Example 2:

#   # Build list of filenames in panel 4:
#   i=0
#   for f in "${fm_panel4_files[@]}"; do
#       panel4_names[$i]="$(basename "$f")"
#       (( i++ ))
#   done
#   echo "${panel4_names[@]}"


# Script Example 3:

#   # Copy selected files to panel 2
#      # make sure panel 2 is visible ?
#      # and files are selected ?
#      # and current panel isn't 2 ?
#   if [ "${fm_pwd_panel[2]}" != "" ] \
#               && [ "${fm_files[0]}" != "" ] \
#               && [ "$fm_panel" != 2 ]; then
#       cp "${fm_files[@]}" "${fm_pwd_panel[2]}"
#   else
#       echo "Can't copy to panel 2"
#       exit 1    # shows error if 'Popup Error' enabled
#   fi


# Bash Scripting Guide:  http://www.tldp.org/LDP/abs/html/index.html

# NOTE: Additional variables or examples may be available in future versions.
#       Create a new command script to see the latest list of variables.
