# Setup an environment for running this book's examples

FROM ubuntu
MAINTAINER Russell Jurney, russell.jurney@gmail.com

USER root


# Update apt-get and install things
RUN apt-get autoclean
RUN apt-get update && \
    apt-get install -y sudo zip unzip curl bzip2 python-dev build-essential git libssl1.0.0 libssl-dev

RUN groupadd -g 999 ubuntu && \
    useradd -G sudo -m -r -u 999 -g ubuntu ubuntu

# Setup Oracle Java8
RUN apt-get install -y software-properties-common debconf-utils && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    apt-get install -y oracle-java8-installer
ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle


WORKDIR /home/ubuntu
USER ubuntu

# Download and install Anaconda Python
#RUN curl -sL http://repo.continuum.io/archive/Anaconda3-4.2.0-Linux-x86_64.sh /tmp/Anaconda3-4.2.0-Linux-x86_64.sh
RUN curl -sL https://repo.anaconda.com/archive/Anaconda3-5.1.0-Linux-x86_64.sh -O && \
    bash ./Anaconda3-5.1.0-Linux-x86_64.sh -b -p /home/ubuntu/anaconda
ENV PATH="/home/ubuntu/anaconda/bin:$PATH"

#
# Install git, clone repo, install Python dependencies
#
RUN git clone https://github.com/rjurney/Agile_Data_Code_2
WORKDIR /home/ubuntu/Agile_Data_Code_2
ENV PROJECT_HOME=/Agile_Data_Code_2
RUN pip install --upgrade pip && \
    pip install -r requirements.txt
WORKDIR /home/ubuntu

#
# Install Hadoop: may need to update this link... see http://hadoop.apache.org/releases.html
#
#RUN curl -sL http://apache.osuosl.org/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz /tmp/hadoop-2.7.3.tar.gz
RUN curl -sL http://apache.osuosl.org/hadoop/common/hadoop-2.7.6/hadoop-2.7.6.tar.gz -O && \
    mkdir -p /home/ubuntu/hadoop && \
    tar -xvf hadoop-2.7.6.tar.gz -C hadoop --strip-components=1
ENV HADOOP_HOME=/home/ubuntu/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin
ENV HADOOP_CLASSPATH=/home/ubuntu/hadoop/etc/hadoop/:/home/ubuntu/hadoop/share/hadoop/common/lib/*:/home/ubuntu/hadoop/share/hadoop/common/*:/home/ubuntu/hadoop/share/hadoop/hdfs:/home/ubuntu/hadoop/share/hadoop/hdfs/lib/*:/home/ubuntu/hadoop/share/hadoop/hdfs/*:/home/ubuntu/hadoop/share/hadoop/yarn/lib/*:/home/ubuntu/hadoop/share/hadoop/yarn/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/lib/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/*:/home/ubuntu/hadoop/etc/hadoop:/home/ubuntu/hadoop/share/hadoop/common/lib/*:/home/ubuntu/hadoop/share/hadoop/common/*:/home/ubuntu/hadoop/share/hadoop/hdfs:/home/ubuntu/hadoop/share/hadoop/hdfs/lib/*:/home/ubuntu/hadoop/share/hadoop/hdfs/*:/home/ubuntu/hadoop/share/hadoop/yarn/lib/*:/home/ubuntu/hadoop/share/hadoop/yarn/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/lib/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/*:/home/ubuntu/hadoop/contrib/capacity-scheduler/*.jar:/home/ubuntu/hadoop/contrib/capacity-scheduler/*.jar
ENV HADOOP_CONF_DIR=/home/ubuntu/hadoop/etc/hadoop

#
# Install Spark: may need to update this link... see http://spark.apache.org/downloads.html
#
#RUN curl -sL http://d3kbcqa49mib13.cloudfront.net/spark-2.1.0-bin-without-hadoop.tgz /tmp/spark-2.1.0-bin-without-hadoop.tgz
RUN curl -sL https://archive.apache.org/dist/spark/spark-2.3.0/spark-2.3.0-bin-without-hadoop.tgz -O && \
    mkdir -p /home/ubuntu/spark && \
    tar -xvf spark-2.3.0-bin-without-hadoop.tgz -C spark --strip-components=1
ENV SPARK_HOME=/home/ubuntu/spark
ENV HADOOP_CONF_DIR=/home/ubuntu/hadoop/etc/hadoop/
ENV SPARK_DIST_CLASSPATH=/home/ubuntu/hadoop/etc/hadoop/:/home/ubuntu/hadoop/share/hadoop/common/lib/*:/home/ubuntu/hadoop/share/hadoop/common/*:/home/ubuntu/hadoop/share/hadoop/hdfs:/home/ubuntu/hadoop/share/hadoop/hdfs/lib/*:/home/ubuntu/hadoop/share/hadoop/hdfs/*:/home/ubuntu/hadoop/share/hadoop/yarn/lib/*:/home/ubuntu/hadoop/share/hadoop/yarn/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/lib/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/*:/home/ubuntu/hadoop/etc/hadoop:/home/ubuntu/hadoop/share/hadoop/common/lib/*:/home/ubuntu/hadoop/share/hadoop/common/*:/home/ubuntu/hadoop/share/hadoop/hdfs:/home/ubuntu/hadoop/share/hadoop/hdfs/lib/*:/home/ubuntu/hadoop/share/hadoop/hdfs/*:/home/ubuntu/hadoop/share/hadoop/yarn/lib/*:/home/ubuntu/hadoop/share/hadoop/yarn/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/lib/*:/home/ubuntu/hadoop/share/hadoop/mapreduce/*:/home/ubuntu/hadoop/contrib/capacity-scheduler/*.jar:/home/ubuntu/hadoop/contrib/capacity-scheduler/*.jar
ENV PATH=$PATH:/home/ubuntu/spark/bin

# Have to set spark.io.compression.codec in Spark local mode, give 8GB RAM
RUN cp /home/ubuntu/spark/conf/spark-defaults.conf.template /home/ubuntu/spark/conf/spark-defaults.conf && \
    echo 'spark.io.compression.codec org.apache.spark.io.SnappyCompressionCodec' >> /home/ubuntu/spark/conf/spark-defaults.conf && \
    echo "spark.driver.memory 8g" >> /home/ubuntu/spark/conf/spark-defaults.conf

# Setup spark-env.sh to use Python 3
RUN echo "PYSPARK_PYTHON=python3" >> /home/ubuntu/spark/conf/spark-env.sh && \
    echo "PYSPARK_DRIVER_PYTHON=python3" >> /home/ubuntu/spark/conf/spark-env.sh

# Setup log4j config to reduce logging output
RUN cp /home/ubuntu/spark/conf/log4j.properties.template /home/ubuntu/spark/conf/log4j.properties && \
    sed -i 's/INFO/ERROR/g' /home/ubuntu/spark/conf/log4j.properties

#
# Install Mongo, Mongo Java driver, and mongo-hadoop and start MongoDB
#
USER root
RUN echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.4.list
RUN apt-get update && \
    apt-get install -y --allow-unauthenticated mongodb-org && \
    mkdir -p /data/db
# apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 && \

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER ubuntu
# Get the MongoDB Java Driver and put it in Agile_Data_Code_2
#RUN curl -sL http://central.maven.org/maven2/org/mongodb/mongo-java-driver/3.4.0/mongo-java-driver-3.4.0.jar /tmp/mongo-java-driver-3.4.0.jar
RUN curl -sL http://central.maven.org/maven2/org/mongodb/mongo-java-driver/3.6.3/mongo-java-driver-3.6.3.jar -O && \
    mv ./mongo-java-driver-3.6.3.jar /home/ubuntu/Agile_Data_Code_2/lib/

# Install the mongo-hadoop project in the mongo-hadoop directory in the root of our project.
RUN curl -sL https://github.com/mongodb/mongo-hadoop/archive/r1.5.2.tar.gz -O && \
    mkdir -p /home/ubuntu/mongo-hadoop && \
    tar -xvzf ./r1.5.2.tar.gz -C mongo-hadoop --strip-components=1 && \
    rm -f ./r1.5.2.tar.gz
WORKDIR /home/ubuntu/mongo-hadoop
RUN /home/ubuntu/mongo-hadoop/gradlew jar
WORKDIR /home/ubuntu
RUN cp /home/ubuntu/mongo-hadoop/spark/build/libs/mongo-hadoop-spark-*.jar /home/ubuntu/Agile_Data_Code_2/lib/ && \
    cp /home/ubuntu/mongo-hadoop/build/libs/mongo-hadoop-*.jar /home/ubuntu/Agile_Data_Code_2/lib/

# Install pymongo_spark
WORKDIR /home/ubuntu/mongo-hadoop/spark/src/main/python
RUN python setup.py install
WORKDIR /home/ubuntu
RUN cp /home/ubuntu/mongo-hadoop/spark/src/main/python/pymongo_spark.py /home/ubuntu/Agile_Data_Code_2/lib/
ENV PYTHONPATH=$PYTHONPATH:/home/ubuntu/Agile_Data_Code_2/lib

# Cleanup mongo-hadoop
RUN rm -rf /home/ubuntu/mongo-hadoop

#
# Install ElasticSearch in the elasticsearch directory in the root of our project, and the Elasticsearch for Hadoop package
#
RUN curl -sL https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.4.tar.gz -O && \
    mkdir /home/ubuntu/elasticsearch && \
    tar -xvzf ./elasticsearch-6.2.4.tar.gz -C elasticsearch --strip-components=1 && \
    /home/ubuntu/elasticsearch/bin/elasticsearch -d && \
    rm -f ./elasticsearch-6.2.4.tar.gz

# Install Elasticsearch for Hadoop
#RUN curl -sL http://download.elastic.co/hadoop/elasticsearch-hadoop-6.2.4.zip /tmp/elasticsearch-hadoop-6.2.4.zip
RUN curl -sL https://artifacts.elastic.co/downloads/elasticsearch-hadoop/elasticsearch-hadoop-6.2.4.zip -O && \
    unzip ./elasticsearch-hadoop-6.2.4.zip && \
    mv /home/ubuntu/elasticsearch-hadoop-6.2.4 /home/ubuntu/elasticsearch-hadoop && \
    cp /home/ubuntu/elasticsearch-hadoop/dist/elasticsearch-hadoop-6.2.4.jar /home/ubuntu/Agile_Data_Code_2/lib/ && \
    cp /home/ubuntu/elasticsearch-hadoop/dist/elasticsearch-spark-20_2.11-6.2.4.jar /home/ubuntu/Agile_Data_Code_2/lib/ && \
    echo "spark.speculation false" >> /home/ubuntu/spark/conf/spark-defaults.conf && \
    rm -f ./elasticsearch-hadoop-6.2.4.zip && \
    rm -rf /home/ubuntu/elasticsearch-hadoop

# Install and add snappy-java and lzo-java to our classpath below via spark.jars
RUN curl -sL http://central.maven.org/maven2/org/xerial/snappy/snappy-java/1.1.2.6/snappy-java-1.1.2.6.jar -O && \
    mv ./snappy-java-1.1.2.6.jar /home/ubuntu/Agile_Data_Code_2/lib/ && \
    curl -sL http://central.maven.org/maven2/org/anarres/lzo/lzo-hadoop/1.0.5/lzo-hadoop-1.0.5.jar -O && \
    mv ./lzo-hadoop-1.0.5.jar /home/ubuntu/Agile_Data_Code_2/lib/

# Setup mongo and elasticsearch jars for Spark
RUN echo "spark.jars /home/ubuntu/Agile_Data_Code_2/lib/mongo-hadoop-spark-1.5.2.jar,/home/ubuntu/Agile_Data_Code_2/lib/mongo-java-driver-3.6.3.jar,/home/ubuntu/Agile_Data_Code_2/lib/mongo-hadoop-1.5.2.jar,/home/ubuntu/Agile_Data_Code_2/lib/elasticsearch-spark-20_2.11-6.2.4.jar,/home/ubuntu/Agile_Data_Code_2/lib/snappy-java-1.1.2.6.jar,/home/ubuntu/Agile_Data_Code_2/lib/lzo-hadoop-1.0.5.jar" >> /home/ubuntu/spark/conf/spark-defaults.conf

#
# Install and setup Kafka
#

#RUN curl -sL http://www-us.apache.org/dist/kafka/0.10.1.1/kafka_2.11-0.10.1.1.tgz /tmp/kafka_2.11-0.10.1.1.tgz
RUN curl -sL http://www.gtlib.gatech.edu/pub/apache/kafka/0.11.0.2/kafka_2.11-0.11.0.2.tgz -O && \
    mkdir -p /home/ubuntu/kafka && \
    tar -xvzf ./kafka_2.11-0.11.0.2.tgz -C kafka --strip-components=1 && \
    rm -f ./kafka_2.11-0.11.0.2.tgz

# Run zookeeper (which kafka depends on), then Kafka
RUN /home/ubuntu/kafka/bin/zookeeper-server-start.sh -daemon /home/ubuntu/kafka/config/zookeeper.properties && \
    /home/ubuntu/kafka/bin/kafka-server-start.sh -daemon /home/ubuntu/kafka/config/server.properties

#
# Install and set up Airflow
#
# Install Apache Incubating Airflow
RUN pip install airflow && \
    mkdir /home/ubuntu/airflow && \
    mkdir /home/ubuntu/airflow/dags && \
    mkdir /home/ubuntu/airflow/logs && \
    mkdir /home/ubuntu/airflow/plugins && \
    airflow initdb 

#
# Install and setup Zeppelin
#
WORKDIR /home/ubuntu
#RUN curl -sL http://www-us.apache.org/dist/zeppelin/zeppelin-0.6.2/zeppelin-0.6.2-bin-all.tgz /tmp/zeppelin-0.6.2-bin-all.tgz
RUN curl -sL http://mirror.olnevhost.net/pub/apache/zeppelin/zeppelin-0.7.3/zeppelin-0.7.3-bin-all.tgz -O && \
    mkdir -p /home/ubuntu/zeppelin && \
    tar -xvzf ./zeppelin-0.7.3-bin-all.tgz -C zeppelin --strip-components=1 && \
    rm -f ./zeppelin-0.7.3-bin-all.tgz

# Configure Zeppelin
RUN cp /home/ubuntu/zeppelin/conf/zeppelin-env.sh.template /home/ubuntu/zeppelin/conf/zeppelin-env.sh && \
    echo "export SPARK_HOME=/home/ubuntu/spark" >> /home/ubuntu/zeppelin/conf/zeppelin-env.sh && \
    echo "export SPARK_MASTER=local" >> /home/ubuntu/zeppelin/conf/zeppelin-env.sh && \
    echo "export SPARK_CLASSPATH=" >> /home/ubuntu/zeppelin/conf/zeppelin-env.sh

#
# Download the data
#
WORKDIR /home/ubuntu/Agile_Data_Code_2/data

# On-time performance records
RUN curl -sL http://s3.amazonaws.com/agile_data_science/On_Time_On_Time_Performance_2015.csv.gz -O && \
   gzip -d ./On_Time_On_Time_Performance_2015.csv.gz

# Openflights data
RUN curl -sL https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat -O 
RUN curl -sL https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat -O 
RUN curl -sL https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat -O 
RUN curl -sL https://raw.githubusercontent.com/jpatokal/openflights/master/data/countries.dat -O 

# FAA data
RUN curl -sL http://av-info.faa.gov/data/ACRef/tab/aircraft.txt -O 
RUN curl -sL http://av-info.faa.gov/data/ACRef/tab/ata.txt -O 
RUN curl -sL http://av-info.faa.gov/data/ACRef/tab/compt.txt -O 
RUN curl -sL http://av-info.faa.gov/data/ACRef/tab/engine.txt -O 
RUN curl -sL http://av-info.faa.gov/data/ACRef/tab/prop.txt -O 

# WBAN Master List
RUN curl -sL http://www.ncdc.noaa.gov/homr/file/wbanmasterlist.psv.zip -O && \
    unzip -o ./wbanmasterlist.psv.zip

RUN for i in $(seq -w 1 12); do curl -Lko /tmp/QCLCD2015${i}.zip http://www.ncdc.noaa.gov/orders/qclcd/QCLCD2015${i}.zip && \
    unzip -o /tmp/QCLCD2015${i}.zip && \
    gzip 2015${i}*.txt && \
    rm -f /tmp/QCLCD2015${i}.zip; done


# Back to /home/ubuntu
WORKDIR /home/ubuntu

RUN jupyter-notebook --generate-config && \
  cp /home/ubuntu/Agile_Data_Code_2/jupyter_notebook_config.py /home/ubuntu/.jupyter

EXPOSE 5000
EXPOSE 4567
EXPOSE 8888

USER ubuntu
COPY startup.sh startup.sh
CMD chmod +x /home/ubuntu/startup.sh && /home/ubuntu/startup.sh
# Done!