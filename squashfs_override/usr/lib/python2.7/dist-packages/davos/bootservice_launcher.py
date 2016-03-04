# -*- coding: utf-8; -*-
#
# (c) 2015-2016 Siveo, http://www.siveo.net
#
# $Id$
#
# This file is part of Pulse 2, http://www.siveo.net/solutions/pulse/
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
#

import os
import subprocess

class bootserviceLauncher(object):

    image_uuid = None

    def __init__(self, manager):

        self.manager = manager


    def start(self):

        # Get Script
        self.bootservice_script = self.manager.kernel_params['bootservice_script']
        os.environ['BOOTSERVICE_SCRIPT'] = self.bootservice_script

        # Run bootservice script
        self.run_script()

    def setlibpostinstVars(self):
        # Setting some env vars needed by libpostinst
        os.environ['SHORTMAC'] = self.manager.mac.upper().replace(':', '')
        os.environ['MAC'] = self.manager.mac.upper()
        os.environ['HOSTNAME'] = self.manager.hostname
        os.environ['IPSERVER'] = self.manager.server

    def run_script(self):
        self.setlibpostinstVars()
        subprocess.call('davos_bootservice')
        


