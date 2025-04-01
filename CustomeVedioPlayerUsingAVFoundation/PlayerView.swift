//
//  PlayerView.swift
//  CustomeVedioPlayerUsingAVFoundation
//
//  Created by Akshaya Gunnepalli on 28/03/25.
//


import Foundation
import AVFoundation
import UIKit
import AVKit
let APP_DELEGATE = UIApplication.shared.delegate as? AppDelegate ?? AppDelegate()
class PlayerView: UIView {
    
    var viewController : UIViewController?
    
    let playerViewController =  AVPlayerViewController()
    /// For Resuming And Sliding the Vedio
     var operatingStackView : VedioOperatingView = {
         var stackView = VedioOperatingView()
         stackView.setupStack()
         return stackView
     }()
    
    /// For Play and Pause the vedio
     var pauseAndPlayView : PlayPauseVedioView = {
        var stackView = PlayPauseVedioView()
         stackView.setupPlayPause()
        return stackView
     }()
  
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame =  self.bounds
        playerLayer.videoGravity = .resizeAspectFill
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUI()
    }
   
    /// UI Components
    func setUI() {
        self.backgroundColor = .black
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        pauseAndPlayView.isHidden = true // initially hide puase view
        setConstraints()
        addActions()
    }
    
    func loadVideo(viewController:UIViewController) {
        self.viewController = viewController
        guard let url = URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4") else { return }
        player = AVPlayer(url: url)
        
        let interval = CMTime(seconds: 1, preferredTimescale: 600)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(self?.player?.currentItem?.duration ?? CMTime.zero)
            self?.operatingStackView.progressView.value = Float(currentTime / duration)
        }
        setupObserver()
    }
   
    
    func setConstraints() {
        
        self.addSubview(operatingStackView)
        operatingStackView.setconstraints(stackView: operatingStackView, view: self, height: 30, bottum: -10, trailing: -10, leading: 10)

        self.addSubview(pauseAndPlayView)
        pauseAndPlayView.setconstraints(stackView: pauseAndPlayView, view: self, height: 60, bottum: -(self.frame.height / 2.5), trailing: -(self.frame.width / 4), leading: (self.frame.width / 4))
    }
    
    /// Provide Required Actions
    func addActions() {
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(tapgeture))
        self.addGestureRecognizer(tapgesture)
        
        self.operatingStackView.progressView.isUserInteractionEnabled = true
        self.operatingStackView.progressView.addTarget(nil, action: #selector(sliderValueChanges), for: .valueChanged)
        self.operatingStackView.progressView.addTarget(nil, action: #selector(slidertapped), for: .touchDown)
        self.operatingStackView.progressView.addTarget(nil, action: #selector(sliderReleased), for: .touchUpInside)
        self.operatingStackView.soundControll.addTarget(self, action: #selector(muteAndUnmute), for: .touchUpInside)
        self.operatingStackView.fullScreenButton.addTarget(self, action: #selector(handleLandscapeMode), for: .touchUpInside)
        
        self.pauseAndPlayView.pauseAndPlayButton.addTarget(self, action: #selector(playAndPause), for: .touchUpInside)
        self.pauseAndPlayView.postViewButton.addTarget(self, action: #selector(seekForward), for: .touchUpInside)
        self.pauseAndPlayView.preViewButton.addTarget(self, action: #selector(seekBackward), for: .touchUpInside)
    }

    
    /// Hide and show Pause and Play View
    @objc
    func tapgeture(){
        pauseAndPlayView.isHidden = !pauseAndPlayView.isHidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            UIView.animate(withDuration: 0.5) {
                self.pauseAndPlayView.isHidden = true
            }
        }
    }
    
    
    /// Hide and show Pause and Play View
    @objc
    func playAndPause(){
        self.pauseAndPlayView.pauseAndPlayButton.animateClick {
            self.pauseAndPlayView.pauseAndPlayButton.isSelected.toggle()
        }
        if self.pauseAndPlayView.pauseAndPlayButton.isSelected {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    /// Hide and show Pause and Play View
    @objc
    func muteAndUnmute(){
        self.operatingStackView.soundControll.animateClick {
            self.operatingStackView.soundControll.isSelected.toggle()
            DispatchQueue.main.async {
                self.player?.isMuted = self.operatingStackView.soundControll.isSelected
            }
        }
    }
    
    @objc func sliderValueChanges(_ slider: UISlider) {
        let value = slider.value
        let duration = CMTimeGetSeconds(player?.currentItem?.duration ?? CMTime.zero)
        let seekTime = CMTime(seconds: Double(value) * duration, preferredTimescale: 1000)
        player?.seek(to: seekTime)
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: operatingStackView.progressView)
        let percentage = location.x / operatingStackView.progressView.bounds.width
        operatingStackView.progressView.value = Float(percentage)
        sliderValueChanges(operatingStackView.progressView)
    }
    
    @objc func slidertapped(_ slider: UISlider){
        player?.pause()
    }
    @objc func sliderReleased(_ slider: UISlider){
        player?.play()
        sliderValueChanges(slider)
    }
    
    
    @objc
    func handleLandscapeMode(sender:UIButton) {
        sender.isSelected = !sender.isSelected
        guard let viewController = self.viewController else {
            return
        }
        playerViewController.player = player
        playerViewController.delegate = self
        playerViewController.modalPresentationStyle = .fullScreen
        APP_DELEGATE.isVideoPlaying = true
        viewController.present(playerViewController, animated: true) 
    }

      /// Seeking video 15 seconds backward
    @objc func seekBackward() {
        let currentTime = CMTimeGetSeconds(player?.currentTime() ?? CMTime())
        var newTime = currentTime - 14.0
        
        if newTime < 0 {
            newTime = 0
        }
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        player?.seek(to: time)
    }
    
    /// Seeking video 15 seconds forward
    @objc func seekForward() {
        guard let duration = player?.currentItem?.duration else {
            return
        }
        
        let currentTime = CMTimeGetSeconds(player?.currentTime() ?? CMTime())
        var newTime = currentTime + 15.0
        
        if newTime > CMTimeGetSeconds(duration) {
            newTime = CMTimeGetSeconds(duration)
        }
        let time: CMTime = CMTime(value: Int64(newTime * 1000), timescale: 1000)
        player?.seek(to: time)
    }
    
    /// Adding an observer to get video time periodically
    func setupObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let main = DispatchQueue.main
        
        _ = player?.addPeriodicTimeObserver(forInterval: interval, queue: main, using: { [weak self] (time) in
            
            
            guard let weakself = self else { return }
            guard let currentItem = weakself.player?.currentItem else { return }

            // upadate  video with slider
            let duration = CMTimeGetSeconds(currentItem.duration)
            let currentTime = CMTimeGetSeconds(time)
            let progress = Float(currentTime / duration)
            self?.operatingStackView.progressView.value = progress
            
            // Updating the TimeValue
            let currentTimeString = weakself.formatTime(time: time, total: false)
            self?.operatingStackView.timeLable.text = currentTimeString
            let totalTime = weakself.formatTime(time: currentItem.duration, total: true)
            self?.operatingStackView.totaltimeLable.text = totalTime
            
        })
    }
    
    func formatTime(time: CMTime,total:Bool) -> String {
        
        let totalSeconds = CMTimeGetSeconds(time)
         if !totalSeconds.isNaN && !totalSeconds.isInfinite {
            let hours = Int((totalSeconds) / 3600)
            let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
            let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
              if hours != 0 {
                 if total {
                    return String(format: "%2d:%02d:%02d",hours, minutes, seconds)
                } else {
                    return String(format: "%2d:%02d:%02d", hours, minutes, seconds)
                }
             } else {
                 if total {
                    return String(format: "%02d:%02d",minutes, seconds)
                } else {
                    return String(format: "%02d:%02d",minutes, seconds)
                }
             }
             
        } else {
             return ""
        }
    }
 
}
/// Determines if video is still playing
extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}
extension PlayerView : AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
         rotateToLandsScapeDevice()
        if let play = playerViewController.player?.isPlaying  {
            if play {
                self.player?.play()
            } else {
                self.player?.pause()
            }
        }
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        rotateToPotraitDevice()
        if let play = playerViewController.player?.isPlaying  {
            if play {
                self.player?.play()
            } else {
                self.player?.pause()
            }
        }
    }
}

extension PlayerView {

    func rotateToLandsScapeDevice() {
 
         UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        UIView.setAnimationsEnabled(true)
    }
    
    func rotateToPotraitDevice() {
 
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIView.setAnimationsEnabled(true)
    }
}
class VedioOperatingView : CommonStack {
    
    var progressView: UISlider = {
        var progressView = UISlider()
        progressView.minimumValue = 0
        progressView.maximumValue = 1
        progressView.tintColor = UIColor.systemMint
        progressView.maximumTrackTintColor = .lightGray
        progressView.isContinuous = false
        let thumbSize = CGSize(width: 10, height: 10)
        let thumbImage = UIGraphicsImageRenderer(size: thumbSize).image { _ in
           UIColor.white.setFill()
           UIBezierPath(ovalIn: CGRect(origin: .zero, size: thumbSize)).fill()
        }
        progressView.setThumbImage(thumbImage, for: .normal)
        return progressView
    }()
    var timeLable : UILabel = {
        var label = UILabel()
        label.textColor = .white
        label.widthAnchor.constraint(equalToConstant: 45).isActive = true
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "00:00"
        return label
    }()
    var totaltimeLable : UILabel = {
        var label = UILabel()
        label.textColor = .white
        label.widthAnchor.constraint(equalToConstant: 45).isActive = true
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "00:00"
        return label
    }()
    var fullScreenButton : UIButton = {
        var button = UIButton()
        button.isSelected = false
        button.setImage(UIImage(systemName: "arrow.down.left.and.arrow.up.right.rectangle"), for: .normal)
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.tintColor = .white
        button.tag = 105
        return button
    }()
    var soundControll : UIButton = {
        var button = UIButton()
        button.isSelected = false
        button.setImage(UIImage(systemName: "speaker.wave.2"), for: .normal)
        button.setImage(UIImage(systemName: "speaker.slash"), for: .selected)
        button.tag = 103
        button.widthAnchor.constraint(equalToConstant: 20).isActive = true
        button.tintColor = .white
        return button
    }()
    
    var settings : UIButton = {
        var button = UIButton()
        button.isSelected = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "gearshape")?.withTintColor(.white, renderingMode: .alwaysTemplate), for: .normal)
        button.tag = 103
        button.tintColor = .white
        return button
    }()
    
    
    
    var settingsView : UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 30).isActive = true
        return view
    }()
    
    func setupStack() {
        self.translatesAutoresizingMaskIntoConstraints = true
        self.distribution = .fill
        self.backgroundColor = .gray.withAlphaComponent(0.5)
        self.spacing = 5
        self.layer.cornerRadius = 5
        //AddSubViews
        
        self.addArrangedSubview(timeLable)
        
        let view = UIView()
        view.frame.size.width = self.frame.width - 120
        view.addSubview(progressView)
        setconstraints(stackView: progressView, view: view, height: 15, bottum: -7.5, trailing: 0, leading: 0)
        self.addArrangedSubview(view)
        
        self.addArrangedSubview(totaltimeLable)
        
        self.addArrangedSubview(settingsView)
        
        self.addArrangedSubview(soundControll)
        
        self.addArrangedSubview(fullScreenButton)
        
        settingsView.addSubview(settings)
        settings.centerYAnchor.constraint(equalTo: settingsView.centerYAnchor, constant: 0).isActive = true
        settings.centerXAnchor.constraint(equalTo: settingsView.centerXAnchor, constant: 0).isActive = true
        settings.widthAnchor.constraint(equalToConstant: 20).isActive = true
        settings.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
}
class PlayPauseVedioView : CommonStack {
    
    var preViewButton : UIButton = {
        var btn = UIButton()
        btn.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        btn.tag = 101
        return btn
    }()
    var postViewButton : UIButton = {
        var btn = UIButton()
        btn.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        btn.tag = 102
        return btn
    }()
    var pauseAndPlayButton : UIButton = {
        var btn = UIButton()
        btn.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .selected)
        btn.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 60).isActive = true
        btn.tag = 104
        btn.imageView?.contentMode = .scaleToFill
        return btn
    }()
    func setupPlayPause(){
        self.translatesAutoresizingMaskIntoConstraints = true
        self.distribution = .fillEqually
        self.spacing = 10
        self.backgroundColor = .clear
        self.tintColor = .white
        
        // AddSubviews
        
        self.addArrangedSubview(preViewButton)
        
        let view = UIView()
        view.addSubview(pauseAndPlayButton)
        pauseAndPlayButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        pauseAndPlayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.addArrangedSubview(view)
        
        self.addArrangedSubview(postViewButton)
    }
    
}
class CommonStack : UIStackView {
    var callBack: ((_ sender:UIButton) -> Void)?
    
    func setconstraints(stackView:UIView,view:UIView,height:CGFloat,bottum:CGFloat,trailing:CGFloat,leading:CGFloat) {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: height),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leading),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: trailing),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottum),
        ])
    }
}
extension UIButton {
    
    /// For scaling animation while toggle the button

    func animateClick(completion: (() -> Void)? = nil) {
        completion?()
        // Perform a smooth scale-down animation
        UIView.animate(withDuration: 0.15, animations: {
            self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            // Restore to original size with a spring effect
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.8,
                           options: [],
                           animations: {
                self.transform = .identity
            })
        }
    }
    
}
