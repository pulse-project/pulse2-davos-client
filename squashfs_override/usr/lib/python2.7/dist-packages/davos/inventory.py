#!/usr/bin/env python
# -*- coding: utf-8 -*-
import time
import urllib2
from xml.dom.minidom import parse


class Inventory(object):
    
    def __init__(self, manager):
        self.logger = manager.logger
        self.manager = manager
        self.disk = 'sda'
        o, e, ec = manager.runInShell('fusioninventory-agent --local /tmp --no-category=software,user,process,environment')
        o2, e2, ec = manager.runInShell('mv /tmp/*.ocs /tmp/inventory.xml')
        
        # Check if an error occured
        if ec != 0:
            manager.logger.error("Can't find inventory XML file")
            manager.logger.error("%s\n%s", o, e)
            return

        # Loading XMLFile
        self.dom = dom = parse('/tmp/inventory.xml')

        # Remove somes tags
        for tag in ['DRIVES']:
            for element in dom.getElementsByTagName(tag):
                element.parentNode.removeChild(element)

        self.editNodeText('ARCHNAME', 'davos-imaging-diskless-env')
        
        # If we have a detected OS, we inventory OS and SOFT
        if self.OS:
           getattr(self, self.OS + 'Handler').__call__()
        
        # Exporting XML
        data = dom.toxml()

        # Sending inventory
        req = urllib2.Request('http://%s:9999/' % manager.server, data, {'Content-Type': 'application/xml'})
        response = urllib2.urlopen(req)


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

