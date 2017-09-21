from insights.core.plugins import rule, make_response
from insights.parsers.hostname import Hostname

ERROR_KEY = "INSIGHTS_HEARTBEAT"
HEARTBEAT_UUID = "9cd6f607-6b28-44ef-8481-62b0e7773614"
HOST = "insights-heartbeat-" + HEARTBEAT_UUID


@rule(requires=[Hostname])
def is_insights_heartbeat(broker):
    hostname = broker[Hostname].hostname
    if hostname == HOST:
        return make_response(ERROR_KEY)