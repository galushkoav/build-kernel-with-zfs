#https://forum.level1techs.com/t/building-custom-kernel-with-zfs-built-in/117464
#!/bin/bash
CPU_COUNT="4"
KERNEL_VERSION="4.14.8"
BUILD_DIR="/build-kernel"
LINUX_DIR="$BUILD_DIR/linux-$KERNEL_VERSION"
echo "Устанавливаем зависимости"
apt install parted lsscsi ksh zlib1g-dev uuid-dev libattr1-dev libblkid-dev libselinux1-dev libudev-dev libdevmapper-dev  git build-essential kernel-package fakeroot libncurses5-dev libssl-dev ccache build-essential autoconf libtool  gcc make bc fakeroot dpkg-dev  libncurses5-dev libssl-dev gawk alien fakeroot linux-headers-$(uname -r) -y

echo "Создаем директорию для сборки"
mkdir -p $BUILD_DIR
cd $BUILD_DIR
echo "Проверяем если ли скачанное ядро"
if [ ! -d "$LINUX_DIR" ];
then
echo "Скачиваем ядро"
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.xz
tar -xvf linux-$KERNEL_VERSION.tar.xz
fi

cd $LINUX_DIR
echo "Скачиваем и распаковываем патч"
if [ ! -f "$patch-$KERNEL_VERSION.xz" ]; then
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/patch-$KERNEL_VERSION.xz
unxz patch-$KERNEL_VERSION.xz
fi

echo "Копируем config_kernel"
cp $BUILD_DIR/config_kernel $LINUX_DIR/
echo "Запускаем make prepare scripts"
cd $LINUX_DIR
make prepare scripts

Клонируем репозитории для установки поддержки zfs
cd $BUILD_DIR


if [ ! -d "$BUILD_DIR/spl" ]; then
git clone https://github.com/zfsonlinux/spl $BUILD_DIR/spl
fi
if [ ! -d "$BUILD_DIR/zfs" ]; then
git clone https://github.com/zfsonlinux/zfs $BUILD_DIR/zfs
fi

echo "Собраем и устанавливаем spl для zfs"
cd $BUILD_DIR/spl
git checkout master
sh autogen.sh
./configure --prefix=/ --libdir=/lib --includedir=/usr/include --datarootdir=/usr/share --enable-linux-builtin=yes --with-linux=$LINUX_DIR --with-linux-obj=$LINUX_DIR
./copy-builtin $LINUX_DIR
make
make install

echo "Собраем и устанавливаем zfs"
cd $BUILD_DIR/zfs
git checkout master
sh autogen.sh
./configure --prefix=/ --libdir=/lib --includedir=/usr/include --datarootdir=/usr/share --enable-linux-builtin=yes --with-linux=$LINUX_DIR --with-linux-obj=$LINUX_DIR --with-spl=$BUILD_DIR/spl --with-spl-obj=$BUILD_DIR/spl
./copy-builtin $LINUX_DIR
make
make install
echo "Установка zfs завершена"


echo "Собираем ядро"
cp $BUILD_DIR/config_kernel $LINUX_DIR/
echo "Приминяем патчи"
cd $LINUX_DIR
#patch patch-$KERNEL_VERSION -p1 --dry-run
#patch patch-$KERNEL_VERSION -p1
touch REPORTING-BUGS;
echo "Очищаем"
make clean 
echo "Собираем deb пакет"
make -j$CPU_COUNT deb-pkg LOCALVERSION=$KERNEL_VERSION
echo "Сборка пакета завершена - осталось установить"
#curl -L https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh | CONFIG=config_kernel /bin/bash






###kube req
#CONFIG_IP_NF_TARGET_MASQUERADE=y
#CONFIG_IP_NF_NAT=y
#CONFIG_DEVPTS_MULTIPLE_INSTANCES=y
#CONFIG_CGROUP_PIDS=y
#CONFIG_MEMCG_SWAP_ENABLED=y
#CONFIG_MEMCG_KMEM=y
#CONFIG_CFS_BANDWIDTH=y
#CONFIG_RT_GROUP_SCHED=y
#CONFIG_RESOURCE_COUNTERS=y
#CONFIG_IPVLAN=y
#CONFIG_OVERLAY_FS=y
#CONFIG_CGROUP_HUGETLB=y
#CONFIG_AUFS_FS=y
#CONFIG_EXT3_FS_XATTR=y
#CONFIG_EXT3_FS_POSIX_ACL=y
#CONFIG_EXT3_FS_SECURITY=y



#wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.14.8.tar.xz
