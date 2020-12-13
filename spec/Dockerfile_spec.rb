# Copyright (c) 2017-present Sonatype, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'serverspec'
require 'docker'

describe 'Dockerfile' do
  before(:all) do
    Docker.options[:read_timeout] = 900
    @image = Docker::Image.get(ENV['IMAGE_ID'])

    set :os, family: :redhat
    set :backend, :docker
    set :docker_image, @image.id
  end

  describe group('nexus') do
    it 'exists' do
      expect(subject).to exist
    end

    it 'has a specific id' do
      expect(subject).to have_gid(1000)
    end
  end

  describe user('nexus') do
    it 'exists' do
      expect(subject).to exist
    end

    it 'belongs to the nexus group' do
      expect(subject).to belong_to_group('nexus')
    end

    it 'has a specific id' do
      expect(subject).to have_uid(997)
    end

    it 'has the installation directory as home directory' do
      expect(subject).to have_home_directory('/opt/sonatype/nexus-iq-server')
    end
  end

  describe process('java') do
    it 'is running' do
      expect(subject).to be_running
    end

    it 'belongs to the nexus user' do
      expect(subject).to have_attributes(:user => 'nexus')
    end
  end

  describe 'Port configuration' do
    it 'exposes the application port' do
      expect(@image.json['Config']['ExposedPorts']).to have_key('8070/tcp')
    end

    it 'exposes the admin port' do
      expect(@image.json['Config']['ExposedPorts']).to have_key('8071/tcp')
    end
  end

  describe 'Log directory' do
    logDirectory = '/var/log/nexus-iq-server/'

    it 'is a directory' do
      expect(file(logDirectory)).to be_a_directory
    end

    it 'has the right permissions' do
      expect(file(logDirectory)).to be_mode(755)
    end

    it 'is owned by the nexus user/group' do
      expect(file(logDirectory)).to be_owned_by('nexus')
      expect(file(logDirectory)).to be_grouped_into('nexus')
    end

    it 'contains the application log' do
      expect(file(logDirectory + 'clm-server.log')).to be_a_file
    end

    it 'contains the audit log' do
      expect(file(logDirectory + 'audit.log')).to be_a_file
    end

    it 'contains the request log' do
      expect(file(logDirectory + 'request.log')).to be_a_file
    end

    it 'contains the stderr log' do
      expect(file(logDirectory + 'stderr.log')).to be_a_file
    end
  end
end
