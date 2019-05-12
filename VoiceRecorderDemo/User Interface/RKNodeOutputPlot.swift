//
//  RKNodeOutputPlot.swift
//  RecordKitUI
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 RecordKit. All rights reserved.
//
import RecordKit

extension Notification.Name {
    static let IAAConnected = Notification.Name(rawValue: "IAAConnected")
    static let IAADisconnected = Notification.Name(rawValue: "IAADisconnected")
}

/// Plot the output from any node in an signal processing graph
@IBDesignable
open class RKNodeOutputPlot: EZAudioPlot {

    public var isConnected = false

    internal func setupNode(_ input: RKNode?) {
        if !isConnected {
            input?.avAudioUnitOrNode.installTap(
                onBus: 0,
                bufferSize: bufferSize,
                format: nil) { [weak self] (buffer, _) in

                    guard let strongSelf = self else {
                        print("Unable to create strong reference to self")
                        return
                    }
                    buffer.frameLength = strongSelf.bufferSize
                    let offset = Int(buffer.frameCapacity - buffer.frameLength)
                    if let tail = buffer.floatChannelData?[0] {
                        strongSelf.updateBuffer(&tail[offset], withBufferSize: strongSelf.bufferSize)
                    }
            }
        }
        isConnected = true
    }

    // Useful to reconnect after connecting to Audiobus or IAA
    @objc func reconnect() {
        pause()
        resume()
    }

    @objc open func pause() {
        if isConnected {
            node?.avAudioUnitOrNode.removeTap(onBus: 0)
            isConnected = false
        }
    }

    @objc open func resume() {
        setupNode(node)
    }

    private func setupReconnection() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reconnect),
                                               name: .IAAConnected,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reconnect),
                                               name: .IAADisconnected,
                                               object: nil)
    }

    internal var bufferSize: UInt32 = 1_024

    /// The node whose output to graph
    @objc open var node: RKNode? {
        willSet {
            pause()
        }
        didSet {
            resume()
        }
    }

    deinit {
        node?.avAudioUnitOrNode.removeTap(onBus: 0)
    }

    /// Required coder-based initialization (for use with Interface Builder)
    ///
    /// - parameter coder: NSCoder
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNode(RecordKit.output)
        setupReconnection()
    }

    /// Initialize the plot with the output from a given node and optional plot size
    ///
    /// - Parameters:
    ///   - input: RKNode from which to get the plot data
    ///   - width: Width of the view
    ///   - height: Height of the view
    ///
    @objc public init(_ input: RKNode? = RecordKit.output, frame: CGRect = CGRect.zero, bufferSize: Int = 1_024) {
        super.init(frame: frame)
        self.plotType = .buffer
        self.backgroundColor = UIColor.white
        self.shouldCenterYAxis = true
        self.bufferSize = UInt32(bufferSize)

        setupNode(input)
        self.node = input
        setupReconnection()
    }
}
