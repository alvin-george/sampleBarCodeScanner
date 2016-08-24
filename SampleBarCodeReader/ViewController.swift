//
//  ViewController.swift
//  SampleBarCodeReader
//
//  Created by Alvin George on 8/24/16.
//  Copyright © 2016 Alvin George. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, UITextFieldDelegate,AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var sampleTextField: UITextField!
    @IBOutlet weak var sampleBarCodeButton: UIButton!
    var discoveredBarCode:String?

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var previewConnection:AVCaptureConnection?
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    var error : NSError?
    var inputDevice:AVCaptureDeviceInput?
    var timer : NSTimer?

    var identifiedBorder : DiscoveredBarCodeView?

    override func viewDidLoad() {
        super.viewDidLoad()

        //Camera Set Up

        do {
            let inputDevice = try AVCaptureDeviceInput(device: captureDevice) as AVCaptureDeviceInput
            // moved the rest of the image capture into the do{} scope.
        }   catch let error as NSError {
            print(error)
        }

        if let inp = inputDevice {
            captureSession.addInput(inp)
        } else {
            print(error)
        }

        captureSession = AVCaptureSession()

        let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed();
            return;
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypePDF417Code]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = self.view.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        view.layer.addSublayer(previewLayer);

        identifiedBorder = DiscoveredBarCodeView(frame: self.view.bounds)
        identifiedBorder?.backgroundColor = UIColor.clearColor()
        identifiedBorder?.hidden = true;
        self.view.addSubview(identifiedBorder!)


    }
    override func viewWillAppear(animated: Bool) {

    }
    override func viewWillDisappear(animated: Bool) {

        if (previewLayer.connection.supportsVideoOrientation)
        {

        }
        captureSession.stopRunning()

    }
    override func viewWillLayoutSubviews() {

        if let connection =  self.previewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.currentDevice()
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection

            if (previewLayerConnection.supportsVideoOrientation) {

                switch (orientation) {
                case .Portrait: updatePreviewLayer(previewLayerConnection, orientation: .Portrait)
                    break

                case .LandscapeRight: updatePreviewLayer(previewLayerConnection, orientation: .LandscapeLeft)
                    break

                case .LandscapeLeft: updatePreviewLayer(previewLayerConnection, orientation: .LandscapeRight)
                    break

                case .PortraitUpsideDown: updatePreviewLayer(previewLayerConnection, orientation: .PortraitUpsideDown)
                    break

                default: updatePreviewLayer(previewLayerConnection, orientation: .Portrait)
                    break
                }
            }
        }
    }
    override func viewDidAppear(animated: Bool) {
    }
    @IBAction func barCodeButtonTapped(sender: AnyObject) {
        //self.performSegueWithIdentifier("segueToCameraViewController", sender: self)\

        //view.backgroundColor = UIColor.blackColor()

        self.view.layer.addSublayer(previewLayer);
        self.view.addSubview(identifiedBorder!)
        captureSession.startRunning();
    }
    func addDiscoveredBarCode(barcode:String?)
    {
        discoveredBarCode = barcode!  as String
        print("discoveredBarCode @ func:\(discoveredBarCode)")
    }
    func textFieldDidBeginEditing(textField: UITextField) {
    }
    func textFieldDidEndEditing(textField: UITextField) {
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true;
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }

    //Camera Related Methods
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
        captureSession = nil
    }
    func translatePoints(points : [AnyObject], fromView : UIView, toView: UIView) -> [CGPoint] {
        var translatedPoints : [CGPoint] = []
        for point in points {
            let dict = point as! NSDictionary
            let x = CGFloat((dict.objectForKey("X") as! NSNumber).floatValue)
            let y = CGFloat((dict.objectForKey("Y")as! NSNumber).floatValue)
            let curr = CGPointMake(x, y)
            let currFinal = fromView.convertPoint(curr, toView: toView)
            translatedPoints.append(currFinal)
        }
        return translatedPoints
    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        captureSession.stopRunning()

        //        for data in metadataObjects {
        //            let metaData = data as! AVMetadataObject
        //            let transformed = previewLayer?.transformedMetadataObjectForMetadataObject(metaData) as? AVMetadataMachineReadableCodeObject
        //
        //            if let unwraped = transformed {
        //                identifiedBorder?.frame = unwraped.bounds
        //                identifiedBorder?.hidden = false
        //                let identifiedCorners = self.translatePoints(unwraped.corners, fromView: self.view, toView: self.identifiedBorder!)
        //                identifiedBorder?.drawBorder(identifiedCorners)
        //                self.identifiedBorder?.hidden = false
        //                self.startTimer()
        //
        //            }
        //        }

        var highlightViewRect = CGRectZero
        var barCodeObject : AVMetadataObject!
        var detectionString : String!

        let barCodeTypes = [AVMetadataObjectTypeUPCECode,
            AVMetadataObjectTypeCode39Code,
            AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code,
            AVMetadataObjectTypeEAN8Code,
            AVMetadataObjectTypeCode93Code,
            AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code,
            AVMetadataObjectTypeQRCode,
            AVMetadataObjectTypeAztecCode,
            AVMetadataObjectTypeUPCECode,
            AVMetadataObjectTypeInterleaved2of5Code,
            AVMetadataObjectTypeITF14Code,
            AVMetadataObjectTypeDataMatrixCode
        ]
        for metadata in metadataObjects {
            for barcodeType in barCodeTypes {
                if metadata.type == barcodeType {
                    barCodeObject = self.previewLayer.transformedMetadataObjectForMetadataObject(metadata as! AVMetadataMachineReadableCodeObject)

                    highlightViewRect = barCodeObject.bounds
                    detectionString = (metadata as! AVMetadataMachineReadableCodeObject).stringValue
                    self.captureSession.stopRunning()
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.foundCode(detectionString);
                    previewLayer.removeFromSuperlayer()
                    break
                }
            }
        }

//
//        if let metadataObject = metadataObjects.first {
//            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject;
//
//            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
//            foundCode(readableObject.stringValue);
//        }
//        previewLayer.removeFromSuperlayer()
    }
    func foundCode(code: String) {
        discoveredBarCode = code
        print("the Bar Code is : \(discoveredBarCode)")
        self.sampleTextField.text = discoveredBarCode

    }
    func startTimer() {
        if timer?.valid != true {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "removeBorder", userInfo: nil, repeats: false)
        } else {
            timer?.invalidate()
        }
    }
    func removeBorder() {
        /* Remove the identified border */
        self.identifiedBorder?.hidden = true
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    //    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    //        return .Portrait
    //    }
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        previewLayer.frame = self.view.bounds
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

