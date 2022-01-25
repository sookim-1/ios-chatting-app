//
//  Download.swift
//  ios-chatting-app
//
//  Created by sookim on 2022/01/26.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation

let storage = Storage.storage()


//image

func uploadImage(image: UIImage, chatRoomId: String, view: UIView, completion: @escaping (_ imageLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    
    let photoFileName = "PictureMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
    
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
    
    let imageData = image.jpegData(compressionQuality: 0.7)
    
    
    // Firebase storage에 이미지 업로드하는 과정
    var task : StorageUploadTask!
    
    task = storageRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            print("error uploading image \(error!.localizedDescription)")
            
            return
        }
        
        
        storageRef.downloadURL(completion: { (url, error) in
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            
            completion(downloadUrl.absoluteString)
        })
        
    })
    
    // 진행과정 표시
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }

}

func downloadImage(imageUrl: String, completion: @escaping(_ image: UIImage?) -> Void) {
    
    let imageURL = NSURL(string: imageUrl)

    // 실제파일이름은 Url주소 마지막부분입니다.
    let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    // 매번이미지를 다운로드하면 비효율적이기 때문에 기기에 이미지가 존재하는 확인합니다.
    if fileExistsAtPath(path: imageFileName) {
        
        //exist 
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
            completion(contentsOfFile)
        } else {
            print("couldnt generate image")
            completion(nil)
        }
        
    } else {
        //doesnt exist
        
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        
        downloadQueue.async {
            
            let data = NSData(contentsOf: imageURL! as URL)
            
            if data != nil {
                
                var docURL = getDocumentsURL()
                
                docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                
                data!.write(to: docURL, atomically: true)
                
                let imageToReturn = UIImage(data: data! as Data)
                
                DispatchQueue.main.async {
                    completion(imageToReturn!)
                }
                
            } else {
                DispatchQueue.main.async {
                    print("no image in database")
                    completion(nil)
                }
            }
        }
    }
}

func fileInDocumentsDirectory(fileName: String) -> String {
    
    let fileURL = getDocumentsURL().appendingPathComponent(fileName)
    return fileURL.path
}


func getDocumentsURL() -> URL {
    
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    
    return documentURL!
}

func fileExistsAtPath(path: String) -> Bool {
    
    var doesExist = false
    
    let filePath = fileInDocumentsDirectory(fileName: path)
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: filePath) {
        doesExist = true
    } else {
        doesExist = false
    }
    
    return doesExist
}
