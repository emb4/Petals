//
//  ContentView.swift
//  Petals SwiftUI
//
//  Created by Eric Bates on 6/13/20.
//  Copyright © 2020 Eric Bates. All rights reserved.
//

import SwiftUI
import CoreML
import Vision
import Alamofire
import SwiftyJSON

enum ActiveSheet {
    case camera, detail, photoLibrary
}

struct ContentView: View {
    @State private var image: Image?
    @State private var showSheet = false
    @State private var activeSheet: ActiveSheet = .camera
    @State private var inputImage: UIImage?
    @State private var identifyButtonDisabled = true
    
    @State var firstGuess = Guess(name: "", description: "", accuracy: 0)
    @State var secondGuess = Guess(name: "", description: "", accuracy: 0)
    @State var thirdGuess = Guess(name: "", description: "", accuracy: 0)
    @State var fourthGuess = Guess(name: "", description: "", accuracy: 0)
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Rectangle()
                    .foregroundColor(Color("background"))
                    .frame(height: 50)
                    .offset(y: 50)
                HStack {
                    ZStack {
                        Rectangle()
                            .frame(height: 60)
                            .foregroundColor(Color("background"))
                            .edgesIgnoringSafeArea(.all)
                        //                            .shadow(radius: 10)
                        Button(action: {
                            self.activeSheet = .photoLibrary
                            self.showSheet.toggle()
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                            .foregroundColor(Color("accentYellow"))
                        }
                    }
                    Divider()
                        .frame(width: -20, height: 0)
                    ZStack {
                        Rectangle()
                            .frame(height: 60)
                            .foregroundColor(Color("background"))
                            .edgesIgnoringSafeArea(.all)
                        Button(action: {
                            self.activeSheet = .camera
                            self.showSheet.toggle()
                        }) {
                            Image(systemName: "camera.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                            .foregroundColor(Color("accentYellow"))
                        }
                    }
                }
                .offset(y: 0)
                .edgesIgnoringSafeArea(.all)
                Button(action: {
                    self.activeSheet = .detail
                    self.showSheet.toggle()
                    
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 105, height: 125)
                            .foregroundColor(Color("background"))
                            .shadow(radius: 10)
                        if identifyButtonDisabled == true {
                            Image(systemName: "viewfinder")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60)
                                .foregroundColor(Color("disabledColor"))
                            Text("IDENTIFY")
                                .font(.footnote)
                                .fontWeight(.heavy)
                            .foregroundColor(Color("disabledColor"))
                        } else {
                            Image(systemName: "viewfinder")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60)
                                .foregroundColor(Color("accentYellow"))
                            Text("IDENTIFY")
                                .font(.footnote)
                                .fontWeight(.heavy)
                            .foregroundColor(Color("accentYellow"))
                        }
                    }
                    .offset(y: -30)
                }
                .disabled(identifyButtonDisabled)
                .sheet(isPresented: $showSheet, onDismiss: loadImage) {
                    if self.activeSheet == .camera {
                        CameraPicker(image: self.$inputImage)
                    } else if self.activeSheet == .photoLibrary {
                        LibraryPicker(image: self.$inputImage)
                    } else {
                        FlowerView(guess: self.firstGuess, secondGuess: self.secondGuess, thirdGuess: self.thirdGuess, fourthGuess: self.fourthGuess, selectedImage: self.image)
                    }
                }
            }
            //            .background(Color(#colorLiteral(red: 0, green: 0.5546219945, blue: 1, alpha: 1)))
            //            .frame(height: )
        }
        .background(
            ZStack {
                if identifyButtonDisabled == true {
                    Text("Hello, maybe try taking a picture of a flower?")
                        .font(.headline)
                        .padding(.horizontal)
                        .offset(y: -65)
                    .foregroundColor(Color(#colorLiteral(red: 0.4962579012, green: 0.4934777021, blue: 0.4984002709, alpha: 1)))
                }
                image?
                    .resizable()
                    .offset(y: -35)
                    .frame(width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.height)
                    .blur(radius: 20)
                image?
                    .resizable()
                    .offset(y: -35)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                    .shadow(radius: 10)
            }
        )
            .offset(y: 35)
            .onAppear() {
                //                self.colors = NSArray(ofColorsFrom: self.inputImage, withFlatScheme: true)
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        guard let ciimage = CIImage(image: inputImage) else {
            fatalError("Couldn't convert UIImage into CIImage")
        }
        detect(image: ciimage)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            
            if let firstResult = results.first {
                let name = firstResult.identifier.capitalized
                self.firstGuess.name = name
                self.firstGuess.accuracy = Int(firstResult.confidence * 100)
                self.requestInfo(flowerName: firstResult.identifier.capitalized)
            }
            self.secondGuess.name = results[1].identifier.capitalized
            self.secondGuess.accuracy = Int(results[1].confidence * 100)
            self.thirdGuess.name = results[2].identifier.capitalized
            self.thirdGuess.accuracy = Int(results[2].confidence * 100)
            self.fourthGuess.name = results[3].identifier.capitalized
            self.fourthGuess.accuracy = Int(results[3].confidence * 100)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let wikipediaURl = "https://en.wikipedia.org/w/api.php"
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
//                print("Got the wikipedia info")
//                print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let description = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                DispatchQueue.main.async {
                    self.firstGuess.description = description
                    self.firstGuess.imageURL = URL(string: flowerImageURL)
                    self.identifyButtonDisabled = false
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
