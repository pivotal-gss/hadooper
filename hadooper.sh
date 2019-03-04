#!/bin/bash

printf '=%.0s' {1..80} && echo
echo "Install script for Hadoop 2.7 on CentOS 7/x86_64"
printf '=%.0s' {1..80} && echo

if [[ $EUID -ne 0 ]]; then
   echo "ERROR: Run as root : sudo or sudo su -" 
   exit 1
fi

#
# SPINNER for Long Running Processes...
#
spinner()
{
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    printf "[√]\n"
}

#
# PACKAGES
#
printf "Installing Packages..." | tee /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    yum install -y curl which tar sudo openssh-server openssh-clients rsync java-1.8.0-openjdk java-1.8.0-openjdk-devel
) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

#
#PASSWORDLESS SSH
#
ROOT_HOME="/root"
ROOT_SSH_HOME="$ROOT_HOME/.ssh"
ROOT_AUTHORIZED_KEYS="$ROOT_SSH_HOME/authorized_keys"
VAGRANT_HOME="/home/vagrant"
VAGRANT_SSH_HOME="$VAGRANT_HOME/.ssh"
VAGRANT_AUTHORIZED_KEYS="$VAGRANT_SSH_HOME/authorized_keys"

printf "Configuring Passwordless SSH..."  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out

(
    if [ ! -f "$ROOT_SSH_HOME/id_rsa" ]; then ssh-keygen -C root@localhost -f "$ROOT_SSH_HOME/id_rsa" -q -N ""; fi
    if [ ! -f "$VAGRANT_SSH_HOME/id_rsa" ]; then ssh-keygen -C vagrant@localhost -f "$VAGRANT_SSH_HOME/id_rsa" -q -N ""; fi

    cat "$ROOT_SSH_HOME/id_rsa.pub" >> "$ROOT_AUTHORIZED_KEYS"
    cat "$VAGRANT_SSH_HOME/id_rsa.pub" >> "$ROOT_AUTHORIZED_KEYS"
    cat "$VAGRANT_SSH_HOME/id_rsa.pub" >> "$VAGRANT_AUTHORIZED_KEYS"

    sort "$ROOT_AUTHORIZED_KEYS" | uniq > "$ROOT_AUTHORIZED_KEYS".uniq
    sort "$VAGRANT_AUTHORIZED_KEYS" | uniq > "$VAGRANT_AUTHORIZED_KEYS".uniq

    mv "$ROOT_AUTHORIZED_KEYS"{.uniq,}
    mv "$VAGRANT_AUTHORIZED_KEYS"{.uniq,}

    chmod 644 "$ROOT_AUTHORIZED_KEYS"
    chmod 644 "$VAGRANT_AUTHORIZED_KEYS"
    
    ssh-keyscan -H localhost >> "$ROOT_SSH_HOME/known_hosts"
    ssh-keyscan -H 0.0.0.0 >> "$ROOT_SSH_HOME/known_hosts"

    ssh-keyscan -H localhost >> "$VAGRANT_SSH_HOME/known_hosts"
    ssh-keyscan -H 0.0.0.0 >> "$VAGRANT_SSH_HOME/known_hosts"

    chown -R vagrant:vagrant "$VAGRANT_SSH_HOME"

    service sshd start
) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

#
#HADOOP
#
HADOOP_PREFIX=/usr/local/hadoop
printf "Download & Extract Hadoop [/usr/local]..."  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
( curl -s http://www.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz | tar -xz -C /usr/local/ ) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

#
# ENVIRONMENT VARIABLES
#
printf "Configuration: \n"  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out

# HOSTNAME
printf "\t Verify Hosts File: /etc/hosts "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
( ping $HOSTNAME -c 1 -W 1 || echo "127.0.0.1 $HOSTNAME" >>/etc/hosts ) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!


# HADOOP SYMLINK
printf "\t Symlink Hadoop: /usr/local/hadoop "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
( if [ -f "/usr/local/hadoop" ]; then rm /usr/local/hadoop; fi && ln -s /usr/local/hadoop-2.7.7 /usr/local/hadoop ) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!


# OS ENVIORNMENT VARIABLES
printf "\t Environment Variables: /etc/profile.d/hadoop-profile.sh "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    cat > /etc/profile.d/hadoop-profile.sh<<'    EOF'
    # JAVA
    export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
    export PATH=$PATH:$JAVA_HOME/bin

    # HADOOP
    export HADOOP_HOME=/usr/local/hadoop
    export HADOOP_COMMON_HOME=$HADOOP_HOME
    export HADOOP_HDFS_HOME=$HADOOP_HOME
    export HADOOP_MAPRED_HOME=$HADOOP_HOME
    export HADOOP_YARN_HOME=$HADOOP_HOME
    export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
    export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
    EOF
    
    chmod +x /etc/profile.d/hadoop-profile.sh
    
) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!


# HADOOP SYMLINK
printf "\t Create Data Directories: /data/hdfs/namenode /data/hdfs/datanode "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
( mkdir -p /data/hdfs/namenode /data/hdfs/datanode ) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

# HADOOP XML
printf "\t Hadoop Variables: /etc/hadoop/core-site.xml "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    cat > $HADOOP_PREFIX/etc/hadoop/core-site.xml<<'    EOF'
      <configuration>
          <property>
              <name>fs.defaultFS</name>
              <value>hdfs://localhost:9000</value>
          </property>
      </configuration>
    EOF
) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

printf "\t Hadoop Variables: /etc/hadoop/hdfs-site.xml "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    cat > $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml<<'    EOF'
    <configuration>
        <property>
            <name>dfs.data.dir</name>
            <value>file:///data/hdfs/datanode</value>
        </property>
        <property>
            <name>dfs.name.dir</name>
            <value>file:///data/hdfs/namenode</value>
        </property>
        <property>
            <name>dfs.replication</name>
            <value>1</value>
        </property>
    </configuration>
    EOF
)  >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

printf "\t Hadoop Variables: /etc/hadoop/mapred-site.xml "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    cat > $HADOOP_PREFIX/etc/hadoop/mapred-site.xml<<'    EOF'
    <configuration>
        <property>
            <name>mapreduce.framework.name</name>
            <value>yarn</value>
        </property>
    </configuration>
    EOF
) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

printf "\t Hadoop Variables: /etc/hadoop/yarn-site.xml "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    cat > $HADOOP_PREFIX/etc/hadoop/yarn-site.xml<<'    EOF'
    <configuration>
        <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
        </property>
    </configuration>
    EOF
)  >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

# HADOOP ENV SCRIPT
printf "\t Hadoop Variables: /etc/hadoop/hadoop-env.sh "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=\$(readlink -f /usr/bin/java \| sed "s\:bin/java\:\:" )\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
    sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

# HADOOP DAEMONS
printf "\t Hadoop Daemons: /etc/hadoop/hadoop-service.sh "  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
(
    cat > $HADOOP_PREFIX/etc/hadoop/hadoop-service.sh<<'    EOF'
    #!/bin/bash

    start() {
        source "/etc/profile.d/hadoop-profile.sh"

        start-dfs.sh
        start-yarn.sh
    }

    stop() {
        source "/etc/profile.d/hadoop-profile.sh"

        stop-yarn.sh
        stop-dfs.sh
    }

    case $1 in
        start|stop) "$1" ;;
    esac

    exit 0
    EOF

    chmod +x $HADOOP_PREFIX/etc/hadoop/hadoop-service.sh

    cat > /usr/lib/systemd/system/dfs.service<<'    EOF'
    [Unit]
    Description=Hadoop Service Controller
    After=syslog.target network.target remote-fs.target nss-lookup.target network-online.target
    Requires=network-online.target

    [Service]
    User=root
    Group=root
    Type=oneshot
    ExecStart=/bin/bash /usr/local/hadoop/etc/hadoop/hadoop-service.sh start
    ExecStop=/bin/bsh /usr/local/hadoop/etc/hadoop/hadoop-service.sh stop
    WorkingDirectory=/usr/local/hadoop/
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target
    EOF

) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

#
# SOURCE ENVIRONMENT VARIABLES
#
printf "Sourcing Variables..."  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
( 
    source /etc/profile.d/hadoop-profile.sh
    source $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
    source $HADOOP_PREFIX/etc/hadoop/yarn-env.sh

    cat > ~/.bash_profile<<'    EOF'

    source /etc/profile.d/hadoop-profile.sh
    source $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    source $HADOOP_HOME/etc/hadoop/yarn-env.sh

    EOF
				
) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

#
# FORMAT HDFS NAMENODE
#
printf "Formatting HDFS Namenode..."  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
( echo 'Y' | $HADOOP_PREFIX/bin/hdfs namenode -format ) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

#
# SERVICE START
#
printf "Starting Services..."  | tee -a /tmp/hadoop_installer.out && printf "\n\n" >> /tmp/hadoop_installer.out
( service dfs start) >> /tmp/hadoop_installer.out 2>&1 &
spinner $!

echo
printf '=%.0s' {1..40} && echo
echo "Service Status:" 
printf '=%.0s' {1..40} && echo
service dfs status
echo
printf '=%.0s' {1..40} && echo
echo "Hadoop Services:" 
printf '=%.0s' {1..40} && echo
jps
echo
printf '=%.0s' {1..80} && echo
echo "Finished: /tmp/hadoop_installer.out" 
printf '=%.0s' {1..80} && echo

