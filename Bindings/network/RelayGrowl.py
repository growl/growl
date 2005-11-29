#!/usr/bin/env python

"""Growl 0.6 Network Protocol Relay"""
__version__ = "0.6" # will always match Growl version
__author__ = "Rui Carmo (http://the.taoofmac.com)"
__copyright__ = "(C) 2004 Rui Carmo. Code under BSD License."

from PicoRendezvous import *
from netgrowl import *
from SocketServer import *
import struct, time, md5, threading, pprint

class RendezvousWatcher(threading.Thread):
  """Class to maintain an updated cache of known Growl servers"""
  def __init__(self):
    threading.Thread.__init__(self)
    self.servers = []
    self.timer = threading.Event()
    self.interval = 120.0 # no point in checking more often
  # end def

  def shutdown(self):
    self.timer.set()
  # end def

  def getServers(self):
    return self.servers
  # end def

  def run(self):
    """Main loop"""
    p = PicoRendezvous()
    while 1:
      if self.timer.isSet(): return
      self.servers = p.query('_growl._tcp.local.')
      self.timer.wait(self.interval)
  # end def
# end class


class GrowlPacket:
  """Performs basic decoding of a Growl UDP Packet."""

  def __init__(self, data, password = None):
    """Initializes and validates the packet"""
    self.valid = False
    self.data = data
    self.digest = self.data[-16:]
    checksum = md5.new()
    checksum.update(self.data[:-16])
    if password:
      checksum.update(password)
    if self.digest == checksum.digest():
      self.valid = True
  # end def

  def type(self):
    """Returns the packet type"""
    if self.data[1] == '\x01':
      return 'NOTIFY'
    else:
      return 'REGISTER'
  # end def

  def info(self):
    """Returns a subset of packet information"""
    if self.type() == 'NOTIFY':
      nlen = struct.unpack("!H",str(self.data[4:6]))[0]
      tlen = struct.unpack("!H",str(self.data[6:8]))[0]
      dlen = struct.unpack("!H",str(self.data[8:10]))[0]
      alen = struct.unpack("!H",str(self.data[10:12]))[0]
      return struct.unpack(("%ds%ds%ds%ds") % (nlen, tlen, dlen, alen), self.data[12:len(self.data)-16])
    else:
      length = struct.unpack("!H",str(self.data[2:4]))[0]
      return self.data[6:7+length]
  # end def
# end class


class GrowlRelay(UDPServer):
  """Growl Notification Relay"""
  allow_reuse_address = True

  def __init__(self, password = None):
    """Initializes the relay and launches the resolver thread"""
    self.password = password
    self.resolver = RendezvousWatcher()
    self.resolver.start()
    # depending on your architecture and number of network interfaces,
    # you might have to change the '' below.
    UDPServer.__init__(self,('', GROWL_UDP_PORT), _RequestHandler)
  # end def

  def server_close(self):
    self.resolver.shutdown()
  # end def
# end class


class _RequestHandler(DatagramRequestHandler):
  """Processes and logs each incoming notification packet"""

  # Borrowed from BaseHTTPServer for logging
  monthname = [None, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

  def log_date_time_string(self):
     """Return the current time formatted for logging."""
     now = time.time()
     year, month, day, hh, mm, ss, x, y, z = time.localtime(now)
     s = "%02d/%3s/%04d %02d:%02d:%02d" % (
        day, self.monthname[month], year, hh, mm, ss)
     return s

  def handle(self):
    """Handles each request"""
    p = GrowlPacket(self.rfile.read(),self.server.password)
    servers = self.server.resolver.getServers()
    if p.valid:
      s = socket(AF_INET, SOCK_DGRAM)
      for server in servers:
        s.sendto(p.data, (server, GROWL_UDP_PORT))
      s.close()
    else:
      servers = 'discarded'
    # Log the request and outcome
    print "%s - - [%s] %s %s %d %s" % (self.client_address[0],
      self.log_date_time_string(), p.type(), p.info(), len(p.data), servers)


if __name__== '__main__':
  r = GrowlRelay('password')
  try:
    r.serve_forever()
  except KeyboardInterrupt:
    r.server_close()