# Dockerized Yggdrasil Network Router with RADVD
## Why this exists?
To provide Yggdrasil Network capabilities to hardware that cannot natively run Yggdrasil Network software. For example, MikroTik routers.
## Prerequisites
- MikroTik arm64 router with at least 80 MB of free disk space.
- Raspberry Pi 4 or any `arm64` host for building the container.
## Brief instructions for MikroTik
- On your computer, generate Yggdrasil Network config that will be used for the dockerized router.
```
yggdrasil -genconf -json > /tmp/yggdrasil.conf
```
- Fetch your private key, this will be YGGDRASIL_PRIVATE_KEY in MikroTik Container -> Envs.
```
cat /tmp/yggdrasil.conf | jq -M .PrivateKey | tr -d '"'
```
- Calculate your main Yggdrasil IP from that config. In this example the IP will be `202:5b95:731b:5f11:314e:1202:99db:d619`.
```
yggdrasil -useconffile /etc/yggdrasil.conf -address
```
- Calculate your Yggdrasil subnet from the config. Example subnet is `302:5b95:731b:5f11::/64`.
```
yggdrasil -useconffile /etc/yggdrasil.conf -subnet
```

- Setup a bridge with working network using official [MikroTik guide](https://help.mikrotik.com/docs/spaces/ROS/pages/84901929/Container). In this example, bridge address will be 10.1.90.1/24.
- Setup a VETH. Note that VETH is assigned `302:5b95:731b:5f11::2` from Yggdrasil subnet and main Yggdrasil IP is used as the container's default IPv6 gateway.
```
/interface veth add name="veth1_yggdrasil" address=10.1.90.2/24,302:5b95:731b:5f11::2/64 gateway=10.1.90.1 gateway6=202:5b95:731b:5f11:314e:1202:99db:d619
```
- Assign this VETH to a containers bridge.
- IPv6 -> Settings -> Accept Router Advertisements -> yes
- Clone and build the container on `arm64` host, for example, Raspberry Pi 4.
```
git clone https://github.com/gemtoo/ggspot.git
cd ggspot
docker build -t ggspot .
docker save ggspot > ggspot.tar
```
- SFTP into MikroTik and put `ggspot.tar` there.
- Create a container using this archive. Assign VETH from the previous step. In Envs specify YGGDRASIL_PRIVATE_KEY and YGGDRASIL_PEERS (example is in `.env.example`).