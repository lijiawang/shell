==============
VMHA安装使用说明
==============

安装vmha
-------

#. 获取vmha脚本

   .. code-block:: language

       git clone git@gitlab.sh.99cloud.net:99cloud/tools.git
       进入tools 目录即可获取 vmha脚本

#. 安装环境
   将vmha安装至OpenStack环境的控制节点，或者安装在包含keystoneclient,
   novaclient的其他机器中

#. 以控制节点为例安装vmha

   .. code-block:: language

       将下载的tools仓库中vmha脚本拷贝至controller节点
       cd vmha/script/
       ./INSTALL

配置vmha
-------

   .. code-block:: language

       cd /opt/vmha/conf/
       vim vmha.conf 参考配置如下

       #openstack keystone info.
       OS_REGION_NAME=RegionOne
       OS_PROJECT_DOMAIN_ID=default
       OS_USER_DOMAIN_ID=default
       OS_PROJECT_NAME=admin
       OS_USERNAME=admin
       OS_PASSWORD=admin
       OS_AUTH_URL=http://172.16.203.100:35357/v3
       OS_IDENTITY_API_VERSION=3
       OS_AUTH_VERSION=3
       OS_COMPUTE_API_VERSION=2.5

       #check high available OpenStack zone
       #Use , to seperate zone name
       HIGH_AVAILABLE_ZONE=nova

       #number of ping failed, host-evacuate will occur <number>
       FAILED_CHECK_TIME=6

       #each ping interval <second>
       PING_INTERVAL=1

       #each ping timeout. After this second, we believe a failed ping. <second>
       PING_TIMEOUT=2

       #debug flag
       DEBUG=1

       #Use , to seperate filter hosts
       #该选项暂不可用，暂不必要配置
       #VMHA_HOST_FILTER=filter.trystack.cn

启动vmha
-------

   .. code-block:: language

       /ect/init.d/vmha start
       默认vmha 没有开机启动

注意
---

#. 配置中 `VMHA_HOST_FILTER` 暂配置无效, 无需配置该选项

