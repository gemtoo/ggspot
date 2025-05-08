# Dockerized Yggdrasil Network Router with RADVD
## Why this exists?
To provide Yggdrasil Network capabilities to hardware that cannot natively run Yggdrasil Network software. For example, MikroTik routers.
## Prerequisites
- MikroTik arm64 router with at least 100 MB of free disk space.
- Raspberry Pi 4 or any `arm64` host for building the container.
## Brief instructions for MikroTik
- On your computer, generate Yggdrasil Network config that will be used for the dockerized router.
```
yggdrasil -genconf -json > /tmp/yggdrasil.conf
```
- Fetch your private key, this will be the `YGGDRASIL_PRIVATE_KEY` in MikroTik Container -> Envs.
```
cat /tmp/yggdrasil.conf | jq -M .PrivateKey | tr -d '"'
```
- Calculate your main Yggdrasil IP from that config. In this example the IP will be `202:5b95:731b:5f11:314e:1202:99db:d619`.
```
yggdrasil -useconffile /tmp/yggdrasil.conf -address
```
- Calculate your Yggdrasil subnet from the config. Example subnet is `302:5b95:731b:5f11::/64`.
```
yggdrasil -useconffile /tmp/yggdrasil.conf -subnet
```

- Setup a bridge with working network using official [MikroTik guide](https://help.mikrotik.com/docs/spaces/ROS/pages/84901929/Container). In this example, bridge name is `Bridge_Containers` address will be `10.1.90.1/24`.
- Setup a VETH. Note that VETH is assigned `302:5b95:731b:5f11::2` from Yggdrasil subnet and main Yggdrasil IP is used as the container's default IPv6 gateway.
```
/interface veth add name="veth1_yggdrasil" address=10.1.90.2/24,302:5b95:731b:5f11::2/64 gateway=10.1.90.1 gateway6=202:5b95:731b:5f11:314e:1202:99db:d619
```
- Assign this VETH to a containers bridge.
- Configure a static route to `200::/7` (Yggdrasil Network address space). The correct syntax matters here.
```
/ipv6 route add dst-address=200::/7 gateway=302:5b95:731b:5f11::2%Bridge_Containers
```
- IPv6 -> Settings -> Accept Router Advertisements -> yes
- Clone and build the container on `arm64` host, for example, Raspberry Pi 4.
```
git clone https://github.com/gemtoo/ggspot.git
cd ggspot
docker build -t ggspot .
docker save ggspot > ggspot.tar
```
- SFTP into MikroTik and put `ggspot.tar` there.
- Create a container using this archive. Assign VETH from the previous step. In Envs specify `YGGDRASIL_PRIVATE_KEY` and `YGGDRASIL_PEERS` (example is in `.env.example`).
## Notes
- In this example, inside the container the router software brings up a `tun0` interface with the main address `202:5b95:731b:5f11:314e:1202:99db:d619`, subnet `302:5b95:731b:5f11::/64` and a route to `200::/7`, a.k.a. Yggdrasil Network. The main address is going to be the default gateway to Yggdrasil, inside the container.
- VETH is the `eth0` of a container. Per official [Yggdrasil documentation](https://yggdrasil-network.github.io/configuration.html#advertising-a-prefix), for router advertisements to work, VETH should have its own Yggdrasil address (`302:5b95:731b:5f11::2/64` in this case). Assigning Yggdrasil address to VETH makes Yggdrasil reachable from VETH. But such address is reachable only from within the container. This is why Router Advertisement Daemon is needed inside the container.
- Accepting Router Advertisements is crucial, because there is no other way to get an Yggdrasil Network address on the interface outside the container. When the RA happens, Yggdrasil address gets auto-configured with SLAAC on the `Bridge_Containers` interface. This is the point where MikroTik gets it's own Yggdrasil address. This is the point where container's Yggdrasil Network is made available externally.
- To reach Yggdrasil Network hosts from MikroTik, a static route to `200::/7` needs to be configured. In our case `200::/7 via 302:5b95:731b:5f11::2%Bridge_Containers`. VETH address inside the container is used as the default gateway. The gateway scope `%Bridge_Containers` needs to be explicitly specified in the route definition.
- The `s6-overlay` init inside the container runs `apk upgrade --no-cache` every time the container boots. Therefore, to update software inside the container, only a restart is required.
