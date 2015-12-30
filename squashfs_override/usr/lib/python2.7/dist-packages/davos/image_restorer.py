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

import os
import subprocess
import json
import time
import urllib, urllib2
from davos.inventory import Inventory
from time import sleep
from dialog import Dialog

class imageRestorer(object):

    image_uuid = None

    def __init__(self, manager):

        self.manager = manager
        self.logger = manager.logger
        self.rpc = manager.rpc

    @property
    def available_images(self):
        images = []
        for d in os.listdir('/home/partimag'):
            if os.path.isfile('/home/partimag/%s/davosInfo.json' % d):
                images.append(d)
        return images

    def select_image(self):
        def _get_title(image_uuid):
            try:
                _json = json.loads(open('/home/partimag/%s/davosInfo.json' % image_uuid, 'r').read())
                return _json['title']
            except:
                return image_uuid
        available_images = self.available_images
        d = Dialog(dialog="dialog")
        choices = [(str(available_images.index(x) + 1), _get_title(x)) for x in available_images]
        code, tag = d.menu("Select image to restore from:", choices=choices, backtitle="Mandriva Pulse Imaging Client")
        if code != 0:
            # Leave (no image selected)
            return False
        self.image_uuid = available_images[code - 1]
        return True


    def check_image(self):

        # Check if the image exists or not
        if not os.path.isdir('/home/partimag/' + self.image_uuid):
            d = Dialog(dialog="dialog")
            d.msgbox("Could not find image on server", backtitle="Mandriva Pulse Imaging Client")
            raise Exception('Could not find image on server')
        # Check if image is compatible (davos)
        if not os.path.isfile('/home/partimag/%s/davosInfo.json' % self.image_uuid):
            d = Dialog(dialog="dialog")
            d.msgbox("Selected image is not compatible with this backend, please convert this image to the correct format.", backtitle="Mandriva Pulse Imaging Client")
            raise Exception('Could not find image on server')


    def start(self):

        # Get image UUID
        if not self.image_uuid:
            self.image_uuid = self.manager.kernel_params['image_uuid']
            os.environ['IMAGE_UUID'] = self.image_uuid

        # Check image
        self.check_image()

        # Set Fake Parclone mode
        os.environ['CLMODE'] = 'RESTORE_IMAGE'

        # Start the image restore
        subprocess.call('yes 2>/dev/null| /usr/sbin/ocs-sr -icds -nogui -g auto -e1 auto -e2 -c -r -j2 -p true restoredisk %s sda 1>/dev/null' % self.image_uuid, shell=True)

        # Save image JSON and LOG
        current_ts = time.strftime("%Y-%m-%d %H:%M:%S")

        #image_dir = os.path.join('/home/partimag/', self.image_uuid)
        #json_path = os.path.join(image_dir, 'davosInfo.json')

        #info = json.loads(open(json_path, 'r').read())

        # RUN POST INST STEP
        self.run_postimaging()


        # Run post-imaging convergence
        self.apply_convergence()

    def setlibpostinstVars(self):
        # Setting some env vars needed by libpostinst
        os.environ['SHORTMAC'] = self.manager.mac.upper().replace(':', '')
        os.environ['MAC'] = self.manager.mac.upper()
        os.environ['HOSTNAME'] = self.manager.hostname
        os.environ['IPSERVER'] = self.manager.server

    def run_postimaging(self):
        self.setlibpostinstVars()
        subprocess.call('davos_postimaging')

    def apply_convergence(self):

        # Send the fresh restored computer inventory
        #Inventory(self.manager)

        # Waiting for machine registration
        #sleep(30000)

        rpc = self.rpc

        # Get actives convergences for host
        convergences = rpc.imaging_api.getActiveConvergenceForHost(self.manager.host_uuid)

        # If no active convergence, leave
        if not convergences:
            return

        # Get package server mirrors
        mirrors = rpc.rpc.getServerDetails()['mirror']
        mirrors = [m['mountpoint'] for m in mirrors]

        # Extract package ids
        pids = [cv['pid'] for cv in convergences]
        downloads = {pid:None for pid in pids}

        # For each pid, search corresponding mirror
        for pid in pids:
            for m in mirrors:
                try:
                    base_url = 'https://%s:9990%s_files/%s/' % (self.manager.server, m, pid)
                    res = urllib2.urlopen(base_url + 'MD5SUMS', context=rpc.ctx)
                    files = [l[32:].strip() for l in res.read().strip().split('\n')]

                    json_data = json.loads(urllib2.urlopen(base_url + 'conf.json', context=rpc.ctx).read())

                    downloads[pid] = {'mirror': m, 'files': files, 'json': json_data}
                    break
                except Exception, e:
                    self.logger.debug('Unable to locate %s in %s', pid, m)
                    self.logger.debug('Download error: %s', str(e))

        download_dir = '/mnt/__convergence__'
        self.logger.error(download_dir)

        # If download dir doesn't exist, create it
        if not os.path.isdir(download_dir):
            os.mkdir(download_dir)

        # Downloading files and put the script in local GPO (for windows)
        # For linux, we can create an init script that will be deleted after install
        # Maybe use a chroot to handle distributions differences

        __global_command = ['cd C:\\__convergence__']

        # Check if 32 or 64
        if os.path.isdir('/mnt/Program Files (x86)'):
            bash_path = '"C:\\Program Files (x86)\\Mandriva\\OpenSSH\\bin\\bash.exe"'
        else:
            bash_path = '"C:\\Program Files\\Mandriva\\OpenSSH\\bin\\bash.exe"'

        for pid, info in downloads.iteritems():
            # If no mirror found, skip this pid
            if info is None:
                self.logger.warning('Cannot get a valid mirror for package %s', pid)
                continue

            # Creating a directory for a package
            pkg_path = os.path.join(download_dir, pid)
            if not os.path.isdir(pkg_path):
                os.mkdir(pkg_path)

            # Get some info from package json
            pkg_name = info['json']['name']
            command = info['json']['commands']['command']['command']

            # Write command to a shell file
            with open(os.path.join(pkg_path, '__install.sh'), "wb") as f:
                # Add the /bin in path (by default it not on win env)
                f.write('export PATH=$PATH:/bin\n')
                f.write(command)
                __global_command.append('cd %s' % pid)
                __global_command.append('%s __install.sh' % bash_path)
                __global_command.append('timeout 1')
                __global_command.append('cd ..')

            # Download package files
            for fname in info['files']:
                try:
                    url = 'https://%s:9990%s_files/%s/%s' % (self.manager.server, info['mirror'], pid, urllib.quote(fname))

                    self.logger.info('Downloading %s file for %s package', fname, pkg_name)
                    res = urllib2.urlopen(url, context=rpc.ctx)
                    with open(os.path.join(pkg_path, fname), "wb") as f:
                        f.write(res.read())
                except Exception, e:
                    self.logger.error('Unable to download %s for %s package', fname, pkg_name)
                    self.logger.error(str(e))
                    break

        # Write global bat file
        with open(os.path.join(download_dir, '__install.bat'), "wb") as f:
            f.write('\r\n'.join(__global_command))

        # Add group policy
        #self.setlibpostinstVars()
        #libpostinstPath = '/opt/lib/libpostinst.sh'
        #subprocess.call('bash -c \'source %s; AddNewStartupGroupPolicy "C:\\%s\\__install.bat"\''
        #    % (libpostinstPath, self.image_uuid),
        #    shell=True)
        reghive = '/mnt/Windows/System32/config/SOFTWARE'
        regfile = '/usr/lib/python2.7/dist-packages/davos/o.reg'

        self.manager.runInShell('reged -I -C %(reghive)s PRE %(regfile)s' % locals())


