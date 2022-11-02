

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var lable: UILabel!
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
   
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            
            decetc(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true)
        
    }
    
    func decetc(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: MLModelConfiguration()).model) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
           
            guard let result = request.results as? [VNClassificationObservation] else {
                fatalError("")
            }
            
            if let firstResult = result.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(flowerName: firstResult.identifier)
                
               }
            
            }
                     
            let handler = VNImageRequestHandler(ciImage: image)
            
            do {
           try handler.perform([request])
            } catch {
                print(error)
            }
        }
        
    func requestInfo(flowerName: String) {
        
        let parameters : [String: String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "exintro": "",
            "explaintex": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1",
            "pithubsize": "300"
        ]
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
          
          case .success(let value):
              print("got the wikipedia info")
              print(response)
              
              let flowerJSON: JSON = JSON(value)

              let pageid = flowerJSON["query"]["pageids"][0].stringValue

              let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue

              let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
              
              self.imageView.sd_setImage(with: URL(string: flowerImageURL))

              self.lable.text = flowerDescription
              
            case .failure:
              print("did not get the wikipedia info")
            }
        }
    }
    
    @IBAction func cameraButton(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
 
}

