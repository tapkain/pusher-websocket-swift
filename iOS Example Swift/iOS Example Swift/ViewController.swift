//
//  ViewController.swift
//  iOS Example
//

import UIKit
import PusherSwift

class ViewController: UIViewController, PusherDelegate {
    var pusher: Pusher! = nil
    let decoder = JSONDecoder()

    @IBAction func connectButton(_ sender: AnyObject) {
        pusher.connect()
    }

    @IBAction func disconnectButton(_ sender: AnyObject) {
        pusher.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Only use your secret here for testing or if you're sure that there's
        // no security risk
//        let pusherClientOptions = PusherClientOptions(authMethod: .inline(secret: "YOUR_APP_SECRET"))
//        pusher = Pusher(key: "YOUR_APP_KEY", options: pusherClientOptions)

//        // Use this if you want to try out your auth endpoint
//        let optionsWithEndpoint = PusherClientOptions(
//            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
//        )
//        pusher = Pusher(key: "YOUR_APP_KEY", options: optionsWithEndpoint)

        // Use this if you want to try out your auth endpoint (deprecated method)

        pusher.delegate = self

        pusher.connect()

        // bind to all events globally
        let _ = pusher.bind(eventCallback: { (event: PusherEvent) in
            var message = "Received event: '\(event.eventName)'"

            if let channel = event.channelName {
                message += " on channel '\(channel)'"
            }
            if let userId = event.userId {
                message += " from user '\(userId)'"
            }
            if let data = event.data {
                message += " with data '\(data)'"
            }

            print(message)
        })

        // subscribe to a channel
        let myChannel = pusher.subscribe("my-channel")

        // bind a callback to event "my-event" on that channel
        let _ = myChannel.bind(eventName: "my-event", eventCallback: { (event: PusherEvent) in

            // convert the data string to type data for decoding
            guard let json: String = event.data,
                let jsonData: Data = json.data(using: .utf8)
            else {
                print("Could not convert JSON string to data")
                return
            }

            // decode the event data as json into a DebugConsoleMessage
            let decodedMessage = try? self.decoder.decode(DebugConsoleMessage.self, from: jsonData)
            guard let message = decodedMessage else {
                print("Could not decode message")
                return
            }

            print("\(message.name) says \(message.message)")
        })

        // callback for member added event
        let onMemberAdded = { (member: PusherPresenceChannelMember) in
            print(member)
        }

        // subscribe to a presence channel
        let chan = pusher.subscribe("presence-channel", onMemberAdded: onMemberAdded)

        // triggers a client event on that channel
        chan.trigger(eventName: "client-test", data: ["test": "some value"])
    }

    // PusherDelegate methods

    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // print the old and new connection states
        print("old: \(old.stringValue()) -> new: \(new.stringValue())")
    }

    func subscribedToChannel(name: String) {
        print("Subscribed to \(name)")
    }

    func debugLog(message: String) {
        print(message)
    }

    func receivedError(error: PusherError) {
        if let code = error.code {
            print("Received error: (\(code)) \(error.message)")
        } else {
            print("Received error: \(error.message)")
        }
    }
}


class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        var request = URLRequest(url: URL(string: "http://localhost:9292/pusher/auth")!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: String.Encoding.utf8)
        return request
    }
}

struct DebugConsoleMessage: Codable {
    let name: String
    let message: String
}
