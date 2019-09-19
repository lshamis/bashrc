set -o errexit -o noclobber -o nounset -o pipefail

opts="$(getopt -o n:i: -l name:,image:,nvidia --name "$0" -- "$@")"
eval set -- "$opts"

NAME="dev"
IMAGE="ubuntu:bionic"
RUNTIME=""
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
    --nvidia)
      RUNTIME="--runtime=nvidia"
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
X11_FLAGS="-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=${DISPLAY}"

if [ $(docker ps -q -f name="^${NAME}$") ]; then
  docker exec -it $NAME bash
else
  docker run --rm -it --privileged \
    --name $NAME \
    -h $NAME \
    $RUNTIME \
    $USER_FLAGS \
    $ETC_MOUNT_FLAGS \
    $SUDO_FLAGS \
    $NET_FLAGS \
    $X11_FLAGS \
    $@ \
    $IMAGE bash
fi

