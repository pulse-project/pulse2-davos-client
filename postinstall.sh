mkdir /var/lib/pulse2/clients/imaging
pushd /var/lib/pulse2/clients/imaging
mkdir -p ./root/.ssh/
chmod 700 ./root/.ssh/
cp /root/.ssh/id_rsa.pub ./root/.ssh/authorized_keys
mkdir -p ./home/pulse/.ssh/
chmod 700 ./home/pulse/.ssh/
cp /root/.ssh/id_rsa.pub ./home/pulse/.ssh/authorized_keys
chown -R 1000:1000 ./home/pulse/
find . -print | cpio -o -H newc | gzip -9 > /var/lib/pulse2/imaging/davos/rootfs-custom.gz
popd
