//
//  GoalTableViewCell.swift
//  BeeSwift
//
//  Created by Andy Brett on 4/24/15.
//  Copyright (c) 2015 APB. All rights reserved.
//

import Foundation

class GoalCollectionViewCell: UICollectionViewCell {
    var slugLabel :BSLabel = BSLabel()
    var titleLabel :BSLabel = BSLabel()
    var thumbnailImageView :UIImageView = UIImageView()
    var deltasLabel :BSLabel = BSLabel()
    var countdownView :UIView = UIView()
    var countdownLabel :BSLabel = BSLabel()
    let margin = 8
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.slugLabel)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.thumbnailImageView)
        self.contentView.addSubview(self.deltasLabel)
        self.contentView.addSubview(self.countdownView)
        self.countdownView.addSubview(self.countdownLabel)
        if #available(iOS 13.0, *) {
            self.contentView.backgroundColor = .systemBackground
        }
        self.slugLabel.font = UIFont(name: "Avenir-Heavy", size: 18)
        self.slugLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.margin)
            make.top.equalTo(10)
            make.width.lessThanOrEqualTo(self.contentView).multipliedBy(0.35)
        }
        if #available(iOS 13.0, *) {
            self.slugLabel.textColor = .label
        }
        
        self.titleLabel.font = UIFont(name: "Avenir-Light", size: 18)
        if #available(iOS 13.0, *) {
            self.titleLabel.textColor = .label
        }
        self.titleLabel.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(self.slugLabel)
            make.left.equalTo(self.slugLabel.snp.right).offset(10)
            make.width.lessThanOrEqualTo(self.contentView).multipliedBy(0.6)
        }
        self.titleLabel.textAlignment = .right
        
        self.countdownView.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(8)
            make.top.equalTo(self.slugLabel.snp.bottom).offset(5)
            make.bottom.equalTo(self.thumbnailImageView)
            make.width.equalTo(75)
        }
        
        self.countdownView.addSubview(self.countdownLabel)
        self.countdownLabel.textColor = UIColor.white
        self.countdownLabel.font = UIFont(name: "Avenir-Heavy", size: 18)
        self.countdownLabel.snp.makeConstraints { (make) -> Void in
            make.center.equalTo(self.countdownView)
        }

        self.thumbnailImageView.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.countdownView.snp.right).offset(self.margin)
            make.top.equalTo(self.countdownView)
            make.height.equalTo(Constants.thumbnailHeight)
            make.width.equalTo(Constants.thumbnailWidth)
        }

        self.deltasLabel.textAlignment = NSTextAlignment.center
        self.deltasLabel.font = UIFont(name: "Avenir-Black", size: 13)
        self.deltasLabel.numberOfLines = 0
        self.deltasLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.thumbnailImageView.snp.right).offset(5)
            make.centerY.equalTo(self.thumbnailImageView.snp.centerY)
            make.right.equalTo(-self.margin)
        }
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GoalCollectionViewCell.refreshCountdown), userInfo: nil, repeats: true)
    }
        
    func deadbeatChanged() {
        self.setThumbnailImage()
    }
    
    func refreshCountdown() {
        if self.goal == nil { return }
        self.deltasLabel.text = self.goal!.baremin! + " " + self.goal!.countdownHelperText + "\n" + String(self.goal!.countdownText)
    }
    
    func setThumbnailImage() {
        guard let _ = self.goal else { return }
        if CurrentUserManager.sharedManager.isDeadbeat() {
            self.thumbnailImageView.image = UIImage(named: "ThumbnailPlaceholder")
        } else {
            self.thumbnailImageView.af_setImage(withURL: URL(string: self.goal!.cacheBustingThumbUrl)!, placeholderImage: UIImage(named: "ThumbnailPlaceholder"), filter: nil, progress: nil, progressQueue: DispatchQueue.global(), imageTransition: .noTransition, runImageTransitionIfCached: false, completion: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    var goal: JSONGoal? {
        didSet {
            self.thumbnailImageView.image = nil
            self.setThumbnailImage()
            
            if goal == nil {
                self.countdownLabel.text = ""
                self.countdownView.backgroundColor = UIColor.beeGrayColor()
            } else {
                self.countdownLabel.text = goal!.briefLosedate
                self.countdownView.backgroundColor = goal!.countdownColor
            }
            
            self.titleLabel.text = goal?.title
            self.slugLabel.text = goal?.slug
            self.titleLabel.isHidden = goal?.title == goal?.slug
            self.deltasLabel.text = goal!.baremin! + " " + goal!.countdownHelperText + "\n" + String(goal!.countdownText)
        }
    }
}
