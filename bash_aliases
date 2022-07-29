
#####################
# docker using WSL2 #
#####################
alias docker='wsl -d Ubuntu-20.04 docker -H unix:///mnt/wsl/shared-docker/docker.sock'
alias docker-compose='wsl -d Ubuntu-20.04 docker-compose -H unix:///mnt/wsl/shared-docker/docker.sock'
alias start-dockerd='echo "~/startDockerd.sh" | wsl -d Ubuntu-20.04 --user docker '
alias stop-dockerd='echo "killall dockerd" | wsl -d Ubuntu-20.04 --user docker'
