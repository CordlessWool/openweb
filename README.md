# openweb

This script is written to easily setup a tor or torsnowflake node on a raspberry pi

## How to

This guide is focusing on a Raspberry Pi with Raspian OS/Debian
Setup a SD-Card with the [Rasperry Pi Imager](https://www.raspberrypi.com/software/) or you tool of joice. You will find more Information to setup the Image on the RaspberryPi Page [here](https://www.raspberrypi.com/documentation/computers/getting-started.html)

Connect to the commandline via ssh and install git
```sh
sudo apt-get install git
```

Load this git repository and navigate to it
```sh
git clone https://github.com/CordlessWool/openweb.git
cd openweb
```

From here on you can use the openweb bash command to install and control the systems
```sh
#Start easy and use a automatic Setup, this will also set a cronjob to start snowflake after a restart
./openweb snowflake auto

#To start a unrestricted snowflake server you have to open some ports (more informatin see below)
#To tell snowflake which range it can use and opened in the firewall (if you ran it at home you have to configure you router)
./openweb snowflake auto -ephemeral-ports-range 60100:60300

#A Report and how the server is connected is saved in the log, the log will be overwriten afert restart
./openweb snowflake log

#Log is useing tail to output the logs so you can also follow them
./openweb snowflake log -n 100 -f

#To update snowflake you can easily run
./openweb snowflake update
./openweb snowflake restart

#To update this repository you have to use git
git pull
```

## Snowflake

You will find more information to the tor snowflake proxy [here](https://snowflake.torproject.org/)

### Restricted vs Unrestricted
If your server is behind a firewall (usally you router should have one) the tor snowflake proxy will run in a restricted mode. It is more complicate to use your proxy and the amount of connection will be much lower then with a unrestricted on, but you do not have to open some ports in you firewall, to it is more secure for you. If you will feel save to open some port, do it, but keep in mind to update you OS frequently to get secruity fixes fast. 
