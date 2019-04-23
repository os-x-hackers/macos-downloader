#!/bin/sh

parameters="${1}${2}${3}${4}${5}${6}${7}${8}${9}"

Escape_Variables()
{
	text_progress="\033[38;5;113m"
	text_success="\033[38;5;113m"
	text_warning="\033[38;5;221m"
	text_error="\033[38;5;203m"
	text_message="\033[38;5;75m"

	text_bold="\033[1m"
	text_faint="\033[2m"
	text_italic="\033[3m"
	text_underline="\033[4m"

	erase_style="\033[0m"
	erase_line="\033[0K"

	move_up="\033[1A"
	move_down="\033[1B"
	move_foward="\033[1C"
	move_backward="\033[1D"
}

Parameter_Variables()
{
	if [[ $parameters == *"-v"* || $parameters == *"-verbose"* ]]; then
		verbose="1"
		set -x
	fi
}

Path_Variables()
{
	script_path="${0}"
	directory_path="${0%/*}"

	resources_path="$directory_path/resources"
}

Input_Off()
{
	stty -echo
}
Input_On()
{
	stty echo
}

Output_Off() {
	if [[ $verbose == "1" ]]; then
		"$@"
	else
		"$@" &>/dev/null
	fi
}

Check_Environment()
{
	echo ${text_progress}"> Checking system environment."${erase_style}
	if [ -d /Install\ *.app ]; then
		environment="installer"
	fi
	if [ ! -d /Install\ *.app ]; then
		environment="system"
	fi
	echo ${move_up}${erase_line}${text_success}"+ Checked system environment."${erase_style}
}

Check_Root()
{
	echo ${text_progress}"> Checking for root permissions."${erase_style}
	if [[ $environment == "installer" ]]; then
		root_check="passed"
		echo ${move_up}${erase_line}${text_success}"+ Root permissions check passed."${erase_style}
	else
		if [[ $(whoami) == "root" && $environment == "system" ]]; then
			root_check="passed"
			echo ${move_up}${erase_line}${text_success}"+ Root permissions check passed."${erase_style}
		fi
		if [[ ! $(whoami) == "root" && $environment == "system" ]]; then
			root_check="failed"
			echo ${text_error}"- Root permissions check failed."${erase_style}
			echo ${text_message}"/ Run this tool with root permissions."${erase_style}
			Input_On
			exit
		fi
	fi
}

Check_Resources()
{
	echo ${text_progress}"> Checking for resources."${erase_style}
	if [[ -d "$resources_path" ]]; then
		resources_check="passed"
		echo ${move_up}${erase_line}${text_success}"+ Resources check passed."${erase_style}
	fi
	if [[ ! -d "$resources_path" ]]; then
		resources_check="failed"
		echo ${text_error}"- Resources check failed."${erase_style}
		echo ${text_message}"/ Run this tool with the required resources."${erase_style}
		Input_On
		exit
	fi
}

Check_Internet()
{
	echo ${text_progress}"> Checking for internet conectivity."${erase_style}
	if [[ $(ping -c 5 www.google.com) == *transmitted* && $(ping -c 5 www.google.com) == *received* ]]; then
		echo ${move_up}${erase_line}${text_success}"+ Integrity conectivity check passed."${erase_style}
	else
		echo ${text_error}"- Integrity conectivity check failed."${erase_style}
		echo ${text_message}"/ Run this tool while connected to the internet."${erase_style}
		Input_On
		exit
	fi
}

Input_Folder()
{
	echo ${text_message}"/ What save folder would you like to use?"${erase_style}
	echo ${text_message}"/ Input a save folder path."${erase_style}

	Input_On
	read -e -p "/ " save_folder
	Input_Off
}

Input_Operation_Version()
{
	echo ${text_message}"/ What operation would you like to run?"${erase_style}
	echo ${text_message}"/ Input an operation number."${erase_style}
	echo ${text_message}"/     1 - Mojave"${erase_style}
	echo ${text_message}"/     2 - High Sierra"${erase_style}
	Input_On
	read -e -p "/ " operation_version
	Input_Off

	if [[ $operation_version == "1" ]]; then
		installer_choice="m"
	fi
	if [[ $operation_version == "2" ]]; then
		installer_choice="hs"
	fi
}

Import_Variables()
{
	curl -L -s -o /tmp/resources.zip https://github.com/rmc-team/macos-downloader-resources/archive/master.zip
	unzip -q /tmp/resources.zip -d /tmp
	chmod +x /tmp/macos-downloader-resources-master/resources/var.sh
	source /tmp/macos-downloader-resources-master/resources/var.sh

	installer_url="${installer_choice}_installer_url"
	installer_key="${!installer_url#*/*/}"
	installer_key="${installer_key%/*}"
	update_key="${update_url#*/*/}"
	update_key="${update_key%/*}"
	combo_update_key="${combo_update_url#*/*/}"
	combo_update_key="${combo_update_key%/*}"

	curl -L -s -o /tmp/$installer_key.dist https://swdist.apple.com/content/downloads/${!installer_url}/$installer_key.English.dist
	curl -L -s -o /tmp/$update_key.dist https://swdist.apple.com/content/downloads/$update_url/$update_key.English.dist

	installer_name="$(grep "\"SU_TITLE\"\ =" /tmp/$installer_key.dist)"
	installer_name="${installer_name#*SU_TITLE*=*\"}"
	installer_name="${installer_name%\"*}"
	update_version="$(grep -A1 "ProductVersion" /tmp/$update_key.dist)"
	update_version="${update_version#*<string>}"
	update_version="${update_version%</string>*}"
}

Input_Operation_Download()
{
	echo ${text_message}"/ What operation would you like to run?"${erase_style}
	echo ${text_message}"/ Input an operation number."${erase_style}
	echo ${text_message}"/     1 - Installer"${erase_style}
	if [[ $update_option == "1" && $installer_choice == "m" ]]; then
		echo ${text_message}"/     2 - Update"${erase_style}
	fi
	if [[ $combo_update_option == "1" && $installer_choice == "m" ]]; then
		echo ${text_message}"/     3 - Combo Update"${erase_style}
	fi
	Input_On
	read -e -p "/ " operation_download
	Input_Off

	if [[ $operation_download == "1" ]]; then
		Download_Installer
		Prepare_Installer
	fi
	if [[ $operation_download == "2" ]]; then
		update_name="macOSUpd"
		update_url="$update_url"
		update_key="$update_key"
		Download_Update
		Prepare_Update
	fi
	if [[ $operation_download == "3" ]]; then
		update_name="macOSUpdCombo"
		update_url="$combo_update_url"
		update_key="$combo_update_key"
		Download_Update
		Prepare_Update
	fi
}

Download_Installer()
{
	echo ${text_progress}"> Downloading installer files."${erase_style}
	mkdir /tmp/"Install $installer_name"
	installer_folder="/tmp/Install $installer_name"

	curl -L -s -o "$installer_folder"/InstallAssistantAuto.pkg http://swcdn.apple.com/content/downloads/${!installer_url}/InstallAssistantAuto.pkg
	curl -L -s -o "$installer_folder"/InstallESDDmg.pkg http://swcdn.apple.com/content/downloads/${!installer_url}/InstallESDDmg.pkg
	curl -L -s -o "$installer_folder"/RecoveryHDMetaDmg.pkg http://swcdn.apple.com/content/downloads/${!installer_url}/RecoveryHDMetaDmg.pkg
	echo ${move_up}${erase_line}${text_success}"+ Downloaded installer files."${erase_style}
}

Prepare_Installer()
{
	echo ${text_progress}"> Preparing installer."${erase_style}
	cd "$save_folder"

	chmod +x "$resources_path"/pbzx
	"$resources_path"/pbzx "$installer_folder"/InstallAssistantAuto.pkg | Output_Off cpio -i

	cp "$installer_folder"/InstallESDDmg.pkg "$save_folder"/"Install $installer_name.app"/Contents/SharedSupport/InstallESD.dmg
	mv "$installer_folder"/RecoveryHDMetaDmg.pkg "$installer_folder"/RecoveryHDMeta.dmg

	Output_Off hdiutil attach "$installer_folder"/RecoveryHDMeta.dmg -mountpoint /tmp/RecoveryHDMeta -nobrowse
	cp -R /tmp/RecoveryHDMeta/ "$save_folder"/"Install $installer_name.app"/Contents/SharedSupport/
	Output_Off hdiutil detach /tmp/RecoveryHDMeta

	touch "$save_folder"/"Install $installer_name.app"
	echo ${move_up}${erase_line}${text_success}"+ Prepared installer."${erase_style}
}

Download_Update()
{
	echo ${text_progress}"> Downloading update files."${erase_style}
	mkdir /tmp/"$update_name$update_version"
	update_folder="/tmp/$update_name$update_version"

	curl -L -s -o "$update_folder"/macOSBrain.pkg http://swcdn.apple.com/content/downloads/$update_url/macOSBrain.pkg
	curl -L -s -o "$update_folder"/SecureBoot.pkg http://swcdn.apple.com/content/downloads/$update_url/SecureBoot.pkg
	curl -L -s -o "$update_folder"/EmbeddedOSFirmware.pkg http://swcdn.apple.com/content/downloads/$update_url/EmbeddedOSFirmware.pkg
	curl -L -s -o "$update_folder"/FirmwareUpdate.pkg http://swcdn.apple.com/content/downloads/$update_url/FirmwareUpdate.pkg
	curl -L -s -o "$update_folder"/FullBundleUpdate.pkg http://swcdn.apple.com/content/downloads/$update_url/FullBundleUpdate.pkg
	curl -L -s -o "$update_folder"/$update_name$update_version.pkg http://swcdn.apple.com/content/downloads/$update_url/$update_name$update_version.pkg
	curl -L -s -o "$update_folder"/$update_name$update_version.RecoveryHDUpdate.pkg http://swcdn.apple.com/content/downloads/$update_url/$update_name$update_version.RecoveryHDUpdate.pkg
	curl -L -s -o "$update_folder"/$update_key.dist https://swdist.apple.com/content/downloads/$update_url/$update_key.English.dist
	echo ${move_up}${erase_line}${text_success}"+ Downloaded update files."${erase_style}
}

Prepare_Update()
{
	echo ${text_progress}"> Preparing update."${erase_style}
	sed -i '' 's|<pkg-ref id="com\.apple\.pkg\.update\.os\.10\.14\.[0-9]\{1,\}Patch\.[a-zA-Z0-9]\{1,\}" auth="Root" packageIdentifier="com\.apple\.pkg\.update\.os\.10\.14\.[0-9]\{1,\}\.[a-zA-Z0-9]\{1,\}" onConclusion="RequireRestart">macOSUpd10\.14\.[0-9]\{1,\}Patch\.pkg<\/pkg-ref>||' "$update_folder"/$update_key.dist
	Output_Off productbuild --distribution "$update_folder"/$update_key.dist --package-path "$update_folder" "$save_folder/$update_name$update_version.pkg"
	echo ${move_up}${erase_line}${text_success}"+ Prepared update."${erase_style}
}

End()
{
	echo ${text_progress}"> Removing temporary files."${erase_style}
	Output_Off rm -R /tmp/*
	echo ${move_up}${erase_line}${text_success}"+ Removed temporary files."${erase_style}

	echo ${text_message}"/ Thank you for using macOS Downloader."${erase_style}
	Input_On
	exit
}

Input_Off
Escape_Variables
Parameter_Variables
Path_Variables
Check_Environment
Check_Root
Check_Resources
Check_Internet
Input_Folder
Input_Operation_Version
Import_Variables
Input_Operation_Download
End