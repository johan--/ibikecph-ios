//
//  InstructionTextToSpeechSynthesizer.swift
//  I Bike CPH
//

//import AVFoundation.AVAudioSession
import AVFoundation.AVSpeechSynthesis

class InstructionTextToSpeechSynthesizer: TextToSpeechSynthesizer {

    static let sharedInstance = InstructionTextToSpeechSynthesizer()
    
    var hasReachedDestination: Bool = false
    private var lastSpokenTurnInstruction: String = ""
    private var previousDistanceToNextTurn: Int = Int.max
    private var hasSpokenDestination: Bool = false
    var routeComposite: RouteComposite? {
        didSet {
            self.hasReachedDestination = false
            self.hasSpokenDestination = false
            self.lastSpokenTurnInstruction = ""
            self.previousDistanceToNextTurn = Int.max
            self.updateBackgroundLocationsAllowance()
            self.updateSpeechAllowance()
            
            // Speak destination and first instruction
            self.speakDestination()
            self.speakTurnInstruction()
        }
    }
    
    func speakDestination() {
        if let destination = self.routeComposite?.to {
            let destinationName = (destination.name.containsString(destination.street)) ? destination.street + " " + destination.number : destination.name
            let stringToBeSpoken = String.init(format: "read_aloud_enabled".localized, destinationName)
            self.speakString(self.replaceSubstrings(stringToBeSpoken))
        }
    }
    
    func speakRecalculatingRoute() {
        let stringToBeSpoken = "read_aloud_recalculating_route".localized
        self.speakString(stringToBeSpoken)
    }
    
    func speakTurnInstruction() {
        guard let routeComposite = self.routeComposite,
                  instructions = self.routeComposite?.currentRoute?.turnInstructions.copy() as? [SMTurnInstruction],
                  instruction = instructions.first else {
            return
        }
        
        var nextTurnInstruction = self.replaceSubstrings(instruction.fullDescriptionString)
        let metersToNextTurn = Int(instruction.lengthInMeters)
        let minimumDistanceBeforeTurn: Int = 75
        let distanceDelta: Int = 500
        let onPublicTransport = instruction.routeType != .Bike && instruction.routeType != .Walk
        
        if (self.lastSpokenTurnInstruction != nextTurnInstruction) {
            // The turn instruction has changed
            self.previousDistanceToNextTurn = Int.max
            if metersToNextTurn < minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.speakString(nextTurnInstruction)
            } else {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                
                nextTurnInstruction = String(format:"read_aloud_upcoming_instruction".localized + ", \(nextTurnInstruction)",instruction.roundedDistanceToNextTurn, "unit_metres".localized)
                self.speakString(nextTurnInstruction)
            }
        } else {
            // The turn instruction is the same as before
            if metersToNextTurn < minimumDistanceBeforeTurn && self.previousDistanceToNextTurn >= minimumDistanceBeforeTurn {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                self.speakString(nextTurnInstruction)
            } else if self.previousDistanceToNextTurn - metersToNextTurn >= distanceDelta && !onPublicTransport {
                self.lastSpokenTurnInstruction = nextTurnInstruction
                self.previousDistanceToNextTurn = metersToNextTurn
                
                let (hours, minutes) = self.hoursAndMinutes(routeComposite.durationLeft)
                var encouragement: String
                let hoursString = (hours == 1) ? "unit_h_long_singular".localized : "unit_h_long".localized
                let minutesString = (minutes == 1) ? "unit_m_long_singular".localized : "unit_m_long".localized
                if hours > 0 {
                    encouragement = "read_aloud_encouragement_time_h_m".localized
                    encouragement = String(format: encouragement, String(hours), hoursString, String(minutes), minutesString)
                } else {
                    encouragement = "read_aloud_encouragement_time_m".localized
                    encouragement = String(format: encouragement, String(minutes), minutesString)
                }
                self.speakString(encouragement)
            }
        }
    }
    
    private let calendar = NSCalendar.currentCalendar()
    private let unitFlags: NSCalendarUnit = [.Hour, .Minute]
    private func hoursAndMinutes(seconds: NSTimeInterval) -> (hour: Int, minutes: Int) {
        let rounded = round(seconds/60)*60 // Round to minutes
        let components = calendar.components(unitFlags, fromDate: NSDate(), toDate: NSDate(timeIntervalSinceNow: rounded), options: NSCalendarOptions(rawValue: 0))
        let hours = components.hour
        let minutes = components.minute
        return (hours, minutes)
    }
    
    private func replaceSubstrings(string: String) -> String {
        let mutatedString = string.stringByReplacingOccurrencesOfString(" st.", withString: " station")
        return mutatedString
    }
    
    override func speakString(string: String) {
        if !Settings.sharedInstance.readAloud.on {
            // Reading aloud is not enabled
            return
        }
        if self.hasReachedDestination {
            // Do not speak anymore after destination has been reached
            return
        }
        if self.hasRemainingSpeech && self.hasSpokenDestination {
            self.stopSpeaking()
        }
        super.speakString(string)
    }
    
    override init () {
        super.init()
        self.setupSettingsObserver()
    }
    
    deinit {
        self.unobserve()
    }
    
    private var observerTokens = [AnyObject]()
    private func unobserve() {
        for observerToken in self.observerTokens {
            NotificationCenter.unobserve(observerToken)
        }
        NotificationCenter.unobserve(self)
    }
    
    private func setupSettingsObserver() {
        self.observerTokens.append(NotificationCenter.observe(settingsUpdatedNotification) { [weak self] notification in
            self?.updateSpeechAllowance()
        })
    }
    
    private func updateSpeechAllowance() {
        if self.routeComposite != nil && Settings.sharedInstance.readAloud.on {
            self.enableSpeech(true)
        } else {
            self.enableSpeech(false)
        }
    }
    
    private func updateBackgroundLocationsAllowance() {
        if self.routeComposite != nil && Settings.sharedInstance.readAloud.on {
            SMLocationManager.sharedInstance().allowsBackgroundLocationUpdates = true
        } else {
            SMLocationManager.sharedInstance().allowsBackgroundLocationUpdates = false
        }
    }
    
    override func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        super.speechSynthesizer(synthesizer, didFinishSpeechUtterance: utterance)
        self.hasSpokenDestination = true
    }
}