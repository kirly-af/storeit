//
//  WebSocketManager.swift
//  StoreIt
//
//  Created by Romain Gjura on 03/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation
import Starscream
import ObjectMapper

class WebSocketManager {
    
    let url: NSURL
    let ws: WebSocket
    let navigationManager: NavigationManager
    
    var uidFactory: UidFactory

    var list: UITableView?
    
    init(host: String, port: Int, uidFactory: UidFactory, navigationManager: NavigationManager) {
        self.url = NSURL(string: "ws://\(host):\(port)/")!
        self.ws = WebSocket(url: url)
        self.navigationManager = navigationManager
        self.uidFactory = uidFactory
        self.list = nil
    }
    
    func getTableView() -> UITableView? {
        // TODO: find a maybe better way to get StoreItSynchDirectoryView
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let mainNavigationController = appDelegate.window?.rootViewController as! UINavigationController
        let tabBarController = mainNavigationController.viewControllers[1] as! UITabBarController
        let navigationController = tabBarController.viewControllers![0] as! UINavigationController
        let listView = navigationController.viewControllers[0] as! StoreItSynchDirectoryView
        
        return listView.list
    }
    
    func updateListView() {
        if self.list == nil {
            self.list = self.getTableView()
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.list?.reloadData()
        }
    }
    
    func eventsInitializer(loginFunction: () -> Void, logoutFunction: () -> Void) {
        self.ws.onConnect = {
        	print("[Client.WebSocketManager] WebSocket is connected to \(self.url)")
            loginFunction()
        }

        self.ws.onDisconnect = { (error: NSError?) in
        	print("[Client.WebSocketManager] Websocket is disconnected from \(self.url) with error: \(error?.localizedDescription)")
            logoutFunction()
        }
                
        self.ws.onText = { (request: String) in
            print("[Client.WebSocketManager] Client recieved a request : \(request)")

            let cmdInfos = CommandInfos()
            
            if let command: ResponseResolver = Mapper<ResponseResolver>().map(request) {
                if (command.command == cmdInfos.RESP) {
                    
                    // SEREVR HAS RESPONDED
                    if let response: Response = Mapper<Response>().map(request) {
                        
                        // JOIN RESPONSE
                        if (response.text == cmdInfos.JOIN_RESPONSE_TEXT) {
                            if let params = response.parameters {
                                let home: File? = params["home"]
                                
                                if let files = home?.files {
                                    self.navigationManager.setItems(files)
                                    self.updateListView()
                                }
                            }
                        }
                            
                        // SUCCESS CMD RESPONSE
                        else if (response.text == cmdInfos.SUCCESS_TEXT) {
                            let uid = response.commandUid

                            if (self.uidFactory.isWaitingForReponse(uid)) {
                                
                                let commandType = self.uidFactory.getCommandNameForUid(uid)

                                // FADD
                                if (commandType == cmdInfos.FADD) {
                                    let files = self.uidFactory.getObjectForUid(uid) as! [File]
                                    
                                    for file in files {
                                        self.navigationManager.insertFileObject(file)
                                        self.updateListView()
                                    }
                                }
                                
                            }
                        }
                        
                        // ERROR CMD RESPONSE
                        // TODO
                    }
                }
                    
                // Server sent a command (FADD, FUPT, FDEL)
                else if (cmdInfos.SERVER_TO_CLIENT_CMD.contains(command.command)) {
                    if (command.command == "FDEL") {
                        let _: Command? = Mapper<Command<FdelParameters>>().map(request)
                        
                    } else if (command.command == "FMOV") {
                        let _: Command? = Mapper<Command<FmovParameters>>().map(request)
                    } else {
                        let _: Command? = Mapper<Command<DefaultParameters>>().map(request)
                    }
                }
                    
                // We don't know what the server wants
                else {
                    print("[Client.Client.WebSocketManager] Request cannot be processed")
                }
            }
            
        }
        
        self.ws.onData = { (data: NSData) in
            print("[Client.WebSocketManager] Client recieved some data: \(data.length)")
        }
        
        self.ws.connect()
    }
    
    func sendRequest(request: String, completion: (() -> ())?) {
        if (self.ws.isConnected) {
            print("[WSManager] request is sending... : \(request)")
            self.ws.writeString(request, completion: completion)
        } else {
            print("[Client.WebSocketManager] Client can't send request \(request) to \(url), WS is disconnected")
        }
    }

}