//
//  ViewController.swift
//  Flower World
//
//  Created by Arman morshed on 2/3/19.
//  Copyright © 2019 Arman morshed. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label: UILabel!
    
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[.originalImage] as? UIImage {
            
            guard let userPickedCiImage = CIImage(image: userPickedImage) else{
                fatalError("Can not Convert to CI Image")
            }
            
            detect(image: userPickedCiImage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    
    func  detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Con not find The Model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let  classification = request.results?.first as? VNClassificationObservation else{
                fatalError("Could not classify image")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            
            self.requestInfo(flowerName: classification.identifier)
            
            print(classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
         try handler.perform([request])
        }catch{
            print(error)
        }
    }
    
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize": "500"
        ]
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess{
                
                let flowerJSON : JSON = JSON(response.result.value!)
                
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
                
                let flowerImageUrl = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                
                self.label.text = flowerDescription
                self.imageView.sd_setImage(with: URL(string: flowerImageUrl))
                
                
            }else{
                
            }
        }
        
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
      present(imagePicker, animated: true, completion: nil)
    }
}


