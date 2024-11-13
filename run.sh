#/usr/bin/env bash
set -e
trap 'exit 0' ERR
export CLIENTNAME="vpn"

mkdir ./vpn
mkdir ./vpn/data
cd ./vpn
cat >>docker-compose.yml <<EOF
services:
  ovpn:
    image: kylemanna/openvpn
    volumes:
      - ./data:/etc/openvpn
    ports:
        - 6000:1194/udp
    cap_add:
      - NET_ADMIN
    restart: always

  frpc:
    restart: always
    network_mode: host
    volumes:
      - ./frpc.toml:/etc/frp/frpc.toml
      - ./$CLIENTNAME.ovpn:/etc/frp/client.ovpn
    container_name: frpc
    image: snowdreamtech/frpc:alpine
EOF

cat >>input.txt <<EOF



EOF

cat >>frpc.toml <<EOF
auth.token = "12345678"
serverAddr = "sub.jeff3.win"
serverPort = 7000

[[proxies]]
name = "vpn"
type = "udp"
localIP = "127.0.0.1"
localPort = 6000
remotePort = 6000

[[proxies]]
name = "dot_ovpn"
type = "tcp"
remotePort = 8888
[proxies.plugin]
type = "static_file"
localPath = "/etc/frp"

EOF


docker compose run --rm ovpn ovpn_genconfig -u udp://10.1.4.220:6000
cat input.txt | docker compose run -T --rm ovpn ovpn_initpki nopass
docker compose run --rm ovpn easyrsa build-client-full "$CLIENTNAME" nopass
docker compose run --rm ovpn ovpn_getclient "$CLIENTNAME" > "$CLIENTNAME.ovpn"
