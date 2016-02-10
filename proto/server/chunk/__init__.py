from log import logger
import shared
import client
import engine

chunks = dict()
users = dict()

class Hash:

  hsh = '0'

  def __init__(self, hsh):
    self.hsh = hsh

  def __str__(self):
    hsh_size = 4
    return self.hsh[:hsh_size] + '...' + self.hsh[-hsh_size:]

def add_user(who, hashes: list):

    logger.debug('{} has {} chunks to register'.format(who.username, len(hashes)))

    for h in hashes:
        if h == '':
            logger.warn('{} sent invalid chunk hash'.format(who.username))
            continue
        h = Hash(h)
        register_chunk(h, who.username)
        keep_chunk_alive(who, h)

def get_chunk_owners(chk: Hash):
    if not chk in chunks:
        return []
    return [shared.climanager.get_cli(name) for name in chunks[chk]]

#TODO: add an availability flag to know if the client is available
def get_chunk_owner(chk: Hash):
    if not chk in chunks or chunks[chk] == []:
        return None
    return shared.climanager.get_cli(chunks[chk][0])

def has_user_chunk(chk: Hash, username: str):
    if not chk in chunks:
        return []
    return username in chunks[chk]

def register_chunk(chk, username: str):

    if isinstance(chk, str):
      chk = Hash(chk)

    if not chk in chunks:
        chunks[chk] = [username]
    else:
        chunks[chk].append(username)

    if not username in users:
        users[username] = [chk]
    else:
        users[username].append(chk)

    return chk


def remove_user(frm):
    if not frm.username in users:
        logger.debug('user {} has zero chunks'.format(frm.username))
        return

    for chk in users[frm.username]:
        chunks[chk].remove(frm.username)
        keep_chunk_alive(frm, chk)

    del users[frm.username]

def remove_chunk(chk: str):
    if not chk in chunks:
        logger.debug('chunk {} does not exists'.format(chk))
        return

    for user in chunks[chk]:
        users[user].remove(chk)

    del chunks[chk]

def get_redundancy(chk: str):

    if chk not in chunks:
        return 0
    return len(chunks[chk])

def dump():
    logger.debug('dump chunks:'.format(chunks))
    logger.debug('dump users:'.format(users))

def find_user_for_storing(chk: Hash):

    for u in shared.climanager.clients.keys():
        if not has_user_chunk(chk, u):
            return shared.climanager.get_cli(u)
    return None

def keep_chunk_alive(frm, chk: Hash):
    
    redundancy = get_redundancy(chk)

    REDUNDANCY_LEVEL = 3


    #TODO: do some multicast propagation for chunk hosting
    while redundancy < REDUNDANCY_LEVEL:
        engine.host_chunk(frm, chk)
        redundancy += 1
