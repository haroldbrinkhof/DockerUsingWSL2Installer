
function asRoot(){
     echo "$@" | wsl --user root -d "$DISTRO";
}
function asDocker(){
     echo "$@" | wsl --user docker -d "$DISTRO";
}

function installDistro(){
     cat splashScreen_vm_not_there;
     read -p "";
     wsl --install -d "$DISTRO";
}

function terminateDistro(){
     wsl -t "$DISTRO";
}

function setAptProxySettings(){
	PROXIES="Acquire::http::Proxy \\\"${HTTP_PROXY_SCHEME}://${HTTP_USER}:${HTTP_PASSWORD}@${HTTP_URL}\\\";"; 
	PROXIES+=$'\n';
	PROXIES+="Acquire::https::Proxy \\\"${HTTPS_PROXY_SCHEME}://${HTTPS_USER}:${HTTPS_PASSWORD}@${HTTPS_URL}\\\";"; 

	asRoot "echo \"$PROXIES\" > /etc/apt/apt.conf.d/proxy.conf";

}

function setDockerProxySettings(){
	asRoot "jo -p proxies=\$(jo default=\$(jo httpProxy='${HTTP_PROXY_SCHEME}://${HTTP_USER}:${HTTP_PASSWORD}@${HTTP_URL}' httpsProxy='${HTTPS_PROXY_SCHEME}://{$HTTPS_USER}:${HTTPS_PASSWORD}@${HTTPS_URL}')) > /root/.docker/config.json";

	asDocker "test -d /home/docker/.docker || mkdir /home/docker/.docker";
	asDocker "jo -p proxies=\$(jo default=\$(jo httpProxy='${HTTP_PROXY_SCHEME}://${HTTP_USER}:${HTTP_PASSWORD}@${HTTP_URL}' httpsProxy='${HTTPS_PROXY_SCHEME}://{$HTTPS_USER}:${HTTPS_PASSWORD}@${HTTPS_URL}')) > /home/docker/.docker/config.json";
}

function addDockerUserAndConfigure(){

	asRoot "groupadd -f docker"
	asRoot "(id -u docker >/dev/null 2>&1) || (echo "adding user docker" && useradd -s /usr/bin/bash -g docker -m docker && usermod --password \$(echo docker | openssl passwd -1 -stdin) docker ) "	

	asRoot "test -d /home/docker || mkdir /home/docker && cp -rT /etc/skel /home/docker && chown -R docker:docker /home/docker"
	asRoot "usermod -aG docker docker";
	asRoot "usermod -aG sudo docker";
}

function installDockerPackagesAndConfigure(){

	asRoot "apt --yes update";
	asRoot "apt --yes upgrade";
	asRoot "apt --yes remove docker.io docker-compose";
	asRoot "apt --yes auto-remove";
	asRoot "apt --yes install docker.io docker-compose jo";

	terminateDistro;

	asRoot "groupmod -g 36257 docker";

	DOCKER_DIR="/mnt/wsl/shared-docker";
	RUN_SCRIPT=$(printf "mkdir -pm o=,ug=rwx $DOCKER_DIR;\nsudo chgrp docker $DOCKER_DIR;\nnohup sudo dockerd > /dev/null 2>&1 &\ndisown\nsleep 5\n");

	asRoot "mkdir -pm o=,ug=rwx $DOCKER_DIR";
	asRoot "chgrp docker $DOCKER_DIR";
	asRoot "test -d /etc/docker || mkdir /etc/docker";

	asRoot "jo -p hosts=\$(jo  -a \"unix:///mnt/wsl/shared-docker/docker.sock\") iptables=false > /etc/docker/daemon.json";

	asRoot "echo 'docker ALL=(ALL:ALL) NOPASSWD: /usr/bin/dockerd, /usr/bin/chgrp, /usr/bin/killall dockerd' | sudo EDITOR='tee -a' visudo"
	asDocker "echo \"$RUN_SCRIPT\" > ~/startDockerd.sh";
	asDocker "chmod u+x ~/startDockerd.sh";

}

function installPowerShellFunctions(){
	find ~/ -type d -name 'Documents' -exec bash -c '
	test -d "$0/WindowsPowerShell" || mkdir "$0/WindowsPowerShell";
	test -f "$0/WindowsPowerShell/Microsoft.PowerShell_profile.ps1" || touch "$0/WindowsPowerShell/Microsoft.PowerShell_profile.ps1";
	grep -q "function docker" "$0/WindowsPowerShell/Microsoft.PowerShell_profile.ps1" || cat powershell_aliases >> "$0/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
	' \{\} \; 2>/dev/null;
}

function installBashAliases(){
	grep -q 'alias docker=' ~/.bashrc || cat bash_aliases >> ~/.bashrc
}

