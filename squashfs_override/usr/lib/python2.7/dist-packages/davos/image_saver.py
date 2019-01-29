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

class imageSaver(object):

    def __init__(self, manager):

        self.manager = manager
        self.logger = manager.logger
        self.imaging_api = manager.rpc.imaging_api


    def start(self):

        # Get image UUID
        self.image_uuid = self.imaging_api.computerCreateImageDirectory(self.manager.mac)

        # Set Fake Parclone mode
        self.logger.debug('Setting f.clone CLMODE env var to SAVE_IMAGE')
        os.environ['CLMODE'] = 'SAVE_IMAGE'

        # Find out the device to save
        if os.path.exists('/dev/nvme0n1'):
            self.device = 'nvme0n1'
        elif os.path.exists('/dev/sda'):
            self.device = 'sda'
        elif os.path.exists('/dev/hda'):
            self.device = 'hda'

        # Start the image saver
        command = '/usr/sbin/ocs-sr --batch ' + self.manager.clonezilla_params['clonezilla_saver_params'] + ' savedisk ' + self.image_uuid + ' ' + self.device
        self.logger.info('Running command: %s', command )
        error_code = subprocess.call('%s 2>&1| tee /var/log/davos_command.log' % (command), shell=True)

        image_dir = os.path.join('/home/partimag/', self.image_uuid) + '/'

        # Save image JSON
        info = {}
        current_ts = time.strftime("%Y-%m-%d %H:%M:%S")
        info['title'] = 'Image of %s at %s' % (self.manager.hostname, current_ts)
        info['description'] = ''
        info['size'] = sum(os.path.getsize(image_dir+f) for f in os.listdir(image_dir) if os.path.isfile(image_dir+f))
        info['has_error'] = (error_code == 0)
        json_path = os.path.join(image_dir, 'davosInfo.json')
        open(json_path, 'w').write(json.dumps(info))

        # Send save img request
        self.imaging_api.imageDone(self.manager.mac, self.image_uuid)

        # Enter debug if error occurred
        if error_code != 0:
            self.manager.enterDebug()
