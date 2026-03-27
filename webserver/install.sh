#!/usr/bin/bash
set -x

### Get directory where this script is installed
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Append to release file
echo WEBCONTROLLER_VERSION=\"$(cd $BASEDIR; ~/mini_pupper_bsp/get-version.sh)\" >> ~/mini-pupper-release

source  ~/mini-pupper-release
source /etc/os-release

PIP_BREAK=""
if [ "$UBUNTU_CODENAME" == "noble" ]
then
    PIP_BREAK="--break-system-packages"
fi

sudo rm -rf /usr/lib/python3/dist-packages/blinker*
sudo apt-get install -y python3-pip
if [ "$IS_RELEASE" == "YES" ]
then
    cd $BASEDIR
    TAG_COMMIT=$(git rev-list --abbrev-commit --tags --max-count=1)
    TAG=$(git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true)
    if [ "v$WEBCONTROLLER_VERSION" != "$TAG" ]
    then
        sed -i "s/IS_RELEASE=YES/IS_RELEASE=NO/" ~/mini-pupper-release
    fi
    VERSION=$(cd $BASEDIR; ~/mini_pupper_bsp/get-version.sh)
    sudo PBR_VERSION=$VERSION python3 -m pip install $PIP_BREAK $BASEDIR/backend
    sudo PBR_VERSION=$VERSION python3 -m pip install $PIP_BREAK $BASEDIR/../joystick_sim
else
    sudo python3 -m pip install $PIP_BREAK $BASEDIR/backend
    sudo python3 -m pip install $PIP_BREAK $BASEDIR/../joystick_sim
fi

if ! python3 -c "import UDPComms" >/dev/null 2>&1; then
    sudo python3 -m pip install $PIP_BREAK git+https://github.com/stanfordroboticsclub/UDPComms.git
fi

sudo ln -sf $BASEDIR/web-controller.service /etc/systemd/system/web-controller.service
sudo systemctl daemon-reload
sudo systemctl enable web-controller
sudo systemctl start web-controller
