// The Swift Programming Language
// https://docs.swift.org/swift-book

import Photos
import PhotosUI
import UIKit

public class OMPhotoLibrary {
    public static let shared = OMPhotoLibrary()
    
    
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    var imageCachingManager = PHCachingImageManager()
    var activeRequests: [PHAssetLocalIdentifier: PHImageRequestID] = [:]
    
    public func requestAuthorization(
            accessLevel: PHAccessLevel = .readWrite,
            handleError: ((OMPhotoLibraryAuthorizationError?) -> Void)? = nil
        ) {
            /// This is the code that does the permission requests
            PHPhotoLibrary.requestAuthorization(for: accessLevel) { [weak self] status in
                self?.authorizationStatus = status
                /// We can determine permission granted by the status
                switch status {
                /// Fetch all photos if the user granted us access
                /// This won't be the photos themselves but the
                /// references only.
                case .authorized, .limited:
                    break
                /// For denied response, we should show an error
                case .denied, .notDetermined, .restricted:
                    handleError?(.restrictedAccess)
                    
                @unknown default:
                    break
                }
            }
        }

    public func fetchImage(
        byLocalIdentifier localId: PHAssetLocalIdentifier,
        targetSize: CGSize = PHImageManagerMaximumSize,
        contentMode: PHImageContentMode = .default,
        onError: @escaping (Error) -> (),
        onImage: @escaping  (UIImage) -> ()
    )  {
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [localId],
            options: nil
        )
        guard let asset = results.firstObject else {
            onError(OMPhotoLibraryQueryError.phAssetNotFound)
            return
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        
            /// Use the imageCachingManager to fetch the image
        let request = imageCachingManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options,
            resultHandler: { image, info in
                /// image is of type UIImage
                if let error = info?[PHImageErrorKey] as? Error {
                    onError(error)
                    return
                }
                
                guard let image = image else {
                    onError(OMPhotoLibraryQueryError.phAssetNotFound)
                    return
                }
                onImage(image)
            })
            
//            activeRequests[localId] = request
    }
    ///
    public func  fetchVideo(
            byLocalIdentifier localId: PHAssetLocalIdentifier,
            targetSize: CGSize = PHImageManagerMaximumSize,
            contentMode: PHImageContentMode = .default,
            onError:  @escaping (Error) -> (),
            onVideo:  @escaping (AVPlayerItem) -> ()
        )   {
            
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [localId],
            options: nil
        )
        guard let asset = results.firstObject else {
            onError(OMPhotoLibraryQueryError.phAssetNotFound)
            return
        }
        
        let manager = PHImageManager.default()
        let options =  PHVideoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        let request = imageCachingManager.requestPlayerItem(forVideo: asset,
                                                       options: options,
                                                       resultHandler: { item, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    onError(error)
                    return
                }
                
                guard let item = item else {
                    onError(OMPhotoLibraryQueryError.phAssetNotFound)
                    return
                }

                onVideo(item)
            })
            
//            activeRequests[localId] = request
        }
    
    
    func cancel(_ localID: PHAssetLocalIdentifier) {
        if let requestID = activeRequests[localID] {
            imageCachingManager.cancelImageRequest(requestID)
        }
        
    }
}


public enum OMPhotoLibraryAuthorizationError {
    case restrictedAccess
}

public enum OMPhotoLibraryQueryError: Error {
    case phAssetNotFound
}

public typealias PHAssetLocalIdentifier = String



