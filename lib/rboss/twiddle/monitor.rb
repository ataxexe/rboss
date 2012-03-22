#                         The MIT License
#
# Copyright (c) 2011 Marcelo Guimarães <ataxexe@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'mbean'

module JBoss
  module Twiddle

    module Monitor

      def defaults
        @@defaults ||= {
          :webapp => {
            :description => 'Deployed webapps',
            :pattern => 'jboss.web:type=Manager,host=localhost,path=/#{resource}',
            :properties => %W(activeSessions maxActive distributable maxActiveSessions
                              expiredSessions rejectedSessions),
            :header => [
              ['Context', 'Active', 'Max', 'Distributable', 'Max Active', 'Expired', 'Rejected'],
              ['', 'Sessions', 'Active', '',
               'Sessions', 'Sessions', 'Sessions'],
            ],
            :scan => proc do
              query "jboss.web:type=Manager,*" do |path|
                path.gsub! "jboss.web:type=Manager,path=/", ""
                path.gsub! /,host=.+/, ''
                path
              end
            end
          },
          :web_deployment => {
            :description => 'Deployed webapp control',
            :pattern => 'jboss.web.deployment:war=/#{resource}'
          },
          :connector => {
            :description => 'JBossWeb connector',
            :pattern => 'jboss.web:type=ThreadPool,name=#{resource}',
            :properties => %W(maxThreads currentThreadCount currentThreadsBusy),
            :header => ['Connector', 'Max Threads', 'Current Threads', 'Busy Threads'],
            :health => {
              :indexes => {
                :max => 1,
                :using => 2
              }
            },
            :scan => proc do
              query "jboss.web:type=ThreadPool,*" do |path|
                path.gsub "jboss.web:type=ThreadPool,name=", ""
              end
            end
          },
          :cached_connection_manager => {
            :description => 'JBoss JCA cached connections',
            :pattern => 'jboss.jca:service=CachedConnectionManager',
            :properties => %W(InUseConnections),
            :header => ['In Use Connections'],
            :print_as => :single_list
          },
          :main_deployer => {
            :description => 'Main Deployer',
            :pattern => 'jboss.system:service=MainDeployer'
          },
          :engine => {
            :description => 'JBossWeb engine',
            :pattern => 'jboss.web:type=Engine',
            :properties => %W(jvmRoute name defaultHost),
            :header => ['JVM Route', 'Name', 'Default Host'],
            :print_as => :single_list
          },
          :log4j => {
            :description => 'JBoss Log4J Service',
            :pattern => 'jboss.system:service=Logging,type=Log4jService',
            :properties => %W(DefaultJBossServerLogThreshold),
            :header => ['Default Server Log Threshold'],
            :print_as => :single_list
          },
          :server => {
            :description => 'JBoss Server specifications',
            :pattern => 'jboss.system:type=Server',
            :properties => %W(VersionName VersionNumber Version),
            :header => ['Version Name', 'Version Number', 'Version'],
            :print_as => :single_list
          },
          :server_info => {
            :description => 'JBoss Server runtime info',
            :pattern => 'jboss.system:type=ServerInfo',
            :properties => %W(ActiveThreadCount MaxMemory FreeMemory AvailableProcessors
                              JavaVendor JavaVersion OSName OSArch),
            :header => ['Active Threads', 'Max Memory', 'Free Memory',
                        'Processors', 'Java Vendor',
                        'Java Version', 'OS Name', 'OS Arch'],
            :formatter => {:humanize => [1, 2]},
            :print_as => :single_list,
            :health => {
              :indexes => {
                :max => 1,
                :free => 2
              }
            },
          },
          :server_config => {
            :description => 'JBoss Server configuration',
            :pattern => 'jboss.system:type=ServerConfig',
            :properties => %W(ServerName HomeDir ServerLogDir ServerHomeURL),
            :header => ['Server Name', 'Home Dir', 'Log Dir', 'Home URL'],
            :print_as => :single_list
          },
          :system_properties => {
            :description => 'System properties',
            :pattern => 'jboss:name=SystemProperties,type=Service'
          },
          :request => {
            :description => 'JBossWeb connector requests',
            :pattern => 'jboss.web:type=GlobalRequestProcessor,name=#{resource}',
            :properties => %W(requestCount errorCount maxTime),
            :header => ['Connector', 'Requests', 'Errors', 'Max Time'],
            :health => {
              :indexes => {
                :max => 1,
                :using => 2
              }
            },
            :scan => proc do
              query "jboss.web:type=ThreadPool,*" do |path|
                path.gsub "jboss.web:type=ThreadPool,name=", ""
              end
            end
          },
          :datasource => {
            :description => 'Datasource',
            :pattern => 'jboss.jca:service=ManagedConnectionPool,name=#{resource}',
            :properties => %W(MinSize MaxSize AvailableConnectionCount
                                InUseConnectionCount ConnectionCount),
            :header => [
              ['JNDI Name', 'Min', 'Max', 'Connections', 'Connections', 'Connection'],
              ['', 'Size', 'Size', 'Avaliable', 'In Use', 'Count']
            ],
            :health => {
              :indexes => {
                :max => 2,
                :using => 4
              }
            },
            :scan => proc do
              query "jboss.jca:service=ManagedConnectionPool,*" do |path|
                path.gsub "jboss.jca:service=ManagedConnectionPool,name=", ""
              end
            end
          },
          :queue => {
            :description => 'JMS Queue',
            :pattern => 'jboss.messaging.destination:service=Queue,name=#{resource}',
            :properties => %W(JNDIName MessageCount DeliveringCount
              ScheduledMessageCount MaxSize FullSize Clustered ConsumerCount),
            :header => ['Name', 'JNDI', 'Messages', 'Deliveries', 'Scheduleded', 'Max Size',
                        'Full Size', 'Clustered', 'Consumed'],
            :scan => proc do
              query "jboss.messaging.destination:service=Queue,*" do |path|
                path.gsub "jboss.messaging.destination:service=Queue,name=", ""
              end
            end
          },
          :jndi => {
            :description => 'JNDI View',
            :pattern => 'jboss:service=JNDIView'
          },
          :ejb => {
            :description => 'EJB',
            :pattern => 'jboss.j2ee:#{resource},service=EJB3',
            :properties => %W(CreateCount RemoveCount CurrentSize AvailableCount),
            :header => ['EJB', 'Created', 'Removed', 'Current', 'Available'],
            :scan => proc do
              result = query "jboss.j2ee:*"
              (result.find_all do |path|
                path["service=EJB3"] && path["name="] && path["jar="] && !path["ear="]
              end).collect do |path|
                path.gsub("jboss.j2ee:", '').gsub(/,?service=EJB3/, '')
              end
            end
          }
        }
      end

      module_function :defaults

      def mbeans
        @mbeans ||= {}
      end

      def monitor mbean_id, params
        mbeans[mbean_id] = JBoss::MBean::new params.merge(:twiddle => @twiddle)
      end

      def mbean mbean_id
        mbean = mbeans[mbean_id]
        return JBoss::MBean::new :pattern => mbean_id.to_s, :twiddle => @twiddle unless mbean
        if @current_resource
          mbean.with @current_resource
        end
        mbean
      end

    end

  end

end
