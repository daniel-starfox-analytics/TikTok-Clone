//
//  MediaPickerVideoBaseCell.swift
//  TikTok
//
//  Created by Osaretin Uyigue on 11/28/20.
//  Copyright © 2020 Osaretin Uyigue. All rights reserved.
//

//
//  CollectionViewCell
//
//  Created by Osaretin Uyigue on 4/29/19.
//  Copyright © 2019 Osaretin Uyigue. All rights reserved.
//

import UIKit
import Photos
class MediaPickerVideoBaseCell: MediaPickerBaseCell {
    
    //MARK: - Init
  
    
    
    
    
    //MARK: - Properties
   
    
    
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! MediaPickerCell
        let asset = videoAssets[indexPath.item]
        let width = (frame.width) / 2.8
        let size = CGSize(width: width, height: width)
        cell.imageView.image = getAssetThumbnail(asset: asset, size: size)
        cell.phAsset = asset
        // Clear previous duration text
        cell.videoDurationLabel.text = "--:--" // Placeholder

        // Asynchronously load duration and update cell
        // TODO: This Task should be managed by the cell itself if it can be recycled before completion.
        Task {
            do {
                let duration = try await asset.load(.duration)
                let durationInSeconds = CMTimeGetSeconds(duration)
                if durationInSeconds.isFinite && !durationInSeconds.isNaN {
                    let minutes = Int(durationInSeconds / 60)
                    let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
                    let videoLengthString = String(format: "%02d:%02d", minutes, seconds)

                    // Ensure cell is still displaying this asset's data
                    if cell.phAsset == asset {
                        await MainActor.run {
                            cell.videoDurationLabel.text = videoLengthString
                        }
                    }
                } else {
                    if cell.phAsset == asset {
                        await MainActor.run {
                            cell.videoDurationLabel.text = "00:00"
                        }
                    }
                }
            } catch {
                print("Error loading duration for asset \(asset.localIdentifier): \(error)")
                if cell.phAsset == asset {
                    await MainActor.run {
                        cell.videoDurationLabel.text = "00:00" // Or some error indicator
                    }
                }
            }
        }
        return cell
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoAssets.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
           return videoAssets.isEmpty == true ? CGSize(width: frame.width, height: frame.width) : .zero
       }
    
   
}
