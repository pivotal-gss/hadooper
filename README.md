# hadooper
**Bash Centos Hadoop Install Script**

# Details #
* Run as root ( or sudo )
* Add Standalone Hadoop to your existing environment with one command: `./hadooper.sh`
* Can be easily integrated with an virtualization project by adding the command to the runtime execution (piv-go-gpdb, spark-cluster,...). 

# Usage #
* Run `./hadooper.sh`

With any luck, you'll get output similar to this...

```
================================================================================
Install script for Hadoop 2.7 on CentOS 7/x86_64
================================================================================
Installing Packages...[√]
Configuring Passwordless SSH...[√]
Download & Extract Hadoop [/usr/local]...[√]
Configuration:
	 Verify Hosts File: /etc/hosts [√]
	 Symlink Hadoop: /usr/local/hadoop [√]
	 Environment Variables: /etc/profile.d/hadoop-profile.sh [√]
	 Create Data Directories: /data/hdfs/namenode /data/hdfs/datanode [√]
	 Hadoop Variables: /etc/hadoop/core-site.xml [√]
	 Hadoop Variables: /etc/hadoop/hdfs-site.xml [√]
	 Hadoop Variables: /etc/hadoop/mapred-site.xml [√]
	 Hadoop Variables: /etc/hadoop/yarn-site.xml [√]
	 Hadoop Variables: /etc/hadoop/hadoop-env.sh [√]
	 Hadoop Daemons: /etc/hadoop/hadoop-service.sh [√]
Sourcing Variables...[√]
Formatting HDFS Namenode...[√]
Starting Services...[√]

========================================
Service Status:
========================================
Redirecting to /bin/systemctl status dfs.service
● dfs.service - Hadoop Service Controller
   Loaded: loaded (/usr/lib/systemd/system/dfs.service; disabled; vendor preset: disabled)
   Active: active (exited) since Fri 2018-08-03 18:09:04 UTC; 760ms ago
  Process: 14702 ExecStart=/bin/bash /usr/local/hadoop/etc/hadoop/hadoop-service.sh start (code=exited, status=0/SUCCESS)
 Main PID: 14702 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/dfs.service
           └─15423 /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64/jre//bin/java -Dproc_resourceman...

Aug 03 18:08:45 hn0 systemd[1]: Starting Hadoop Service Controller...
Aug 03 18:08:46 hn0 bash[14702]: Starting namenodes on [localhost]
Aug 03 18:08:50 hn0 bash[14702]: localhost: starting namenode, logging to /usr/local/hadoop-2.7.7/logs/had...n0.out
Aug 03 18:08:54 hn0 bash[14702]: localhost: starting datanode, logging to /usr/local/hadoop-2.7.7/logs/had...n0.out
Aug 03 18:08:55 hn0 bash[14702]: Starting secondary namenodes [0.0.0.0]
Aug 03 18:09:00 hn0 bash[14702]: 0.0.0.0: starting secondarynamenode, logging to /usr/local/hadoop-2.7.7/l...n0.out
Aug 03 18:09:01 hn0 bash[14702]: starting yarn daemons
Aug 03 18:09:01 hn0 bash[14702]: starting resourcemanager, logging to /usr/local/hadoop/logs/yarn-root-res...n0.out
Aug 03 18:09:04 hn0 bash[14702]: localhost: starting nodemanager, logging to /usr/local/hadoop/logs/yarn-r...n0.out
Aug 03 18:09:04 hn0 systemd[1]: Started Hadoop Service Controller.
Hint: Some lines were ellipsized, use -l to show in full.

========================================
Hadoop Services:
========================================
15217 SecondaryNameNode
14835 NameNode
15715 NodeManager
15784 Jps
15006 DataNode
13935 Master
15423 ResourceManager

================================================================================
Finished: /tmp/hadoop_installer.out
================================================================================
```

# Note: 
The checkmarks indicate that portion of the script has completed -- not that it has completed without error.
Always review the log file for validation.

In Progress:

* Variable Configuration File:
 * Hadoop Version
 * Install Directory
 * Data Directories
 * ...whatever your comments lead to...

