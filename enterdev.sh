#!/bin/bash
set -o errexit -o noclobber -o nounset

opts="$(getopt -o n:i:d -l name:,image:,detach --name "$0" -- "$@")"
eval set -- "$opts"

NAME="dev"
IMAGE="ubuntu:bionic"
DETACH=false
while true
do
  case "$1" in
    -n|--name)
      NAME=$2
      shift 2
      ;;
    -i|--image)
      IMAGE=$2
      shift 2
      ;;
    -d|--detach)
      DETACH=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
  esac
done

USER=$(whoami)

ETC_MOUNT_FLAGS=""
for f in "group" "gshadow" "inputrc" "localtime" "passwd" "shadow" "subgid" "subuid" "sudoers"; do
  ETC_MOUNT_FLAGS="${ETC_MOUNT_FLAGS} -v /etc/$f:/etc/$f:ro"
done

USER_FLAGS="-u $(id -u):$(id -g) -v /home/$USER:/home/$USER -w /home/$USER"
for grp in $(id -G); do USER_FLAGS="$USER_FLAGS --group-add $grp"; done

SUDO_FLAGS="-v /usr/bin/sudo:/usr/bin/sudo:ro -v /usr/lib/sudo:/usr/lib/sudo:ro"
NET_FLAGS="--network host --add-host ${NAME}:127.0.0.1"
IPC_FLAGS="--ipc host --pid host"
X11_FLAGS=""
if [ "${DISPLAY:-}" ]; then
  X11_FLAGS="-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=${DISPLAY}"
fi
NVIDIA_FLAGS=""
if [[ $(docker run --rm --runtime=nvidia ${IMAGE} bash -c "exit 0" 2>/dev/null ; echo $? ) == 0 ]]; then
  NVIDIA_FLAGS="--runtime=nvidia"
elif [[ $(docker run --rm --gpus=all ${IMAGE} bash -c "exit 0" 2>/dev/null ; echo $? ) == 0 ]]; then
  NVIDIA_FLAGS="--gpus=all"
fi
DOCKER_FLAGS="-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker"

if [ ! $(docker ps -q -f name="^${NAME}$") ]; then
  docker run --rm -it -d --privileged \
    --name $NAME \
    -h $NAME \
    $USER_FLAGS \
    $ETC_MOUNT_FLAGS \
    $SUDO_FLAGS \
    $NET_FLAGS \
    $IPC_FLAGS \
    $X11_FLAGS \
    $NVIDIA_FLAGS \
    $DOCKER_FLAGS \
    $@ \
    $IMAGE bash
fi

if [ "$DETACH" = false ]; then
  docker exec -it -w "${PWD}" $NAME bash
fi
