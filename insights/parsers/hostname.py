"""
hostname - command ``/bin/hostname``
====================================

This parser simply reads the output of ``/bin/hostname``, which is the
configured fully qualified domain name of the client system.  It then
splits it into ``hostname`` and ``domain`` and stores these as attributes,
along with the unmodified name in the ``fqdn`` attribute.

Examples:

    >>> hostname = shared[Hostname]
    >>> hostname.fqdn
    'www.example.com'
    >>> hostname.hostname
    'www'
    >>> hostname.domain
    'example.com'

"""

from .. import Parser, parser
from insights.core.serde import deserializer, serializer


@parser("hostname")
class Hostname(Parser):
    """Class for parsing ``hostname`` command output.

    Attributes:
        fqdn: The fully qualified domain name of the host. The same to
            ``hostname`` when domain part is not set.
        hostname: The hostname.
        domain: The domain get from the fqdn.
    """
    def parse_content(self, content):
        raw = None
        if len(content) == 1:
            raw = content[0].strip()
        self.fqdn = raw
        self.hostname = raw.split(".")[0] if raw else None
        self.domain = ".".join(raw.split(".")[1:]) if raw else None


@serializer(Hostname)
def serialize(obj):
    return vars(obj)


@deserializer(Hostname)
def deserialize(_type, obj):
    hostname = Hostname(None)
    for k, v in obj.items():
        setattr(hostname, k, v)
    return hostname