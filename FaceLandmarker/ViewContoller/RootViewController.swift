// Copyright 2023 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import AVFoundation

private var csvContent = ""
var combinedResultBundle = ResultBundle(inferenceTime: 0.0, faceLandmarkerResults: [], size: .zero)
var ratio = 0.0

protocol InferenceResultDeliveryDelegate: AnyObject {
  func didPerformInference(result: ResultBundle?)
}

protocol InterfaceUpdatesDelegate: AnyObject {
  func shouldClicksBeEnabled(_ isEnabled: Bool)
}

//to pass the diagnosisSessions data from RootViewController to InitialViewController
protocol RootViewControllerDelegate: AnyObject {
    func updateSessions(_ sessions: [(Date, Double)])
}

/** The view controller is responsible for presenting and handling the tabbed controls for switching between the live camera feed and
  * media library view controllers. It also handles the presentation of the inferenceVC
  */
class RootViewController: UIViewController {

  // MARK: Storyboards Connections
  @IBOutlet weak var tabBarContainerView: UIView!
  @IBOutlet weak var runningModeTabbar: UITabBar!
  @IBOutlet weak var bottomSheetViewBottomSpace: NSLayoutConstraint!
  @IBOutlet weak var bottomViewHeightConstraint: NSLayoutConstraint!
  weak var delegate: RootViewControllerDelegate?
  
  // MARK: Constants
  private struct Constants {
    static let inferenceBottomHeight = 260.0
    static let expandButtonHeight = 41.0
    static let expandButtonTopSpace = 10.0
    static let mediaLibraryViewControllerStoryBoardId = "MEDIA_LIBRARY_VIEW_CONTROLLER"
    static let cameraViewControllerStoryBoardId = "CAMERA_VIEW_CONTROLLER"
    static let storyBoardName = "Main"
    static let inferenceVCEmbedSegueName = "EMBED"
    static let tabBarItemsCount = 2
  }
  
  // MARK: Controllers that manage functionality
  private var inferenceViewController: BottomSheetViewController?
  private var cameraViewController: CameraViewController?
  private var mediaLibraryViewController: MediaLibraryViewController?
    var diagnosisSessions: [(Date, Double)] = [] {
        didSet {
            saveSessionData(diagnosisSessions)
        }
    }
  
  // MARK: Private Instance Variables
  private var totalBottomSheetHeight: CGFloat {
    guard let isOpen = inferenceViewController?.toggleBottomSheetButton.isSelected else {
      return 0.0
    }
    
    return isOpen ? Constants.inferenceBottomHeight - self.view.safeAreaInsets.bottom
      : Constants.expandButtonHeight + Constants.expandButtonTopSpace
  }
    
    public func writeResultBundleToCSV(_ resultBundle: ResultBundle) {
        let header = "frame,irisPoint,X,Y,Z,Vx,Vy,Vz,Score" // Column headers
        csvContent = header
        
        print("Deep Dark Fantasy")
        
        for faceLandmarkResult in resultBundle.faceLandmarkerResults {
            guard let landmarks = faceLandmarkResult?.faceLandmarks else {
                continue
            }
            
            // Iterate over the faceLandmarks
            for (_, landmark) in landmarks.enumerated() {
                frame+=1
                
                let vector1: (Double, Double, Double) = (Double(landmark[454].x-landmark[234].x), Double(landmark[454].y-landmark[234].y), Double(landmark[454].z-landmark[234].z))
                
                let vector2: (Double, Double, Double) = (Double(landmark[6].x-landmark[234].x), Double(landmark[6].y-landmark[234].y), Double(landmark[6].z-landmark[234].z))
                
                let point1: (Double, Double, Double) = (Double(landmark[468].x), Double(landmark[468].y), Double(landmark[468].z))
                
                let point2: (Double, Double, Double) = (Double(landmark[473].x), Double(landmark[473].y), Double(landmark[473].z))
                
                let normalVector = normalizeVector(crossProduct(vector1, vector2))
                
                let distance = dotProduct(normalVector,point1)
                
                let projected_point1 : (Double, Double, Double) = (point1.0-distance*normalVector.0,point1.1-distance*normalVector.1,point1.2-distance*normalVector.2)
                
                let projected_point2 : (Double, Double, Double) = (point2.0-distance*normalVector.0,point2.1-distance*normalVector.1,point2.2-distance*normalVector.2)
                
                for i in 0..<2 {
                    if(frame == 1) {
                        iris[0]=projected_point1
                        iris[1]=projected_point2
                        let row = "\(frame),\(i+1),\(round(1000*iris[i].0)/1000),\(round(1000*iris[i].1)/1000),\(round(1000*iris[i].2)/1000)" // Create a row with x, y, and z coordinates
                        csvContent += "\n" + row
                        
                        piris[0]=projected_point1
                        piris[1]=projected_point2
                    }
                    else {
                        iris[0]=projected_point1
                        iris[1]=projected_point2
                        
                        vel[i].x=30*(iris[i].0-piris[i].0)
                        vel[i].y=30*(iris[i].1-piris[i].1)
                        vel[i].z=30*(iris[i].2-piris[i].2)
                        
                        xsum+=abs(vel[i].x)
                        ysum+=abs(vel[i].y)
                        
                        ratio = round(1000*ysum/xsum)/1000
                        
                        let row = "\(frame),\(i+1),\(round(1000*landmark[i].x)/1000),\(round(1000*landmark[i].y)/1000),\(round(1000*landmark[i].z)/1000),\(round(1000*vel[i].x)/1000),\(round(1000*vel[i].y)/1000),\(round(1000*vel[i].z)/1000),\(ratio)" // Create a row with x, y, and z coordinates
                        csvContent += "\n" + row
                    }
                }
                piris[0]=projected_point1
                piris[1]=projected_point2
                
                /*for i in 0..<478 {
                 if(frame == 1) {
                 var resultTuple = Array<Double>()
                 resultTuple.append(Double(landmark[i].x))
                 resultTuple.append(Double(landmark[i].y))
                 resultTuple.append(Double(landmark[i].z))
                 prev[i]=resultTuple
                 
                 let row = "\(frame),\(i+1),\(landmark[i].x),\(landmark[i].y),\(landmark[i].z)" // Create a row with x, y, and z coordinates
                 csvContent += "\n" + row
                 
                 
                 }
                 else {
                 var rt = prev[i]
                 vel[i].x=30*(Double(landmark[i].x)-rt[0])
                 vel[i].y=30*(Double(landmark[i].y)-rt[1])
                 vel[i].z=30*(Double(landmark[i].z)-rt[2])
                 
                 var resultTuple = Array<Double>()
                 resultTuple.append(Double(landmark[i].x))
                 resultTuple.append(Double(landmark[i].y))
                 resultTuple.append(Double(landmark[i].z))
                 prev[i]=resultTuple
                 
                 let row = "\(frame),\(i+1),\(landmark[i].x),\(landmark[i].y),\(landmark[i].z),\(vel[i].x),\(vel[i].y),\(vel[i].z)" // Create a row with x, y, and z coordinates
                 csvContent += "\n" + row
                 }
                 }*/
            }
        }
    }
    
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        writeResultBundleToCSV(combinedResultBundle)
        let csvFileName = "landmark.csv" // Specify the desired file name
        
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(csvFileName)
            
            do {
                try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file created at path:", fileURL.path)
                
                DispatchQueue.main.async {
                    // Use the fileURL to present documentPicker on the main thread
                    let documentPicker = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
                    self.present(documentPicker, animated: true, completion: nil)
                    self.diagnosisSessions.append((Date(), ratio))
                    self.delegate?.updateSessions(self.diagnosisSessions)
                }
            } catch {
                print("Error creating CSV file:", error.localizedDescription)
            }
        }
    }
    
    @IBAction func menuButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "segueIdentifierToInitialVC", sender: self)
    }
    
    func saveSessionData(_ sessions: [(Date, Double)]) {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let fileURL = documentDirectory.appendingPathComponent("sessions.txt")

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            let sessionStrings = sessions.map { session -> String in
                let dateString = dateFormatter.string(from: session.0)
                return "\(dateString),\(session.1)"
            }.joined(separator: "\n")

            do {
                try sessionStrings.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error saving sessions data: \(error)")
            }
        }

    func loadSessionData() -> [(Date, Double)] {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
            let fileURL = documentDirectory.appendingPathComponent("sessions.txt")

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            do {
                let sessionStrings = try String(contentsOf: fileURL, encoding: .utf8)
                let sessions = sessionStrings.split(separator: "\n").compactMap { line -> (Date, Double)? in
                    let components = line.split(separator: ",")
                    guard components.count == 2,
                          let date = dateFormatter.date(from: String(components[0])),
                          let ratio = Double(components[1]) else {
                        return nil
                    }
                    return (date, ratio)
                }
                return sessions
            } catch {
                print("Error loading sessions data: \(error)")
                return []
        }
    }
    

  // MARK: View Handling Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    // Create face landmarker helper
    
    loadAndPlayVideo()
    
    inferenceViewController?.isUIEnabled = true
    runningModeTabbar.selectedItem = runningModeTabbar.items?.first
    runningModeTabbar.delegate = self
    instantiateCameraViewController()
    switchTo(childViewController: cameraViewController, fromViewController: nil)
    diagnosisSessions = loadSessionData()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    guard inferenceViewController?.toggleBottomSheetButton.isSelected == true else {
      bottomSheetViewBottomSpace.constant = -Constants.inferenceBottomHeight
      + Constants.expandButtonHeight
      + self.view.safeAreaInsets.bottom
      + Constants.expandButtonTopSpace
      return
    }
    
    bottomSheetViewBottomSpace.constant = 0.0
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: Storyboard Segue Handlers
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    if segue.identifier == Constants.inferenceVCEmbedSegueName {
      inferenceViewController = segue.destination as? BottomSheetViewController
      inferenceViewController?.delegate = self
      bottomViewHeightConstraint.constant = Constants.inferenceBottomHeight
      view.layoutSubviews()
    }
  }
  
  // MARK: Private Methods
  private func instantiateCameraViewController() {
    guard cameraViewController == nil else {
      return
    }
    
    guard let viewController = UIStoryboard(
      name: Constants.storyBoardName, bundle: .main)
      .instantiateViewController(
        withIdentifier: Constants.cameraViewControllerStoryBoardId) as? CameraViewController else {
      return
    }
    
    viewController.inferenceResultDeliveryDelegate = self
    viewController.interfaceUpdatesDelegate = self
    
    cameraViewController = viewController
  }
  
  private func instantiateMediaLibraryViewController() {
    guard mediaLibraryViewController == nil else {
      return
    }
    guard let viewController = UIStoryboard(name: Constants.storyBoardName, bundle: .main)
      .instantiateViewController(
        withIdentifier: Constants.mediaLibraryViewControllerStoryBoardId)
            as? MediaLibraryViewController else {
      return
    }
    
    viewController.interfaceUpdatesDelegate = self
    viewController.inferenceResultDeliveryDelegate = self
    mediaLibraryViewController = viewController
  }
  
  private func updateMediaLibraryControllerUI() {
    guard let mediaLibraryViewController = mediaLibraryViewController else {
      return
    }
    
    mediaLibraryViewController.layoutUIElements(
      withInferenceViewHeight: self.totalBottomSheetHeight)
  }
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
        
        // MARK: Load and Play Video
    private func loadAndPlayVideo() {
        guard let path = Bundle.main.path(forResource: "Nemo", ofType: "mp4") else {
                debugPrint("Video file not found")
                return
            }
            
            let url = URL(fileURLWithPath: path)
            player = AVPlayer(url: url)
            playerLayer = AVPlayerLayer(player: player)
            
            // Adjust the size and frame of the video
            playerLayer?.frame = view.bounds
            playerLayer?.videoGravity = .resizeAspectFill  // Adjust as needed
            
            view.layer.insertSublayer(playerLayer!, at: 0) // Make sure the video is behind all other views
            
            // Hide the tabBarContainerView while the video is playing
            tabBarContainerView.isHidden = true
            
            // Play video on loop by listening to its end
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(videoDidEnd),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: player?.currentItem)
            
            // Start playing the video
            player?.play()
    }
    
    @objc private func videoDidEnd(notification: NSNotification) {
        // Loop the video
        player?.seek(to: CMTime.zero)
        player?.play()
    }
}

// MARK: UITabBarDelegate
extension RootViewController: UITabBarDelegate {
  func switchTo(
    childViewController: UIViewController?,
    fromViewController: UIViewController?) {
    fromViewController?.willMove(toParent: nil)
    fromViewController?.view.removeFromSuperview()
    fromViewController?.removeFromParent()
    
    guard let childViewController = childViewController else {
      return
    }
      
    addChild(childViewController)
    childViewController.view.translatesAutoresizingMaskIntoConstraints = false
    tabBarContainerView.addSubview(childViewController.view)
    NSLayoutConstraint.activate(
      [
        childViewController.view.leadingAnchor.constraint(
          equalTo: tabBarContainerView.leadingAnchor,
          constant: 0.0),
        childViewController.view.trailingAnchor.constraint(
          equalTo: tabBarContainerView.trailingAnchor,
          constant: 0.0),
        childViewController.view.topAnchor.constraint(
          equalTo: tabBarContainerView.topAnchor,
          constant: 0.0),
        childViewController.view.bottomAnchor.constraint(
          equalTo: tabBarContainerView.bottomAnchor,
          constant: 0.0)
      ]
    )
    childViewController.didMove(toParent: self)
  }
  
  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    guard let tabBarItems = tabBar.items, tabBarItems.count == Constants.tabBarItemsCount else {
      return
    }

    var fromViewController: UIViewController?
    var toViewController: UIViewController?
    
    switch item {
    case tabBarItems[0]:
        fromViewController = mediaLibraryViewController
        toViewController = cameraViewController
    case tabBarItems[1]:
        instantiateMediaLibraryViewController()
        fromViewController = cameraViewController
        toViewController = mediaLibraryViewController
    default:
      break
    }
    
    switchTo(
      childViewController: toViewController,
      fromViewController: fromViewController)
    self.shouldClicksBeEnabled(true)
    self.updateMediaLibraryControllerUI()
  }
}

// MARK: InferenceResultDeliveryDelegate Methods
extension RootViewController: InferenceResultDeliveryDelegate {
  func didPerformInference(result: ResultBundle?) {
    combinedResultBundle.faceLandmarkerResults.append(contentsOf: result?.faceLandmarkerResults ?? [])
    combinedResultBundle.size = result?.size ?? .zero
    var inferenceTimeString = ""
    
    if let inferenceTime = result?.inferenceTime {
      inferenceTimeString = String(format: "%.2fms", inferenceTime)
    }
    inferenceViewController?.update(inferenceTimeString: inferenceTimeString)
  }
}

// MARK: InterfaceUpdatesDelegate Methods
extension RootViewController: InterfaceUpdatesDelegate {
  func shouldClicksBeEnabled(_ isEnabled: Bool) {
    inferenceViewController?.isUIEnabled = isEnabled
  }
}

// MARK: InferenceViewControllerDelegate Methods
extension RootViewController: BottomSheetViewControllerDelegate {
  func viewController(
    _ viewController: BottomSheetViewController,
    didSwitchBottomSheetViewState isOpen: Bool) {
      if isOpen == true {
        bottomSheetViewBottomSpace.constant = 0.0
      }
      else {
        bottomSheetViewBottomSpace.constant = -Constants.inferenceBottomHeight
        + Constants.expandButtonHeight
        + self.view.safeAreaInsets.bottom
        + Constants.expandButtonTopSpace
      }
      
      UIView.animate(withDuration: 0.3) {[weak self] in
        guard let weakSelf = self else {
          return
        }
        weakSelf.view.layoutSubviews()
        weakSelf.updateMediaLibraryControllerUI()
      }
    }
}
