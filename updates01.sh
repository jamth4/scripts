#!/bin/bash
#
release_file=/etc/os-release
logfile=/var/log/updater.log
errorlog=/var/log/updater_errors.log
rebootlog=/var/log/rebootneeded.log
errormess="An error occurred, please check the $errorlog file"
rebootreq="A system reboot is required.  Rebooting in 30 secs."

check_exit_status() {
	if [ $? -ne 0 ]; then
		echo $errormess
	fi
}

install_dnf_tools() {
	if ! needs-restarting -v &> /dev/null; then
		echo "yum-utils not installed.  Installing..."
		sudo /usr/bin/dnf install yum-utils -y 1>>$logfile 2>>$errorlog
		check_exit_status
	fi
}

reboot_cmd() {
	echo $rebootreq
	/usr/bin/sleep 30
	sudo /usr/sbin/reboot
}

if grep -q "Debian" $release_file || grep -q "Ubuntu" $release_file || grep -q "Raspbian" $release_file; then
	# The host is based on Debian/Ubuntu, run the apt command
	sudo /usr/bin/apt update 1>>$logfile 2>>$errorlog
	check_exit_status
	sudo /usr/bin/apt dist-upgrade -y 1>>$logfile 2>>$errorlog
	check_exit_status
	if [ -f /var/run/reboot-required ]; then
		reboot_cmd
	fi
fi

if grep -q "Fedora" $release_file; then
	# The host is based on RHEL/Fedora, run the dnf command
	install_dnf_tools
	sudo /usr/bin/dnf update -y 1>>$logfile 2>>$errorlog
	check_exit_status
	/usr/bin/needs-restarting -r > $rebootlog
	grep "Reboot is required" $rebootlog &> /dev/null
	if [ $? -eq 0 ]; then
		reboot_cmd
	fi
fi

