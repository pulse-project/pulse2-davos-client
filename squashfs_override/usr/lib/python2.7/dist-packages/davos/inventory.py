#!/usr/bin/env python
# -*- coding: utf-8 -*-
import time
import urllib2
from xml.dom.minidom import parse
import tftpy
import psutil
import fcntl
import socket
import struct


class Inventory(object):
    
    def __init__(self, manager):
        self.logger = manager.logger
        self.manager = manager
        self.disk = 'sda'
        self.logger.info('Running inventory')
        o, e, ec = manager.runInShell('fusioninventory-agent --local /tmp --no-category=software,user,process,environment,network,controller,memory,drive,usb,slot,input')
        o2, e2, ec = manager.runInShell('mv /tmp/*.ocs /tmp/inventory.xml')

        # Check if an error occured
        if ec != 0:
            manager.logger.error("Can't find inventory XML file")
            manager.logger.error("%s\n%s", o, e)
            return

        # Loading XMLFile
        self.dom = dom = parse('/tmp/inventory.xml')

        # Replace ARCHNAME, OSNAME and OSCOMMENTS
        self.editNodeText('ARCHNAME', 'davos-imaging-diskless-env')
        self.editNodeText('OSNAME', 'Unknown operating system (PXE network boot inventory)')
        self.editNodeText('FULL_NAME', 'Unknown operating system (PXE network boot inventory)')
        timestamp = time.ctime()
        self.editNodeText('OSCOMMENTS', 'Inventory generated on ' + timestamp)

        # If we have a detected OS, we inventory OS and SOFT
        #if self.OS:
        #   getattr(self, self.OS + 'Handler').__call__()

        # Find mac address of connected interface
        pnic = psutil.net_io_counters(pernic=True)
        stats = {}
        for nicname in list(pnic.keys()):
            stats[nicname] = pnic[nicname].bytes_sent
        self.interface = max(stats, key=stats.get)
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        info = fcntl.ioctl(sock.fileno(), 0x8927,  struct.pack('256s', self.interface[:15]))
        self.macaddress = ':'.join(['%02x' % ord(char) for char in info[18:24]])
        self.ipaddress = socket.inet_ntoa(fcntl.ioctl(sock.fileno(), 0x8915, struct.pack('256s', self.interface[:15]))[20:24])
        self.netmask = socket.inet_ntoa(fcntl.ioctl(sock.fileno(), 0x891b, struct.pack('256s', self.interface))[20:24])

        # Add the connected network interface
        self.addNetwork()

        # Exporting XML
        data = dom.toxml()

        # Copy file to inventories folder on tftp server
        self.logger.info('Uploading inventory to Pulse server')
        filehandler = open('/tmp' + self.macaddress + '.xml', 'w')
        filehandler.write(data)
        filehandler.close()
        tftpclient = tftpy.TftpClient(manager.tftp_ip, 69)
        tftpclient.upload('/' + manager.dump_path + '/' + self.macaddress + '.xml', '/tmp' + self.macaddress + '.xml')


    @property
    def OS(self):
        # A dirty OS detector but ... we don't have time
        win, e, ec = self.manager.runInShell('find /mnt -maxdepth 1 -type d -iname windows')
        etc, e, ec = self.manager.runInShell('find /mnt -maxdepth 1 -type d -iname etc')
        disk_info, e, ec = self.manager.runInShell('fdisk /dev/%s -l', self.disk)
        
        # If we get a result, it's a windows
        if win.strip() and 'NTFS' in disk_info:
            return 'windows'
        elif etc.strip() and 'Linux' in disk_info:
            return 'linux'
        else:
            return ''

    def windowsHandler(self):
        # For windows case, we read first CurrentVersion info
        from Registry import Registry
        reg = Registry.Registry('/mnt/Windows/System32/config/SOFTWARE')

        # ======== OS SECTION ===============================================

        cv_dict = {}
        for entry in reg.open('Microsoft\\Windows NT\\CurrentVersion').values():
            cv_dict[entry.name()] = entry.value()

        if 'ProductName' in cv_dict:
            self.editNodeText('OSNAME', 'Microsoft ' + cv_dict['ProductName'])
            self.editNodeText('FULL_NAME', 'Microsoft ' + cv_dict['ProductName'])

        if 'CSDVersion' in cv_dict:
            self.editNodeText('OSCOMMENTS', cv_dict['CSDVersion'])
            self.editNodeText('SERVICE_PACK', cv_dict['CSDVersion'], 'OPERATINGSYSTEM')

        if 'CurrentVersion' in cv_dict and 'CurrentBuild' in cv_dict:
            self.editNodeText('OSVERSION', cv_dict['CurrentVersion'] + '.' + cv_dict['CurrentBuild'])
            self.editNodeText('KERNEL_VERSION', '6.1.7601')

        self.editNodeText('KERNEL_NAME', 'MSWin32')
        self.editNodeText('NAME', 'Windows', 'OPERATINGSYSTEM')
        self.editNodeText('PUBLISHER', 'Microsoft Corporation', 'OPERATINGSYSTEM')

        if 'BuildLabEx' in cv_dict and 'amd64' in cv_dict['BuildLabEx']:
            self.editNodeText('ARCH', '64-bit', 'OPERATINGSYSTEM')
        else:
            self.editNodeText('ARCH', '32-bit', 'OPERATINGSYSTEM')
           
        # ======== SOFTWARE SECTION =========================================

        soft_keys = reg.open('Microsoft\\Windows\\CurrentVersion\\Uninstall').subkeys()
        soft_keys+= reg.open('Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall').subkeys()
        
        for key in soft_keys:
            soft_dict = {}
            for entry in key.values():
                try:
                    soft_dict[entry.name()] = entry.value().encode('ascii', 'ignore')
                except:
                    soft_dict[entry.name()] = entry.value()
            
            soft = {}
            soft['ARCH'] = 'x86_64'
            soft['FROM'] = 'registry'
            soft['GUID'] = key.name()

            if 'HelpLink' in soft_dict:
                soft['HELPLINK'] = soft_dict['HelpLink']

            if 'DisplayName' in soft_dict:
                soft['NAME'] = soft_dict['DisplayName']
            else:
                continue

            if 'Publisher' in soft_dict:
                soft['PUBLISHER'] = soft_dict['Publisher']

            if 'UninstallString' in soft_dict:
                soft['UNINSTALL_STRING'] = soft_dict['UninstallString']

            if 'DisplayVersion' in soft_dict:
                soft['VERSION'] = soft_dict['DisplayVersion']

            if 'URLInfoAbout' in soft_dict:
                soft['URL_INFO_ABOUT'] = soft_dict['URLInfoAbout']
        
            self.addSoftware(soft)



    def linuxHandler(self):
        pass

    def addSoftware(self, data):
        cont = self.dom.getElementsByTagName('CONTENT')[0]
        softnode = self.dom.createElement('SOFTWARES')
        for k in ['ARCH', 'FROM', 'GUID', 'NAME', 'PUBLISHER', 'UNINSTALL_STRING', 'URL_INFO_ABOUT', 'VERSION']:
            if not k in data:
                continue
            elem = self.dom.createElement(k)
            txt = self.dom.createTextNode(data[k])
            elem.appendChild(txt)
            softnode.appendChild(elem)
        cont.appendChild(softnode)

    def addNetwork(self):
        cont = self.dom.getElementsByTagName('CONTENT')[0]

        new_networks = self.dom.createElement('NETWORKS')

        new_description = self.dom.createElement('DESCRIPTION')
        descriptiontxt = self.dom.createTextNode(self.interface)
        new_description.appendChild(descriptiontxt)

        new_macaddr = self.dom.createElement('MACADDR')
        macaddrtxt = self.dom.createTextNode(self.macaddress)
        new_macaddr.appendChild(macaddrtxt)

        new_ipaddress = self.dom.createElement('IPADDRESS')
        ipaddresstxt = self.dom.createTextNode(self.ipaddress)
        new_ipaddress.appendChild(ipaddresstxt)

        new_ipmask = self.dom.createElement('IPMASK')
        ipmasktxt = self.dom.createTextNode(self.netmask)
        new_ipmask.appendChild(ipmasktxt)

        new_status = self.dom.createElement('STATUS')
        statustxt = self.dom.createTextNode('Up')
        new_status.appendChild(statustxt)

        new_type = self.dom.createElement('TYPE')
        typetxt = self.dom.createTextNode('ethernet')
        new_type.appendChild(typetxt)

        new_virtualdev = self.dom.createElement('VIRTUALDEV')
        virtualdevtxt = self.dom.createTextNode('0')
        new_virtualdev.appendChild(virtualdevtxt)

        new_networks.appendChild(new_description)
        new_networks.appendChild(new_macaddr)
        new_networks.appendChild(new_ipaddress)
        new_networks.appendChild(new_ipmask)
        new_networks.appendChild(new_status)
        new_networks.appendChild(new_type)
        new_networks.appendChild(new_virtualdev)

        cont.appendChild(new_networks)

    def editNodeText(self, nodename, value, parent=None):
        if parent is None:
            parent = self.dom
        else:
            parent = self.dom.getElementsByTagName(parent)[0]
        try:
            node = parent.getElementsByTagName(nodename)[0]
            node.firstChild.replaceWholeText(value)
        except:
            self.logger.warning('Cannot set %s to %s', nodename, value)

