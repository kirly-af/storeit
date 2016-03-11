import logging
import colorlog

formatter = colorlog.ColoredFormatter()

ch = logging.StreamHandler()

formatter = colorlog.ColoredFormatter(
                "%(log_color)s%(levelname)-8s%(reset)s %(blue)s%(message)s",
                 datefmt=None,
                 reset=True,
                 log_colors={
                    'DEBUG':    'cyan',
                    'INFO':     'green',
                    'WARNING':  'yellow',
                    'ERROR':    'red',
                    'CRITICAL': 'red,bg_white',
                 },
                 secondary_log_colors={},
                 style='%'
)

ch.setFormatter(formatter)

logger = logging.getLogger('storeit')
logger.addHandler(ch)


def nomore(s):
    MAX = 80

    if len(s) > MAX:
        appended = ' [...]'

        if isinstance(s, bytes):
            appended = appended.encode()

        return s[:MAX] + appended

    return s