#!/usr/bin/env bash

set -e
set -x

MY_VENV="$HOME/venv"
export MY_VENV

root_functions() {
    # This is the main entrypoint to the commands that modify the system.
    # The functions are defined later in the file and exported.

    set -xe

    extra_repos=(
	https://repos.fedorapeople.org/repos/spot/chromium/fedora-chromium-stable.repo
	http://negativo17.org/repos/fedora-spotify.repo
    )
    export extra_repos

    packages=(
	dopbox
	dpkg
	emacs
	emacs-color-theme
	emacs-nox
	evolution
	evolution-ews
	evolution-mapi
	git
	keepass
	openssh-server
	patchelf
	pyflakes
	python
	python-devel
	python-flake8
	python-jedi
	python-pip
	python-virtualenv
	spotify-client
    )
    export packages


    add_repos
    install_packages
    configure_ssh
    configure_cronjobs
}
export -f root_functions


add_repos() {
    yum localinstall --nogpgcheck -y \
	http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    for repo in ${extra_repos[@]}; do
	yum-config-manager --add-repo=$repo
    done
}
export -f add_repos

install_packages() {
    yum -y install ${packages[@]}
}
export -f install_packages

configure_ssh() {
    systemctl enable sshd
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
}
export -f configure_ssh
    


configure_cronjobs() {
    sed -i 's/START_HOURS_RANGE=3-22/START_HOURS_RANGE=19-7/' /etc/anacrontab
    echo 'yum -y --skip-broken --exclude=kernel\* update' >/etc/cron.daily/system-updateEOF
    chmod +x /etc/cron.daily/system-update
    systemctl restart crond
}
export -f configure_cronjobs


create_venv() {
    test -d $MY_VENV && return 1
    virtualenv $MY_VENV
}

su -c root_functions

create_venv
