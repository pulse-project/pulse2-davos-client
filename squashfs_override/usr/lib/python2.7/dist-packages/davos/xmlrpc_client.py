import ssl, xmlrpclib

class pkgServerProxy(object):


    def __init__(self, ip):
        
        # Creating SSL context
        self.ctx = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
        self.ctx.verify_mode = ssl.CERT_NONE

        # Building url (dirty, port and protocol are hardcoded
        # but we are limited by grub command line max length
        # We could pass them if we upgrade to grub2
        self.base_url = "https://%s:9990/" % ip

    def __getattr__(self, attr_name):
        # Return the corresponding api proxy according to attr
        url = self.base_url + attr_name + '/'
        return xmlrpclib.ServerProxy(url, context=self.ctx)


