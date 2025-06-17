//
//  BodyDetection.swift
//  C4_GymPose
//
//  Created by Richie Reuben Hermanto on 17/06/25.
//

import SwiftUI
import Vision
import PhotosUI

struct PoseClassificationResult {
    let isPoseCorrect: Bool
    let confidence: Float
    let feedback: String
    let detectedJoints: [String: Bool]
}

struct BodyDetection: View {
    @State private var selectedImage = BodyPoseData()
    
    var body : some View {
        VStack{
            if selectedImage.image == nil {
                
                Text("Choose a image File to analyze the labels")
                EmptyImagePicker(selectedImage: $selectedImage)
            }else {
                    Button("Replace Image", action: {
                        selectedImage = BodyPoseData()
                    })
                DisplayImages(selectedImage: $selectedImage)
            }

            Spacer()
        }
    }
    
}

fileprivate struct EmptyImagePicker: View {
    @State private var showImagePicker = false
    @State var selectedItems: [PhotosPickerItem] = []
    @Binding var selectedImage: BodyPoseData
    
    func onPickerImageChangeHandler(images: [PhotosPickerItem])  {
        
        print("Start to init the Image" + "\(images.count)")
        Task{
            for pickedImage in images {
                if let image = try? await pickedImage.loadTransferable(type: Data.self){
                    let processResult = try await processImage(image: image)
                    
                    selectedImage.image = processResult.image
//                    selectedImage.score = processResult.score
//                    selectedImage.faceLandmarks = processResult.faceLandmarks
                    
                    print("processResult success")
                    print(processResult)
                    
                }
            }
        }
        
    }
    
    var body: some View {
        VStack{
            PhotosPicker(selection: $selectedItems.onChange(onPickerImageChangeHandler),maxSelectionCount: 1,
                         matching: .any(of: [.images, .screenshots])) {
                        Text("Select A Photos")
                    }
        
        }
    }
    
}

fileprivate struct DisplayImages: View{
    @Binding var selectedImage: BodyPoseData
    
    var body: some View {
        ScrollView{
            if selectedImage.image == nil {
                Text("Select the photo fisrt")
            } else {
                Image(uiImage: selectedImage.image!)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }

            
        }
    }
}

fileprivate func onPositionFrontDoubleBicepPose(observation: HumanBodyPose3DObservation) -> PoseClassificationResult {
    
    print("\n === FRONT DOUBLE BICEP POSE ANALYSIS === ")
    
    let leftShoulder = observation.joint(for: .leftShoulder)
    let rightShoulder = observation.joint(for: .rightShoulder)
    let leftElbow = observation.joint(for: .leftElbow)
    let rightElbow = observation.joint(for: .rightElbow)
    let leftWrist = observation.joint(for: .leftWrist)
    let rightWrist = observation.joint(for: .rightWrist)
    
    var detectedJoints: [String: Bool] = [:]
    var missingJoints: [String] = []
    var feedback: [String] = []
    var isCorrectPose = true
    var confidence: Float = 1.0
    
    detectedJoints["leftShoulder"] = leftShoulder != nil
    detectedJoints["rightShoulder"] = rightShoulder != nil
    detectedJoints["leftElbow"] = leftElbow != nil
    detectedJoints["rightElbow"] = rightElbow != nil
    detectedJoints["leftWrist"] = leftWrist != nil
    detectedJoints["rightWrist"] = rightWrist != nil
    
//    print("Joint Detection Status:")
//    for (joint, detected) in detectedJoints {
//        let status = detected ? "✅" : "❌"
//        print("   \(status) \(joint): \(detected ? "DETECTED" : "NOT DETECTED")")
//        if !detected {
//            missingJoints.append(joint)
//        }
//    }
    
    if missingJoints.count > 2 {
        print("\n❌ CLASSIFICATION RESULT: POSE TIDAK DAPAT DIDETEKSI")
        print("Reason: Terlalu banyak joint yang tidak terdeteksi (\(missingJoints.count)/6)")
        return PoseClassificationResult(
            isPoseCorrect: false,
            confidence: 0.0,
            feedback: "Tidak dapat mendeteksi pose - terlalu banyak joint yang hilang: \(missingJoints.joined(separator: ", "))",
            detectedJoints: detectedJoints
        )
    }
    
    print("\nPOSE ANALYSIS:")
    
    if let leftShoulder = leftShoulder, let leftElbow = leftElbow {
        let leftShoulderY = leftShoulder.position.columns.3.y
        let leftElbowY = leftElbow.position.columns.3.y
        let leftArmRaised = leftElbowY > leftShoulderY
        print("Left arm raised: \(leftArmRaised ? "✅ YES" : "❌ NO") (Shoulder Y: \(String(format: "%.3f", leftShoulderY)), Elbow Y: \(String(format: "%.3f", leftElbowY)))")
        if !leftArmRaised {
            feedback.append("Angkat lengan kiri lebih tinggi")
            isCorrectPose = false
            confidence -= 0.3
        }
    }
    
    if let rightShoulder = rightShoulder, let rightElbow = rightElbow {
        let rightShoulderY = rightShoulder.position.columns.3.y
        let rightElbowY = rightElbow.position.columns.3.y
        let rightArmRaised = rightElbowY > rightShoulderY
        print("Right arm raised: \(rightArmRaised ? "✅ YES" : "❌ NO") (Shoulder Y: \(String(format: "%.3f", rightShoulderY)), Elbow Y: \(String(format: "%.3f", rightElbowY)))")
        if !rightArmRaised {
            feedback.append("Angkat lengan kanan lebih tinggi")
            isCorrectPose = false
            confidence -= 0.3
        }
    }
    
    if let leftElbow = leftElbow, let leftWrist = leftWrist {
        let leftElbowY = leftElbow.position.columns.3.y
        let leftWristY = leftWrist.position.columns.3.y
        let leftBicepFlexed = leftWristY > leftElbowY
        print("Left bicep flexed: \(leftBicepFlexed ? "✅ YES" : "❌ NO") (Elbow Y: \(String(format: "%.3f", leftElbowY)), Wrist Y: \(String(format: "%.3f", leftWristY)))")
        if !leftBicepFlexed {
            feedback.append("Tekuk lengan kiri lebih kuat untuk menunjukkan bisep")
            isCorrectPose = false
            confidence -= 0.2
        }
    }
    
    if let rightElbow = rightElbow, let rightWrist = rightWrist {
        let rightElbowY = rightElbow.position.columns.3.y
        let rightWristY = rightWrist.position.columns.3.y
        let rightBicepFlexed = rightWristY > rightElbowY
        print("Right bicep flexed: \(rightBicepFlexed ? "✅ YES" : "❌ NO") (Elbow Y: \(String(format: "%.3f", rightElbowY)), Wrist Y: \(String(format: "%.3f", rightWristY)))")
        if !rightBicepFlexed {
            feedback.append("Tekuk lengan kanan lebih kuat untuk menunjukkan bisep")
            isCorrectPose = false
            confidence -= 0.2
        }
    }
    
    if let leftShoulder = leftShoulder, let rightShoulder = rightShoulder {
        let leftShoulderY = leftShoulder.position.columns.3.y
        let rightShoulderY = rightShoulder.position.columns.3.y
        let shoulderDifference = abs(leftShoulderY - rightShoulderY)
        let shouldersLevel = shoulderDifference < 0.1
        print("Shoulders level: \(shouldersLevel ? "✅ YES" : "❌ NO") (Left: \(String(format: "%.3f", leftShoulderY)), Right: \(String(format: "%.3f", rightShoulderY)), Diff: \(String(format: "%.3f", shoulderDifference)))")
        if !shouldersLevel {
            feedback.append("Sejajarkan kedua bahu")
            confidence -= 0.1
        }
    }
    
    confidence = max(0.0, confidence)
    
    let finalFeedback = isCorrectPose ? "Pose Front Double Bicep SEMPURNA! " : feedback.joined(separator: ", ")
    
    print("\n=== FINAL CLASSIFICATION RESULT ===")
    print("Pose Correct: \(isCorrectPose ? "✅ YES" : "❌ NO")")
    print("Confidence: \(String(format: "%.1f", confidence * 100))%")
    print("Feedback: \(finalFeedback)")
    print("=======================================\n")
    
    return PoseClassificationResult(
        isPoseCorrect: isCorrectPose,
        confidence: confidence,
        feedback: finalFeedback,
        detectedJoints: detectedJoints
    )
}

fileprivate func processImage(image: Data) async throws -> BodyPoseData {
    
    let request = DetectHumanBodyPose3DRequest()
    
    let obsv = try await request.perform(on: image)
    
    
    guard let obsvdata : HumanBodyPose3DObservation = obsv.first else {
        print("\n======================\n\n\n❌No one Human detected❌\n")
        return BodyPoseData(image: UIImage(data: image))
    }
    
    print("\n==================\n\n human detected: ",obsv.count)
    print("image name: ", image.suggestedFilename)
    print("\n\nbodyHeight\n",obsvdata.bodyHeight)
    
    print("\n\ndescription\n",obsvdata.description)
    print("\n\navailableJointNames\n",obsvdata.availableJointNames)
    
    print("\n\nallJoints\n",obsvdata.allJoints())
//    for availableJoint in obsvdata.allJoints() {
//
//        print("\nJoint Name ",availableJoint.0)
//        print("Position ",availableJoint.1.position)
//        print("Local Position ",availableJoint.1.localPosition)
//
//    }
    
    
    let leftShoulderData = obsvdata.joint(for: .leftShoulder)
    let rightShoulderData = obsvdata.joint(for: .rightShoulder)
    
    print("\n\nLeft Shoudler: ", leftShoulderData ?? "Left shoudler undetected")
    print("\nright Shoudler: ", rightShoulderData ?? "Right shulder undetected")

    print("\n\nLeft Elbow: ", obsvdata.joint(for: .leftElbow) ?? "Left shoudler undetected")
    print("\nRight Elbow: ", obsvdata.joint(for: .rightElbow) ?? "Right shulder undetected")
    
    print("\n\nLeft Wrist: ", obsvdata.joint(for: .leftWrist) ?? "Left shoudler undetected")
    print("\nRight Wrist: ", obsvdata.joint(for: .rightWrist) ?? "Right shulder undetected")
    
    print("\n\n\navailableJointsGroupNames\n",obsvdata.availableJointsGroupNames)
    print("\n\ncameraRelativePosition\n",obsvdata.cameraRelativePosition(for: .centerHead))

    
    let poseClassification = onPositionFrontDoubleBicepPose(observation: obsvdata)
    
    // Print summary result
    print("\n=== POSE CLASSIFICATION SUMMARY ===")
    print("Status: \(poseClassification.isPoseCorrect ? "POSE BENAR ✅" : "POSE PERLU DIPERBAIKI ❌")")
    print("=====================================\n")
    
    return BodyPoseData(image: UIImage(data: image))

    
    
//    let request = VNDetectHumanBodyPose3DRequest()
//
//
//    let requestHandler = VNImageRequestHandler(data: image)
//
//    try requestHandler.perform([request])
//
//
//        // Get the observation.
//    if let observation = request.results?.first {
//        // Handle the observation.
//
//
//        print("\n\n\n🚀image detection success processed\n")
//        print(request.description)
//        print(request)
//
//        print(observation.description)
//        print(observation)
//
//        let leftShoulder = try observation.recognizedPoint(.leftShoulder)
//        let leftElbow = try observation.recognizedPoint(.leftElbow)
//        let leftWrist = try observation.recognizedPoint(.leftWrist)
//
//        print(leftShoulder)
//        print(leftElbow)
//        print(leftWrist)
//
//
//
//    }
    

}

#Preview {
    BodyDetection()
}
