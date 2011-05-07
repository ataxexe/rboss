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

require_relative "component"

require "logger"
require "rexml/document"

include REXML

module JBoss

  # A class to add deploy folders to a JBoss Profile.
  #
  # author: Marcelo Guimarães <ataxexe@gmail.com>
  class DeployFolder
    include Component

    def initialize jboss, logger, folder
      @jboss = jboss
      @logger = logger
      @folder = folder.to_s

      @absolute_path = @folder.start_with? '/'
      @outside_deploy = (!@folder.start_with?('deploy') and not @absolute_path)

      @configure_vsf_and_profile = (@absolute_path or @outside_deploy)

      @path = @absolute_path ? @folder : "#{@jboss.profile}/#{@folder}"

      @folder = "${jboss.server.home.url}#{@folder}" if @outside_deploy
      @folder = "file://#{@folder}" if @absolute_path
    end

    def process
      @logger.info "Creating deploy folder: #{@path}"
      invoke "mkdir -p #{@path}"

      if @configure_vsf_and_profile
        configure_vfs
        configure_profile
      end
    end

    def configure_profile
      @logger.info "Updating profile.xml"
      processor = create_file_processor
      processor.with "#{@jboss.profile}/conf/bootstrap/profile.xml", :xml do |action|
        action.to_process do |xml, jboss|
          element = XPath.first xml, "//property[@name='applicationURIs']"
          element = XPath.first element, "//list[@elementClass='java.net.URI']"
          deploy = Element::new "value"
          deploy.text = @folder
          element << deploy
          xml
        end
      end
      processor.process
    end

    def configure_vfs
      @logger.info "Updating vfs.xml"
      processor = create_file_processor
      processor.with "#{@jboss.profile}/conf/bootstrap/vfs.xml", :xml do |action|
        action.to_process do |xml, jboss|
          map = XPath.first xml, "//map[@keyClass='java.net.URL']"
          entry = Document::new <<XML
<entry>
  <key>#{@folder}</key>
  <value><inject bean="VfsNamesExceptionHandler"/></value>
</entry>
XML
          map << entry
          xml
        end
      end
      processor.process
    end

  end

end
