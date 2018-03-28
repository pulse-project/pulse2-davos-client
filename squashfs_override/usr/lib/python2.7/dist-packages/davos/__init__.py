# -*- coding: utf-8; -*-
#
# (c) 2007-2015 Mandriva, http://www.mandriva.com/
#
# $Id$
#
# This file is part of Pulse 2, http://pulse2.mandriva.org
#
# Pulse 2 is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Pulse 2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Pulse 2.  If not, see <http://www.gnu.org/licenses/>.

import os, subprocess
import logging
from log import ColoredFormatter
from davos.xmlrpc_client import pkgServerProxy
import re

class davosManager(object):

    debug_mode = True

    def __init__(self):

        # Init logger
        self.initLogger()

        self.logger.debug('Initializing davos')

        # Read Kernel Params
        self.getKernelParams()
        self.server = self.kernel_params['fetch'].split('/')[2]

        self.action = self.kernel_params['davos_action']

        # Get mac address if set. If not, it is a new machine
        try:
            self.mac = self.kernel_params['mac']
        except KeyError:
            pass

        # Get nfs parameters if set. If not, use default values
        try:
            self.nfs_server = self.kernel_params['nfs_server']
        except KeyError:
            self.nfs_server = self.server

        try:
            self.nfs_share_masters = self.kernel_params['nfs_share_masters']
        except KeyError:
            self.nfs_share_masters = '/var/lib/pulse2/imaging/masters/'

        try:
            self.nfs_share_postinst = self.kernel_params['nfs_share_postinst']
        except KeyError:
            self.nfs_share_postinst = '/var/lib/pulse2/imaging/postinst/'

        try:
            self.dump_path = self.kernel_params['dump_path']
        except KeyError:
            self.dump_path = 'inventories'

        try:
            self.timereboot = self.kernel_params['timereboot']
        except KeyError:
            self.timereboot = 2

        try:
            self.tftp_ip = self.kernel_params['tftp_ip']
        except KeyError:
            self.tftp_ip = self.server

        # Init XMLRPC Client
        self.rpc = pkgServerProxy(self.server)

        if self.action == 'REGISTER':
            # Define hostname
            self.setHostname()
        else:
            # Get hostname and uuid
            self.getHostInfo()
            # Clonezilla parameters
            self.getClonezillaParams()
            # Mount NFS Shares
            self.mountNFSShares()
            # Partimag symlink
            self.createPartimagSymlink()

    def initLogger(self):
        self.logger = logging.getLogger('davos')
        self.log_level = level = logging.INFO #logging.DEBUG

        # Init logger

        fhd = logging.FileHandler('/var/log/davos.log')
        fhd.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
        fhd.setLevel(level)
        self.logger.addHandler(fhd)

        if self.debug_mode:
            hdlr2 = logging.StreamHandler()
            hdlr2.setFormatter(ColoredFormatter("%(levelname)-18s %(message)s"))
            hdlr2.setLevel(level)
            self.logger.addHandler(hdlr2)
        
        self.logger.setLevel(level)

    
    def getKernelParams(self):
        
        self.logger.debug('Reading kernel params')

        self.kernel_params = {}

        with open('/proc/cmdline', 'r') as f:
            cmd_line = f.read().strip()
            for item in cmd_line.split(' '):
                if '=' in item:
                    key, value = item.split('=')
                else:
                    key, value = item, None
                self.kernel_params[key] = value
        
        self.logger.debug('Got kernel params %s', str(self.kernel_params))


    def runInShell(self, cmd, *args):
        # If cmd is str and args are not empty remplace them (format)
        if isinstance(cmd, str) and args:
            cmd = cmd % args
        if not isinstance(cmd, list):
            cmd = [cmd]

        self.logger.debug('Running %s', cmd)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        out, err = process.communicate()

        self.logger.debug('Error code: %d', process.returncode)
        self.logger.debug('Output: %s', out)
        
        return out.strip(), err.strip(), process.returncode


    def isEmptyDir(self, path):
        return os.listdir(path) == []


    def getHostInfo(self):
        self.logger.info('Asking for hostinfo')

        self.host_data = self.rpc.imaging_api.getComputerByMac(self.mac)

        self.hostname = self.host_data['shortname']
        # Setting env and machine hostname (for inventory)
        os.environ['HOSTNAME'] = self.hostname
        self.runInShell('hostname ' + self.hostname)
        self.runInShell('sed -i "s/debian/' + self.hostname + '/" /etc/hosts')

        self.logger.info('Got hostname: %s', self.hostname)

        self.host_uuid = self.host_data['uuid']
        self.logger.info('Got UUID: %s', self.host_uuid)

        self.host_entity = self.host_data['entity']
        self.logger.info('Got entity: %s', self.host_entity)


    def getClonezillaParams(self):
        """
        get Clonezilla parameters for the machine
        """
        self.logger.info('Asking for Clonezilla parameters')

        self.clonezilla_params = self.rpc.imaging_api.getClonezillaParamsForTarget(self.host_uuid)


    def mountNFSShares(self):
        # Server address
        server = self.nfs_server

        # Masters Share
        local_dir = '/imaging_server/masters/'
        if not os.path.exists(local_dir):
            os.makedirs(local_dir)
        if self.isEmptyDir(local_dir):
            self.logger.info('Mounting %s NFS Share', local_dir)
            o, e, ec = self.runInShell('mount %s:%s %s' % (server, self.nfs_share_masters, local_dir))
            if ec != 0:
                self.logger.error('Cannot mount %s Share', local_dir)
                self.logger.error('Output: %s', e)

        # Postinst share
        local_dir = '/opt/'
        if not os.path.exists(local_dir):
            os.mkdir(local_dir)
        if self.isEmptyDir(local_dir):
            self.logger.info('Mounting %s NFS Share', local_dir)
            o, e, ec = self.runInShell('mount %s:%s %s' % (server, self.nfs_share_postinst, local_dir))
            if ec != 0:
                self.logger.error('Cannot mount %s Share', local_dir)
                self.logger.error('Output: %s', e)

    def createPartimagSymlink(self):
        # Remove /home/partimag dir
        if self.isEmptyDir('/home/partimag'):
            self.logger.debug('Removing dir: %s', '/home/partimag')
            os.rmdir('/home/partimag')
   
            # Create a symlink to /masters remote directory
            self.logger.debug('Creating symlink to: %s', '/imaging_server/masters')
            os.symlink('/imaging_server/masters', '/home/partimag')

    def is_valid_hostname(self,hostname):
        """
        Check that hostname is valid
        """
        if len(hostname) > 255:
            return False
        if hostname[-1] == ".":
            hostname = hostname[:-1] # strip exactly one dot from the right, if present
        allowed = re.compile("(?!-)[A-Z\d-]{1,63}(?<!-)$", re.IGNORECASE)
        return all(allowed.match(x) for x in hostname.split("."))

    def confirm(self,response):
        """
        Ask user to enter Y or N (case-insensitive).
        :return: True if the answer is Y.
        :rtype: bool
        """
        answer = ""
        while answer not in ["y", "n"]:
            answer = raw_input("You have entered %s. Is this correct [Y/N]? " % response).lower()
        return answer == "y"

    def setHostname(self):
        """
        Ask user to enter hostname of machine and set it on the system
        """
        self.logger.info('Asking user for hostname')
        while True:
            machinename = raw_input("Please enter the machine name: ")
            if self.is_valid_hostname(machinename):
                if self.confirm(machinename):
                    self.hostname = machinename
                    break
            else:
                print("The hostname %s entered is not valid." % machinename)
        # Setting hostname
        self.logger.info('Setting hostname: %s', self.hostname)
        os.environ['HOSTNAME'] = self.hostname
        self.runInShell('hostname ' + self.hostname)
        self.runInShell('sed -i "s/debian/' + self.hostname + '/" /etc/hosts')
