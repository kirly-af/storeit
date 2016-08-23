DAEMON_PATH = '../desktop-app'
global.STOREIT_RELATIVE_PATH = DAEMON_PATH
(require 'dotenv').config path: "#{DAEMON_PATH}/.env"

electron = require 'electron'
{app} = electron
ipc = electron.ipcMain

logger = (require '../lib/log').logger
StoreItClient = (require "../#{DAEMON_PATH}/build/client").default
global.settings = (require "../#{DAEMON_PATH}/build/settings").default

global.daemon = new StoreItClient

display = null
mainWin = null
loadPage = (page) ->
  unless mainWin?
    mainWin = new electron.BrowserWindow
      width: display.size.width
      height: display.size.height
    mainWin.on 'closed', -> mainWin = null
  mainWin.loadURL "file://#{__dirname}/../index.html?p=#{page or ''}"
  mainWin.openDevTools()

authWin = null
auth = (authType) ->
  authWin = new electron.BrowserWindow
    parent: mainWin
    modal: true
    show: settings.getAuthType() == null
    webPreferences:
      nodeIntegration: false
  authWin.on 'closed', -> authWin = null
  daemon.auth(authType, authWin.loadURL.bind(authWin))
    .then ->
      authWin.close()
    .catch (e) ->
      authWin.close()

tray = null
init = ->
  display = electron.screen.getPrimaryDisplay()
  tray = new electron.Tray "#{__dirname}/../assets/images/icon.png"
  tray.setToolTip 'StoreIt'

  tray.setContextMenu electron.Menu.buildFromTemplate [
    {label: 'Settings', click: -> loadPage 'settings'}
    {label: 'Statistics', click: -> loadPage 'stats'} #TODO
    {label: 'Logout', click: -> daemon.logout()} #TODO
    {type: 'separator'}
    {label: 'Restart', click: -> daemon.restart()} #TODO
    {label: 'Quit', click: -> app.quit() }
  ]
  daemon.connect().then -> loadPage()

ipc.on 'auth', (ev, authType) ->
  auth(authType)
    .then -> ev.sender.send 'auth', 'done'
    .catch -> ev.sender.send 'auth', 'done'

ipc.on 'reload', (ev) -> # daemon.restart() #TODO

app.on 'ready', -> init()
app.on 'activate', -> init() unless mainWin?
