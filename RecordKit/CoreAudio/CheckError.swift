//
//  CheckError.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

// Print out a more human readable error message
///
/// - parameter error: OSStatus flag
///
public func CheckError(_ error: OSStatus) {
    #if os(tvOS) // No CoreMIDI
        switch error {
        case noErr:
            return
        case kAudio_ParamError:
            RKLogBrisk("Error: kAudio_ParamError \n")

        case kAUGraphErr_NodeNotFound:
            RKLogBrisk("Error: kAUGraphErr_NodeNotFound \n")

        case kAUGraphErr_OutputNodeErr:
            RKLogBrisk( "Error: kAUGraphErr_OutputNodeErr \n")

        case kAUGraphErr_InvalidConnection:
            RKLogBrisk("Error: kAUGraphErr_InvalidConnection \n")

        case kAUGraphErr_CannotDoInCurrentContext:
            RKLogBrisk( "Error: kAUGraphErr_CannotDoInCurrentContext \n")

        case kAUGraphErr_InvalidAudioUnit:
            RKLogBrisk( "Error: kAUGraphErr_InvalidAudioUnit \n")

        case kAudioToolboxErr_InvalidSequenceType :
            RKLogBrisk( "Error: kAudioToolboxErr_InvalidSequenceType ")

        case kAudioToolboxErr_TrackIndexError :
            RKLogBrisk( "Error: kAudioToolboxErr_TrackIndexError ")

        case kAudioToolboxErr_TrackNotFound :
            RKLogBrisk( "Error: kAudioToolboxErr_TrackNotFound ")

        case kAudioToolboxErr_EndOfTrack :
            RKLogBrisk( "Error: kAudioToolboxErr_EndOfTrack ")

        case kAudioToolboxErr_StartOfTrack :
            RKLogBrisk( "Error: kAudioToolboxErr_StartOfTrack ")

        case kAudioToolboxErr_IllegalTrackDestination :
            RKLogBrisk( "Error: kAudioToolboxErr_IllegalTrackDestination")

        case kAudioToolboxErr_NoSequence :
            RKLogBrisk( "Error: kAudioToolboxErr_NoSequence ")

        case kAudioToolboxErr_InvalidEventType :
            RKLogBrisk( "Error: kAudioToolboxErr_InvalidEventType")

        case kAudioToolboxErr_InvalidPlayerState :
            RKLogBrisk( "Error: kAudioToolboxErr_InvalidPlayerState")

        case kAudioUnitErr_InvalidProperty :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidProperty")

        case kAudioUnitErr_InvalidParameter :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidParameter")

        case kAudioUnitErr_InvalidElement :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidElement")

        case kAudioUnitErr_NoConnection :
            RKLogBrisk( "Error: kAudioUnitErr_NoConnection")

        case kAudioUnitErr_FailedInitialization :
            RKLogBrisk( "Error: kAudioUnitErr_FailedInitialization")

        case kAudioUnitErr_TooManyFramesToProcess :
            RKLogBrisk( "Error: kAudioUnitErr_TooManyFramesToProcess")

        case kAudioUnitErr_InvalidFile :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidFile")

        case kAudioUnitErr_FormatNotSupported :
            RKLogBrisk( "Error: kAudioUnitErr_FormatNotSupported")

        case kAudioUnitErr_Uninitialized :
            RKLogBrisk( "Error: kAudioUnitErr_Uninitialized")

        case kAudioUnitErr_InvalidScope :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidScope")

        case kAudioUnitErr_PropertyNotWritable :
            RKLogBrisk( "Error: kAudioUnitErr_PropertyNotWritable")

        case kAudioUnitErr_InvalidPropertyValue :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidPropertyValue")

        case kAudioUnitErr_PropertyNotInUse :
            RKLogBrisk( "Error: kAudioUnitErr_PropertyNotInUse")

        case kAudioUnitErr_Initialized :
            RKLogBrisk( "Error: kAudioUnitErr_Initialized")

        case kAudioUnitErr_InvalidOfflineRender :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidOfflineRender")

        case kAudioUnitErr_Unauthorized :
            RKLogBrisk( "Error: kAudioUnitErr_Unauthorized")

        default:
            RKLogBrisk("Error: \(error)")
        }
    #else
        switch error {
        case noErr:
            return
        case kAudio_ParamError:
            RKLogBrisk("Error: kAudio_ParamError \n")

        case kAUGraphErr_NodeNotFound:
            RKLogBrisk("Error: kAUGraphErr_NodeNotFound \n")

        case kAUGraphErr_OutputNodeErr:
            RKLogBrisk( "Error: kAUGraphErr_OutputNodeErr \n")

        case kAUGraphErr_InvalidConnection:
            RKLogBrisk("Error: kAUGraphErr_InvalidConnection \n")

        case kAUGraphErr_CannotDoInCurrentContext:
            RKLogBrisk( "Error: kAUGraphErr_CannotDoInCurrentContext \n")

        case kAUGraphErr_InvalidAudioUnit:
            RKLogBrisk( "Error: kAUGraphErr_InvalidAudioUnit \n")

        case kMIDIInvalidClient :
            RKLogBrisk( "kMIDIInvalidClient ")

        case kMIDIInvalidPort :
            RKLogBrisk( "Error: kMIDIInvalidPort ")

        case kMIDIWrongEndpointType :
            RKLogBrisk( "Error: kMIDIWrongEndpointType")

        case kMIDINoConnection :
            RKLogBrisk( "Error: kMIDINoConnection ")

        case kMIDIUnknownEndpoint :
            RKLogBrisk( "Error: kMIDIUnknownEndpoint ")

        case kMIDIUnknownProperty :
            RKLogBrisk( "Error: kMIDIUnknownProperty ")

        case kMIDIWrongPropertyType :
            RKLogBrisk( "Error: kMIDIWrongPropertyType ")

        case kMIDINoCurrentSetup :
            RKLogBrisk( "Error: kMIDINoCurrentSetup ")

        case kMIDIMessageSendErr :
            RKLogBrisk( "kError: MIDIMessageSendErr ")

        case kMIDIServerStartErr :
            RKLogBrisk( "kError: MIDIServerStartErr ")

        case kMIDISetupFormatErr :
            RKLogBrisk( "Error: kMIDISetupFormatErr ")

        case kMIDIWrongThread :
            RKLogBrisk( "Error: kMIDIWrongThread ")

        case kMIDIObjectNotFound :
            RKLogBrisk( "Error: kMIDIObjectNotFound ")

        case kMIDIIDNotUnique :
            RKLogBrisk( "Error: kMIDIIDNotUnique ")

        case kMIDINotPermitted:
            RKLogBrisk( "Error: kMIDINotPermitted: Have you enabled the audio background mode in your ios app?")

        case kAudioToolboxErr_InvalidSequenceType :
            RKLogBrisk( "Error: kAudioToolboxErr_InvalidSequenceType ")

        case kAudioToolboxErr_TrackIndexError :
            RKLogBrisk( "Error: kAudioToolboxErr_TrackIndexError ")

        case kAudioToolboxErr_TrackNotFound :
            RKLogBrisk( "Error: kAudioToolboxErr_TrackNotFound ")

        case kAudioToolboxErr_EndOfTrack :
            RKLogBrisk( "Error: kAudioToolboxErr_EndOfTrack ")

        case kAudioToolboxErr_StartOfTrack :
            RKLogBrisk( "Error: kAudioToolboxErr_StartOfTrack ")

        case kAudioToolboxErr_IllegalTrackDestination :
            RKLogBrisk( "Error: kAudioToolboxErr_IllegalTrackDestination")

        case kAudioToolboxErr_NoSequence :
            RKLogBrisk( "Error: kAudioToolboxErr_NoSequence ")

        case kAudioToolboxErr_InvalidEventType :
            RKLogBrisk( "Error: kAudioToolboxErr_InvalidEventType")

        case kAudioToolboxErr_InvalidPlayerState :
            RKLogBrisk( "Error: kAudioToolboxErr_InvalidPlayerState")

        case kAudioUnitErr_InvalidProperty :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidProperty")

        case kAudioUnitErr_InvalidParameter :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidParameter")

        case kAudioUnitErr_InvalidElement :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidElement")

        case kAudioUnitErr_NoConnection :
            RKLogBrisk( "Error: kAudioUnitErr_NoConnection")

        case kAudioUnitErr_FailedInitialization :
            RKLogBrisk( "Error: kAudioUnitErr_FailedInitialization")

        case kAudioUnitErr_TooManyFramesToProcess :
            RKLogBrisk( "Error: kAudioUnitErr_TooManyFramesToProcess")

        case kAudioUnitErr_InvalidFile :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidFile")

        case kAudioUnitErr_FormatNotSupported :
            RKLogBrisk( "Error: kAudioUnitErr_FormatNotSupported")

        case kAudioUnitErr_Uninitialized :
            RKLogBrisk( "Error: kAudioUnitErr_Uninitialized")

        case kAudioUnitErr_InvalidScope :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidScope")

        case kAudioUnitErr_PropertyNotWritable :
            RKLogBrisk( "Error: kAudioUnitErr_PropertyNotWritable")

        case kAudioUnitErr_InvalidPropertyValue :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidPropertyValue")

        case kAudioUnitErr_PropertyNotInUse :
            RKLogBrisk( "Error: kAudioUnitErr_PropertyNotInUse")

        case kAudioUnitErr_Initialized :
            RKLogBrisk( "Error: kAudioUnitErr_Initialized")

        case kAudioUnitErr_InvalidOfflineRender :
            RKLogBrisk( "Error: kAudioUnitErr_InvalidOfflineRender")

        case kAudioUnitErr_Unauthorized :
            RKLogBrisk( "Error: kAudioUnitErr_Unauthorized")

        default:
            RKLogBrisk("Error: \(error)")
        }
    #endif
}
