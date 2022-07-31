#!/bin/bash

DISTRO="Ubuntu-20.04";
source proxySettings.sh;
source duw_functions.sh;

# wsl produces UTF-16LE ouput for some reason, convert before grepping
! wsl -l | iconv -f UTF-16LE -t UTF-8 | grep -q "$DISTRO" && installDistro || printf "$DISTRO already installed, continueing to configuration.\n\nPress <enter> to continue.\n\n";
read -p ""

addDockerUserAndConfigure;

if [[ "$USE_PROXY_APT" == "yes" ]]; then
     setAptProxySettings;
fi

if [[ "$USE_PROXY_DOCKER" == "yes" ]]; then
     setDockerProxySettings;
fi

installDockerPackagesAndConfigure

echo "installing shell aliases, this can take some time, please wait."
installPowerShellFunctions
installBashAliases

cat finishedScreen


