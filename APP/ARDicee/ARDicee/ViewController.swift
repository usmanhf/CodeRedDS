//
//  ViewController.swift
//  ARDicee
//
//  Created by Usman Farooqi on 11/3/18.
//  Copyright © 2018 Usman Farooqi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Alamofire
import SwiftyJSON
//Globals



class ViewController: UIViewController, ARSCNViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var end: UIDatePicker!
    @IBOutlet weak var start: UIDatePicker!
    @IBOutlet weak var startLoc: UITextField!
    @IBOutlet weak var endLoc: UITextField!
    
    
    let FLIGHT_URL = "https://api.sandbox.amadeus.com/v1.2/flights/low-fare-search"
    let APIKEY = "6Sy1fp88A6Q3AcAPx6CVqMIodX2ahhvd"
    
    @IBOutlet var sceneView: ARSCNView!
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
        
        super.init(nibName: nil, bundle: nil)
        
        self.sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(_:))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        startLoc.delegate = self
        endLoc.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        sceneView.autoenablesDefaultLighting = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        sceneView.addGestureRecognizer(tapGesture)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let results = self.sceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
        guard let result: ARHitTestResult = results.first else {
            return
        }
        
        let tappedNode = self.sceneView.hitTest(gesture.location(in: gesture.view), options: [:])
        
        if !tappedNode.isEmpty {
            
            let node = tappedNode[0].node
            
            let startDate = start.date.description.prefix(10)
            let endDate = end.date.description.prefix(10)
            let params : [String : String] = ["apikey" : APIKEY, "origin" : startLoc.text!, "destination" : endLoc.text!, "departure_date" : String(startDate), "return_date" : String(endDate), "adults" : "1", "number_of_results" : "1"]
            self.getLowPrice(url: FLIGHT_URL, parameters: params)
        } else {
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if let hitResult = results.first {
                //print(hitResult)

            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            
            
//            sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
//                node.removeFromParentNode()
//            }
            
            let planeAnchor = anchor as! ARPlaneAnchor
            let plane =  SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeNode = SCNNode()
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
            planeNode.geometry = plane
            
            node.addChildNode(planeNode)
            
 
            let earth = SCNSphere(radius: 0.1)
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "art.scnassets/2k_earth_specular_map.tif")
            earth.materials = [material]
            
            let earthNode = SCNNode()
            earthNode.transform = SCNMatrix4MakeRotation(Float.pi/2, 0, 1, 0)
            earthNode.position = SCNVector3(
                x:0,
                y:0,
                z:-0.3)
            earthNode.geometry = earth;
            
            sceneView.scene.rootNode.addChildNode(earthNode)
            
            let city = SCNSphere(radius: 0.005)
            let dotMat = SCNMaterial()
            dotMat.diffuse.contents = UIColor.red
            city.materials = [dotMat]
            
            let HOU = SCNNode()
            HOU.position = SCNVector3(
                x:-0.080,
                y:0.05,
                z:-0.01)
            
            HOU.geometry = city
            
            
            earthNode.addChildNode(HOU)
            
            let city2 = SCNSphere(radius: 0.005)
            let dotMat2 = SCNMaterial()
            dotMat2.diffuse.contents = UIColor.blue
            city2.materials = [dotMat2]
            let NY = SCNNode()
            NY.position = SCNVector3(
                x:-0.07,
                y:0.063,
                z:0.020)
            
            NY.geometry = city2
            
            
            earthNode.addChildNode(NY)

        }
        else {
            return
        }
    }
    //-------------------------------------------------------------
    func getLowPrice(url: String, parameters: [String:String]){
        Alamofire.request(url, method : .get, parameters: parameters).responseJSON(){
            response in
            if response.result.isSuccess{
                print("API REQUEST SUCCESS")
                
                let flightJSON : JSON = JSON(response.result.value!)
                self.printData(json: flightJSON)
            }
            else{
                print("Error \(String(describing: response.result.error))")
                print("Connection Issue")
            }
        }
    }
    func printData(json: JSON) {
        
        if let price = json["results"][0]["fare"]["total_price"].string{
            print(price)
            let alert = UIAlertController(title: "FLIGHT PRICE", message: "The lowest price flight comes out to be: \(price)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else {
            print("doesn't work")
        }
       
    }
}
