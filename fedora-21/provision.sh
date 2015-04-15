#!/usr/bin/env bash

set -e
set -x

MY_VENV="$HOME/venv"
export MY_VENV

root_functions() {
    # This is the main entrypoint to the commands that modify the system.
    # The functions are defined later in the file and exported.

    set -xe

    copr_repos=(
        phracek/PyCharm
        nickth/ssr
    )

    extra_repos=(
        https://repos.fedorapeople.org/repos/spot/chromium/fedora-chromium-stable.repo
        http://negativo17.org/repos/fedora-spotify.repo
        http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
    )
    export extra_repos

    packages=(
	dopbox
	dpkg
	emacs
	emacs-color-theme
	evolution
	evolution-ews
	evolution-mapi
	git
        gitk
        graphviz
        graphviz-devel
	keepass
	openssh-server
	patchelf
        pycharm-community
	pyflakes
	python
	python-devel
	python-flake8
	python-jedi
	python-pip
	python-virtualenv
        spotify-client
        thunderbird

        vagrant
        glibc-headers
        glibc-devel
        kernel-headers
        kernel-devel
        VirtualBox
        kmod-VirtualBox

        blender
        smplayer
        ssr
    )
    export packages


    add_repos
    install_packages
    configure_ssh
    configure_cronjobs
}
export -f root_functions


add_repos() {
    yum install -y yum-plugin-copr
    for repo in ${copr_repos[@]}; do
        yum -y copr enable $repo
    done

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
    sed -i 's/START_HOURS_RANGE=3-22/START_HOURS_RANGE=19-23/' /etc/anacrontab
    echo 'yum -y --skip-broken --exclude=kernel\* update' >/etc/cron.daily/system-updateEOF
    chmod +x /etc/cron.daily/system-update
    systemctl restart crond
}
export -f configure_cronjobs


setup_venv() {
    test -d $VENV_DIR || mkdir -vp $VENV_DIR
}


su -c root_functions

setup_venv
