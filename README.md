# Demo mySQL setup

## Starting the VMs

If you already have a mySQL running in your computer, please, stop it since we will use our local 3306 and 3307 ports.

```
vagrant up
```

This will create two VMs. One called db-1 with the ip 192.168.1.10 and db-2 with the ip 192.168.1.11

We can connect to db-1 with

```
vagrant ssh db-1
```

And of course to db-2 with

```
vagrant ssh db-2
```

## Installing Percona mySQL

This procedure should be followed for both machines

Add the Percona repository

```
sudo add-apt-repository "deb http://repo.percona.com/apt trusty testing"
sudo add-apt-repository "deb-src http://repo.percona.com/apt trusty testing"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C4CBDCDCD2EFD2A
```

Install Percona mySQL

```
sudo apt-get update
sudo apt-get install percona-server-server-5.5
sudo apt-get install percona-xtrabackup
```

Check that Percona mySQL is running

```
sudo service mysql status
```

You can stop it with

```
sudo service mysql stop
```

and start it with

```
sudo service mysql start
```

You can take a look to the default config files at

```
/etc/mysql/my.cnf
```

Since we want to be able to be connected from all the network interfaces we can set the bind_address to 0.0.0.0

```
bind-address            = 0.0.0.0
```

After changing this you will need to restart mysql as we did before.

If you try to connect now from the host you will get a message saying that you are not allowed to connect from your host.

Let's connect from the VM.

```
mysql -u root
```

And show the users and privileges

```
select host, user from mysql.user;
```

We can grant to root all privileges from anywhere

```
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
```

Now you should be able to connect from the outside.

To be able to replicate data we need to enable binlogs in mySQL. You can do it adding the following lines to my.cnf

```
log-bin                        = /var/lib/mysql/mysql-bin
expire-logs-days               = 14
sync-binlog                    = 1
```

# Seeding the data

You can find included some ruby scripts to seed the database at db-1 with some sample data. We only need to seed db-1.

```
ruby seed-db-1.rb
```

This will create a database called my_store and some random customers into it.


# Backing up the master machine

The master will be db-1. We will do first a backup of the machine. We will use Percona xtrabackup.

First we will install it.

```
sudo apt-get install percona-xtrabackup
```

In the Vagrantfile we have set up a shared folder at /opt/shared. We will use that folder in both machines.

We can run a backup with

```
sudo innobackupex --user=root /opt/shared/
sudo innobackupex --user=root --apply-log /opt/shared/<backup folder>/
```

Then in /opt/shared we will have a folder with the current date as name. It will contain a backup of out db.


# Import the backup in the slave

First we need to stop mysql in db-2

```
sudo service mysql stop
```

We can check in /etc/mysql/my.cnf where mysql data is stored

```
datadir         = /var/lib/mysql
```

Then we copy all the backup files to that location.

```
sudo rm -rf /var/lib/mysql
sudo cp -r /opt/shared/<your backup> /var/lib/mysql
sudo chown -R mysql:mysql /var/lib/mysql
```

Since we are using a debian based distro for the VMs (Ubuntu) we need to update one more file. Take the password for the debian-sys-maint user from /etc/mysql/debian.cnf in db-1 and copy it to /etc/mysql/debian.cnf in db-2

We can start back mySQL

```
sudo service mysql start
```

TODO: At this moment I had to remove both ib_logfile in the slave machine since mySQL is complining about their size to start. Is there a cleanest solution?

## Configure the replication

### On master

We need to set the server-id in my.cnf. Uncomment the following line in the config file.

```
server-id               = 1
```

To apply the changes you will need to restart mySQL.

```
sudo service mysql restart
```

Check that you can connect to the slave

```
mysql -h 192.168.1.11 -u root
```

If everything is correct exit that console and connect to the local DB.

```
mysql -u root
```

Just run the following SQL

```
GRANT REPLICATION SLAVE ON *.*  TO 'root'@'192.168.1.11';
```

### On slave

In the slave (db-2) just change the following in my.cnf

```
server-id=2
```

Restart the db.

Check the binlog position in the slave

```
sudo cat /var/lib/mysql/xtrabackup_binlog_info
```

It should be something like

```
mysql-bin.000001        389124
```

Connect to db-2's mySQL console and configure db-1 as master

```
CHANGE MASTER TO
  MASTER_HOST='192.168.1.10',
  MASTER_USER='root',
  MASTER_LOG_FILE='<binlog file>',
  MASTER_LOG_POS=<binlog position>;
```

The binlog file and the binlog position are the ones obtained by reading xtrabackup_binlog_info so, for the exmaple before the values should be:

```
CHANGE MASTER TO
  MASTER_HOST='192.168.1.10',
  MASTER_USER='root',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=389124;
```

And finally start the slave from mySQL console.

```
START SLAVE;
```

We can check the status of the slave with

```
SHOW SLAVE STATUS \G
```
