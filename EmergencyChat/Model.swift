//
//  Model.swift
//  EmergencyChat
//
//  Created by Bintang Pradana on 15/01/24.
//

import Foundation
import MultipeerConnectivity

struct Message: Codable, Hashable {
    let text: String
    let from: Person
    let id: UUID
    
    init(text: String, from: Person) {
        self.text = text
        self.from = from
        self.id = UUID()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

struct Person: Codable, Hashable, Equatable {
    let name: String
    let id: UUID
    
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    init(_ peer: MCPeerID, id: UUID) {
        self.name = peer.displayName
        self.id = id
    }
}

struct Chat: Equatable {
    var id: UUID = UUID()
    var messages: [Message] = []
    var peer: MCPeerID
    var person: Person
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PeerInfo: Codable {
    enum PeerInfoType: Codable {
        case Person
    }
    
    var peerInfoType: PeerInfoType = .Person
}

struct ConnectMessage: Codable {
    enum MessageType: Codable {
        case Message
        case PeerInfo
    }
    
    var messageType: MessageType = .Message
    var peerInfo: Person? = nil
    var message: Message? = nil
}

class Model: NSObject, ObservableObject {
    private let serviceType: String = "EmergencyApp"
    private let myPeerID: MCPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var chats: Dictionary<Person, Chat> = [:]
    
    var myPerson: Person
    
    override init() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        myPerson = Person(self.session.myPeerID, id: UIDevice.current.identifierForVendor!)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    func newMessage(message: Message, from: MCPeerID) {
        print("new message: \(message.text)")
        
        chats[message.from]!.messages.append(message)
    }
    
    func newPerson(person: Person, from: MCPeerID) {
        print("new person: \(person.name)")
        
        chats[person] = Chat(peer: from, person: person)
    }
    
    func send(_ message: String, chat: Chat) {
        print("send: \(message) to: \(chat.peer.displayName)")
        
        DispatchQueue.main.async {
            let newMessage = ConnectMessage(messageType: .Message, message: Message(text: message, from: self.myPerson))
            
            if !self.session.connectedPeers.isEmpty {
                do {
                    if let data = try? self.encoder.encode(newMessage) {
                        DispatchQueue.main.async {
                            self.chats[chat.person]?.messages.append(newMessage.message!)
                        }
                        try self.session.send(data, toPeers: [chat.peer], with: .reliable)
                    }
                } catch {
                    print("error send message: \(String(describing: error))")
                }
            }
        }
    }
    
    func receive(message: ConnectMessage, from: MCPeerID) {
        print("receive info: \(message.messageType)")
        
        if (message.messageType == .Message) {
            newMessage(message: message.message!, from: from)
        }
        if (message.messageType == .PeerInfo) {
            newPerson(person: message.peerInfo!, from: from)
        }
    }
    
    func connect(peer: MCPeerID) {
        print("connect: \(peer.displayName)")
        
        DispatchQueue.main.async {
            let newMessage = ConnectMessage(messageType: .PeerInfo, peerInfo: self.myPerson)
            do {
                if let data = try? self.encoder.encode(newMessage) {
                    try self.session.send(data, toPeers: [peer], with: .reliable)
                }
            } catch {
                print("error connect: \(String(describing: error))")
            }
        }
    }
}

extension Model: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("ServiceAdvertiser didReceiveInvitationFromPeer: \(peerID)")
        DispatchQueue.main.async {
            invitationHandler(true, self.session)
        }
        
    }
}

extension Model: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("ServiceBrowser foundPeer: \(peerID)")
        DispatchQueue.main.async {
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("ServiceBrowser lostPeer: \(peerID)")
    }
}

extension Model: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.rawValue)")
        DispatchQueue.main.async {
            if(state == .connected){
                self.connect(peer:peerID)
            }
            self.connectedPeers = session.connectedPeers
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceive bytes \(data.count) bytes")
        if let message = try? decoder.decode(ConnectMessage.self, from: data) {
            DispatchQueue.main.async {
                self.receive(message: message, from: peerID)
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Receiving streams is not supported")
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Receiving resources is not supported")
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Receiving resources is not supported")
    }
}
