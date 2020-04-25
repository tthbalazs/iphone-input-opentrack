/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Displays coordinate axes visualizing the tracked face pose (and eyes in iOS 12).
*/

import ARKit
import SceneKit
import Socket

extension Data {

    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}

class TransformVisualization: NSObject, VirtualContentController {
    
    var contentNode: SCNNode?
    var socket: Socket?
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // This class adds AR content only for face anchors.
        guard anchor is ARFaceAnchor else { return nil }
        	
        guard !(socket?.isConnected ?? false) else { return nil }
        
        do {
            // Create a signature...
            let signature = try Socket.Signature(protocolFamily: .inet, socketType: .datagram, proto: .udp, hostname: "172.20.10.4", port: 4242)
            socket = try Socket.create(connectedUsing: signature!)
        
        } catch let error {
            // See if it's a socket error or something else...
            guard let socketError = error as? Socket.Error else {
                
                print("Unexpected error...")
                return nil
            }
            print("Error reported: \(socketError.description)")
        }
        
        // Load an asset from the app bundle to provide visual content for the anchor.
        contentNode = SCNReferenceNode(named: "coordinateOrigin")
        
        // Provide the node to ARKit for keeping in sync with the face anchor.
        return contentNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        let calcNode = SCNNode()
        
        calcNode.simdTransform = anchor.transform
        
        let x = Double(calcNode.worldPosition.x) * 100
        let y = Double(calcNode.worldPosition.y) * 100
        let z = Double(calcNode.worldPosition.z) * 100
        
        let rotX = Double(calcNode.eulerAngles.x) * (180 / Double.pi)
        let rotY = Double(calcNode.eulerAngles.y) * (180 / Double.pi)
        let rotZ = Double(calcNode.eulerAngles.z) * (180 / Double.pi)
        
        let pos = [x, y, z, rotY, rotX, rotZ] // x, y, z, yaw, pitch, roll
        let posDatagram = Data(fromArray: pos)
                 
        do {
            try socket?.write(from: posDatagram)
        } catch let error {
            // See if it's a socket error or something else...
            guard let socketError = error as? Socket.Error else {
                
                print("Unexpected error...")
                return
            }
            
            print("Error reported: \(socketError.description)")
        }
    }
}
