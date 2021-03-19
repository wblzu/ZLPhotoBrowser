//
//  ZLBWThumbnailViewController.swift
//  Example
//


import UIKit
import Photos
import ZLPhotoBrowser

@objc public enum ZLURLType: Int {
    case image
    case video
}

public class ZLBWThumbnailViewController: UIViewController {

    static let colItemSpacing: CGFloat = 40
    
    static let selPhotoPreviewH: CGFloat = 100
    
    let datas: [Any]
    
    let urlType: ( (URL) -> ZLURLType )?
    
    let urlImageLoader: ( (URL, UIImageView, @escaping ( (CGFloat) -> Void ), @escaping ( () -> Void )) -> Void )?
    
    var currentIndex: Int
    
    var indexBeforOrientationChanged: Int
    
    var collectionView: UICollectionView!
    
//    var isFirstAppear = true
    
    @objc public var doneBlock: ( ([Any]) -> Void )?
    
    var orientation: UIInterfaceOrientation = .unknown
    
    public override var prefersStatusBarHidden: Bool {
        return !ZLPhotoConfiguration.default().showStatusBarInPreviewInterface
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return ZLPhotoConfiguration.default().statusBarStyle
    }
    
    /// - Parameters:
    ///   - datas: Must be one of PHAsset, UIImage and URL, will filter ohers in init function.
    ///   - showBottomView: If showSelectBtn is true, showBottomView is always true.
    ///   - index: Index for first display.
    ///   - urlType: Tell me the url is image or video.
    ///   - urlImageLoader: Called when cell will display, cell will layout after callback when image load finish. The first block is progress callback, second is load finish callback.
    @objc public init(datas: [Any], index: Int = 0, showSelectBtn: Bool = true, showBottomView: Bool = true, urlType: ( (URL) -> ZLURLType )? = nil, urlImageLoader: ( (URL, UIImageView, @escaping ( (CGFloat) -> Void ),  @escaping ( () -> Void )) -> Void )? = nil) {
        let filterDatas = datas.filter { (obj) -> Bool in
            return obj is PHAsset || obj is UIImage || obj is URL
        }
        self.datas = filterDatas
        self.currentIndex = index >= filterDatas.count ? 0 : index
        self.indexBeforOrientationChanged = self.currentIndex
        self.urlType = urlType
        self.urlImageLoader = urlImageLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.frame = CGRect(x: -ZLPhotoPreviewController.colItemSpacing / 2, y: 0, width: self.view.frame.width + ZLPhotoPreviewController.colItemSpacing, height: self.view.frame.height)
        
        let ori = UIApplication.shared.statusBarOrientation
        if ori != self.orientation {
            self.orientation = ori
        }
    }
    
    private func setupUI() {
        // collection view
        let layout = UICollectionViewFlowLayout()
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.view.addSubview(self.collectionView)
        
        ZLPhotoPreviewCell.zl_register(self.collectionView)
        ZLGifPreviewCell.zl_register(self.collectionView)
        ZLLivePhotoPreviewCell.zl_register(self.collectionView)
        ZLVideoPreviewCell.zl_register(self.collectionView)
        ZLLocalImagePreviewCell.zl_register(self.collectionView)
        ZLNetImagePreviewCell.zl_register(self.collectionView)
        ZLNetVideoPreviewCell.zl_register(self.collectionView)
    }
    
    func tapPreviewCell() {
        let currentCell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0))
        if let cell = currentCell as? ZLVideoPreviewCell {
            if cell.isPlaying {
        
            }
        }
    }
    
}


extension ZLBWThumbnailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return ZLLayout.thumbCollectionViewItemSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return ZLLayout.thumbCollectionViewLineSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let defaultCount = CGFloat(ZLPhotoConfiguration.default().columnCount)
        var columnCount: CGFloat = deviceIsiPad() ? (defaultCount+2) : defaultCount
        if UIApplication.shared.statusBarOrientation.isLandscape {
            columnCount += 2
        }
        let totalW = collectionView.bounds.width - (columnCount - 1) * ZLLayout.thumbCollectionViewItemSpacing
        let singleW = totalW / columnCount
        return CGSize(width: singleW, height: singleW)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datas.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let config = ZLPhotoConfiguration.default()
        let obj = self.datas[indexPath.row]
        
        let baseCell: ZLPreviewBaseCell
        
        if let asset = obj as? PHAsset {
            let model = ZLPhotoModel(asset: asset)
            
            if config.allowSelectGif, model.type == .gif {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLGifPreviewCell.zl_identifier(), for: indexPath) as! ZLGifPreviewCell
                
//                cell.singleTapBlock = { [weak self] in
//                    self?.tapPreviewCell()
//                }
                
                cell.model = model
                baseCell = cell
            } else if config.allowSelectLivePhoto, model.type == .livePhoto {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLLivePhotoPreviewCell.zl_identifier(), for: indexPath) as! ZLLivePhotoPreviewCell
                
                cell.model = model
                
                baseCell = cell
            } else if config.allowSelectVideo, model.type == .video {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLVideoPreviewCell.zl_identifier(), for: indexPath) as! ZLVideoPreviewCell
                
                cell.model = model
                
                baseCell = cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLPhotoPreviewCell.zl_identifier(), for: indexPath) as! ZLPhotoPreviewCell

//                cell.singleTapBlock = { [weak self] in
//                    self?.tapPreviewCell()
//                }

                cell.model = model

                baseCell = cell
            }
            
            return baseCell
        } else if let image = obj as? UIImage {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLLocalImagePreviewCell.zl_identifier(), for: indexPath) as! ZLLocalImagePreviewCell
            
            cell.image = image
            
            baseCell = cell
        } else if let url = obj as? URL {
            let type = self.urlType?(url) ?? ZLURLType.image
            if type == .image {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLNetImagePreviewCell.zl_identifier(), for: indexPath) as! ZLNetImagePreviewCell
                cell.image = nil
                
                self.urlImageLoader?(url, cell.preview.imageView, { [weak cell] (progress) in
                    DispatchQueue.main.async {
                        cell?.progress = progress
                    }
                }, { [weak cell] in
                    DispatchQueue.main.async {
                        cell?.preview.resetSubViewSize()
                    }
                })
                
                baseCell = cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLNetVideoPreviewCell.zl_identifier(), for: indexPath) as! ZLNetVideoPreviewCell
                
                cell.videoUrl = url
                
                baseCell = cell
            }
        } else {
            #if DEBUG
            fatalError("Preview obj must one of PHAsset, UIImage, URL")
            #else
            return UICollectionViewCell()
            #endif
        }
        
//        baseCell.singleTapBlock = { [weak self] in
//            self?.tapPreviewCell()
//        }
//
//        (baseCell as? ZLLocalImagePreviewCell)?.longPressBlock = { [weak self] in
//            self?.showSaveImageAlert()
//        }
        
        return baseCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let c = cell as? ZLPreviewBaseCell {
            c.resetSubViewStatusWhenCellEndDisplay()
        }
    }
    
    func showSaveImageAlert() {
        func saveImage() {
            guard let cell = self.collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0)) as? ZLLocalImagePreviewCell, let image = cell.currentImage else {
                return
            }
            let hud = ZLProgressHUD(style: ZLPhotoConfiguration.default().hudStyle)
            hud.show()
            ZLPhotoManager.saveImageToAlbum(image: image) { [weak self] (suc, _) in
                hud.hide()
                if !suc {
                    showAlertView(localLanguageTextValue(.saveImageError), self)
                }
            }
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let save = UIAlertAction(title: localLanguageTextValue(.save), style: .default) { (_) in
            saveImage()
        }
        let cancel = UIAlertAction(title: localLanguageTextValue(.cancel), style: .cancel, handler: nil)
        alert.addAction(save)
        alert.addAction(cancel)
        self.showDetailViewController(alert, sender: nil)
    }
    
}
