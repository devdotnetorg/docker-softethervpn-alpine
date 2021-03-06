# A simple<sup>*</sup> [SoftEther VPN][1] server Docker image

<sup>*</sup> "Simple" as in no configuration parameter is needed for a single-user SecureNAT setup.

Based on repo: [GitHub /siomiz/SoftEtherVPN](https://github.com/siomiz/SoftEtherVPN "GitHub /siomiz/SoftEtherVPN")

## Image Tags ##

### Linux amd64 Tags ###

Tags  | Dockerfile  | OS Version  |  SoftEther
------------- | --  | --  | --
`:latest` `:4.34` | [Dockerfile](https://github.com/devdotnetorg/docker-softethervpn-alpine/blob/master/Dockerfile.alpine) | `alpine:3.12` | Latest Stable ([v4.34-9745-beta](https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/tree/v4.34-9745-beta))

### Linux arm64 Tags ###

Tags  | Dockerfile  | OS Version  |  SoftEther
------------- | --  | --  | --
`:aarch64` `:5.01.9674-aarch64` | [Dockerfile](https://github.com/devdotnetorg/docker-softethervpn-alpine/blob/master/Dockerfile.aarch64) | `alpine:3.12` | Latest ([v5.01.9674](https://github.com/SoftEtherVPN/SoftEtherVPN/tree/5.01.9674))

### Coming soon Linux arm32 Tags ###

Tags  | Dockerfile  | OS Version  |  SoftEther
------------- | --  | --  | --
`:latest` `:armhf` `:5.01.9674-armhf` | [Dockerfile](https://github.com/devdotnetorg/docker-softethervpn-alpine/blob/master/Dockerfile.armhf) | `alpine:3.12` | Latest ([v5.01.9674](https://github.com/SoftEtherVPN/SoftEtherVPN/tree/5.01.9674))

## Setup
 - L2TP/IPSec PSK + OpenVPN
 - SecureNAT enabled
 - Perfect Forward Secrecy (DHE-RSA-AES256-SHA)
 - make'd from [the official SoftEther VPN GitHub Stable Edition Repository][2].

`docker run -d --cap-add NET_ADMIN -p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp -p 1194:1194/udp -p 5555:5555/tcp devdotnetorg/softethervpn-alpine`

Connectivity tested on Android + iOS devices. It seems Android devices do not require L2TP server to have port 1701/tcp open.

The above example will accept connections from both L2TP/IPSec and OpenVPN clients at the same time.

Mix and match published ports: 
- `-p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp` for L2TP/IPSec
- `-p 1194:1194/udp` for OpenVPN.
- `-p 443:443/tcp` for OpenVPN over HTTPS.
- `-p 5555:5555/tcp` for SoftEther VPN (recommended by vendor).
- `-p 992:992/tcp` is also available as alternative.

Any protocol supported by SoftEther VPN server is accepted at any open/published port (if VPN client allows non-default ports).

## Credentials

All optional:

- `-e PSK`: Pre-Shared Key (PSK), if not set: "notasecret" (without quotes) by default.
- `-e USERS`: Multiple usernames and passwords may be set with the following pattern: `username:password;user2:pass2;user3:pass3`. Username and passwords are separated by `:`. Each pair of `username:password` should be separated by `;`. If not set a single user account with a random username ("user[nnnn]") and a random weak password is created.
- `-e SPW`: Server management password. :warning:
- `-e HPW`: "DEFAULT" hub management password. :warning:

Single-user mode (usage of `-e USERNAME` and `-e PASSWORD`) is still supported.

See the docker log for username and password (unless `-e USERS` is set), which *would look like*:

    # ========================
    # user6301
    # 2329.2890.3101.2451.9875
    # ========================
Dots (.) are part of the password. Password will not be logged if specified via `-e USERS`; use `docker inspect` in case you need to see it.

:warning: if not set a random password will be set but not displayed nor logged. If specifying read the notice below.

## Configurations ##

The vpn_server.config configuration file has been moved from the binaries folder to the `/usr/vpnserver/config` subfolder for mounting.
For the container to work, you need to create a file `vpn_server.config`, for this, start the container and specify the initial password for the server and the default hub:
```
$ docker run --name vpnconf -e SPW=<serverpw> -e HPW=<hubpw> -v softethervpn-config:/usr/vpnserver/config devdotnetorg/softethervpn-alpine echo
$ docker rm vpnconf
```
The `vpn_server.config` file will be located at VOLUME:` softethervpn-config`.
Now start the main container:
```
$ docker run ... -v softethervpn-config:/usr/vpnserver/config devdotnetorg/softethervpn-alpine
```
Refer to [SoftEther VPN Server Administration manual](https://www.softether.org/4-docs/1-manual/3._SoftEther_VPN_Server_Manual/3.3_VPN_Server_Administration) for more information.

## Logging ##

By default SoftEther has a very verbose logging system. For privacy or space constraints, this may not be desirable. The easiest way to solve this create a dummy volume to log to /dev/null. In your docker run you can use the following volume variables to remove logs entirely.
```
-v /dev/null:/usr/vpnserver/server_log \
-v /dev/null:/usr/vpnserver/packet_log \
-v /dev/null:/usr/vpnserver/security_log
```
If logs are needed, then logs will accumulate over time. Added cron job for regular cleaning of logs. The cron job runs every 15 minutes. The environment `LIFETIMELOGS` controls the lifetime of the logs in hours.
- (default) If `-e LIFETIMELOGS=0`, then the cron job does not start.
- if `-e LIFETIMELOGS=2`, logs older than 2 hours will be deleted. But you need to remember that a new log file is created at 00:00 every day and recorded until 23:59:59, name: vpn_20201104.log, vpn_20201105.log, etc. Thus, the vpn_20201104.log file will be deleted on 05 November 2020, at 02: 00-02: 15 minutes. There will be daily accumulation of information, if you have not switched to the hourly mode of creating log files.

Example: `docker run -d --cap-add NET_ADMIN -p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp -p 1194:1194/udp -p 5555:5555/tcp -e LIFETIMELOGS=2 devdotnetorg/softethervpn-alpine`

YAML:
```
#VPN
  softethervpn:
    image: devdotnetorg/softethervpn-alpine
    container_name: softethervpn_local
    restart: always
    ports:
      - 992:992/tcp
      - 1194:1194/udp
      - 5555:5555/tcp
      - 53:53/udp     
      - 1195:1195/udp      
    environment:
      - LIFETIMELOGS=2
    volumes:
      - softethervpn-config:/usr/vpnserver/config
      - softethervpn-logs-server:/usr/vpnserver/server_log      
      - softethervpn-logs-packet:/usr/vpnserver/packet_log
      - softethervpn-logs-security:/usr/vpnserver/security_log      
    cap_add:
      - NET_ADMIN    
```

## Server & Hub Management Commands ##

Management commands can be executed just before the server & hub admin passwords are set via:
- `-e VPNCMD_SERVER`: `;`-separated [Server management commands](https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.3_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Entire_Server)).
- `-e VPNCMD_HUB`: `;`-separated [Hub management commands](https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.4_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Virtual_Hub)) (currently only for `DEFAULT` hub).

Example: Set MTU via [`NatSet`](https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.4_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Virtual_Hub)#6.4.97_.22NatSet.22:_Change_Virtual_NAT_Function_Setting_of_SecureNAT_Function) Hub management command:
`-e VPNCMD_HUB='NatSet /MTU:1500'`

Note that commands run only if the config file is not mounted. Some commands (like `ServerPasswordSet`) will cause problems.

## OpenVPN ##

`docker run -d --cap-add NET_ADMIN -p 1194:1194/udp devdotnetorg/softethervpn-alpine`

The entire log can be saved and used as an `.ovpn` config file (change as needed).

Server CA certificate will be created automatically at runtime if it's not set. You can supply _a self-signed 1024-bit RSA certificate/key pair_ created locally OR use the `gencert` script described below. Feed the keypair contents via `-e CERT` and `-e KEY` ([use of `--env-file`][3] is recommended). X.509 markers (like `-----BEGIN CERTIFICATE-----`) and any non-BASE64 character (incl. newline) can be omitted and will be ignored.

Examples (assuming bash; note the double-quotes `"` and backticks `` ` ``):

* ``-e CERT="`cat server.crt`" -e KEY="`cat server.key`"``
* `-e CERT="MIIDp..b9xA=" -e KEY="MIIEv..x/A=="`
* `--env-file /path/to/envlist`

`env-file` template can be generated by:

`docker run --rm devdotnetorg/softethervpn-alpine gencert > /path/to/envlist`

The output will have `CERT` and `KEY` already filled in. Modify `PSK`/`USERS`.

Certificate volumes support (like `-v` or `--volumes-from`) will be added at some point...

## Assembly for ARM devices ##

The assembly for the aarch64 architecture (ARM64v8) was done on the [Banana Pi BPI-M64](http://wiki.banana-pi.org/Banana_Pi_BPI-M64) evaluation board.

The assembly for the armhf architecture (ARM32v7) was done on the [Cubietruck](https://habr.com/ru/post/186576/) evaluation board.

SoftEther VPN was compiled with musl option: `export USE_MUSL=YES`. [Build on musl-based linux](https://github.com/SoftEtherVPN/SoftEtherVPN/blob/master/src/BUILD_UNIX.md#build-on-musl-based-linux).

## License ##

[MIT License][4].

  [1]: https://www.softether.org/
  [2]: https://github.com/SoftEtherVPN/SoftEtherVPN_Stable
  [3]: https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables-e-env-env-file
  [4]: https://github.com/devdotnetorg/docker-softethervpn-alpine/raw/master/LICENSE