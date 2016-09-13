//
//  GuruMeditationFault
//
//  Created by Alex Usbergo on 02/05/16.
//
//  Copyright (c) 2016 Alex Usbergo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public struct Guru {

  public static func error(_ message: String,
                           includeStack: Bool = false) {
    let vc = GuruMeditationViewController()
    let message = formatMessage(message, stack: includeStack ? Thread.callStackSymbols : [])
    vc.errorMessage = message
    vc.style = .Error
    vc.didTapClosure = {
      fatalError(message)
    }
    OverlayWindow.presentModalOverlay(vc)
  }

  public static func warning(_ message: String,
                             includeStack: Bool = false,
                             closure: ((Void) -> Void)? = nil) {
    let message = formatMessage(message, stack: includeStack ? Thread.callStackSymbols: [])
    let vc = GuruMeditationViewController()
    vc.errorMessage = message
    vc.style = .Warning
    vc.didTapClosure = {
      OverlayWindow.dismissModalOverlay()
      closure?()
    }
    OverlayWindow.presentModalOverlay(vc)
  }

  fileprivate static func formatMessage(_ message: String, stack: [String]) -> String {
    return stack.isEmpty
      ? message
      : "\(message)\n\n\(stack.map({"\n\($0)\n"}).joined(separator: "\n"))"
  }
}

// MARK: - Controller

internal class GuruMeditationViewController: UIViewController {

  internal enum Style: String {
    case Warning = "Software Warning. Tap to continue.\n\n"
    case Error = "Software Failure. Tap to crash.\n\nGuru Meditation \n\n"
  }

  override internal class func initialize() {
    Bundle.loadTopazFont()
  }

  internal var errorMessage: String = "" {
    didSet {
      updateErrorLabelText(errorMessage)
    }
  }

  internal var style: Style = .Error {
    didSet {
      self.updateErrorLabelText(self.errorMessage)
    }
  }

  fileprivate func updateErrorLabelText(_ message: String = "No error description.") {
    self.errorLabel.text = self.style.rawValue + message
  }

  fileprivate lazy var errorLabel: InsetLabel = {
    let label = InsetLabel()
    label.numberOfLines = 0
    label.font = UIFont.topazFontOfSize(14)
    label.textColor = UIColor.red
    label.layer.borderColor = label.textColor.cgColor
    label.backgroundColor = UIColor.black
    label.textAlignment = .center
    return label
  }()

  fileprivate lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.backgroundColor = UIColor.black
    scrollView.bounces = false
    return scrollView
  }()

  internal var didTapClosure: ((Void) -> (Void))?

  fileprivate dynamic func gestureRecognizerDidTap() {
    self.didTapClosure?()
  }

  internal required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.updateErrorLabelText()
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.updateErrorLabelText()
  }

  override internal func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.black
    self.view.addSubview(self.scrollView)
    self.scrollView.addSubview(self.errorLabel)
    self.view.addGestureRecognizer(UITapGestureRecognizer(
        target: self,
        action: #selector(GuruMeditationViewController.gestureRecognizerDidTap)))
  }

  override internal func viewDidLayoutSubviews() {
    let margin: CGFloat = 16
    var frame = self.view.bounds.insetBy(dx: margin, dy: margin)
    frame.size.height = self.errorLabel.sizeThatFits(frame.size).height + margin * 4
    self.scrollView.frame = self.view.bounds
    self.scrollView.contentSize.height = self.errorLabel.frame.maxY
    self.errorLabel.frame = frame
  }

  internal override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    flash()
  }

  fileprivate func flash() {
    self.errorLabel.textColor = self.style == .Error
        ? UIColor.red
        : UIColor.yellow
    self.errorLabel.layer.borderColor = self.errorLabel.textColor.cgColor
    self.errorLabel.layer.borderWidth = self.errorLabel.layer.borderWidth > 0 ? 0 : 6
    delay(0.5) { [weak self] in
      self?.flash()
    }
  }
}

private func delay(_ delay: Double, closure:@escaping ()->()) {
  DispatchQueue.main.asyncAfter(
      deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
      execute: closure)
}

// MARK: - Extensions

private extension Bundle {

  class func guruMeditationFaultBundle() -> Bundle {
    var bundle = Bundle()
    var predicate = Int()
    let mainBundlePath = Bundle.main.bundlePath
    let frameworkBundlePath =
      mainBundlePath + "/Frameworks/GuruMeditation.framework/"
    bundle = Bundle(path: frameworkBundlePath)!
    return bundle
  }

  class func loadTopazFont() -> Bool {
    let fontPath = self.guruMeditationFaultBundle().path(forResource: "Topaz", ofType: "ttf")!
    let inData = try? Data(contentsOf: URL(fileURLWithPath: fontPath))
    var error: Unmanaged<CFError>?
    let provider = CGDataProvider(data: inData as! CFData)
    let font = CGFont(provider!)
    CTFontManagerRegisterGraphicsFont(font, &error)
    return error != nil
  }
}

private extension UIFont {

  class func topazFontOfSize(_ size: CGFloat) -> UIFont {
    let font: UIFont? = UIFont(name: "TopazPlus a600a1200a4000", size: size)
    return font ?? UIFont.boldSystemFont(ofSize: size)
  }
}

private class InsetLabel: UILabel {

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  override func drawText(in rect: CGRect) {
    let margin: CGFloat = 16
    let insets = UIEdgeInsets.init(top: margin, left: margin, bottom: margin, right: margin)
    super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

//MARK: - Overlay Window

internal class OverlayWindow {

  var containedViewController: UIViewController {
    return overlayViewController.containedViewController
  }

  fileprivate var overlayWindow: UIWindow? = {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.isHidden = false
    return window
  }()

  fileprivate let overlayViewController: OverlayViewController

  init(containedViewController: UIViewController) {
    self.overlayViewController =
      OverlayViewController(containedViewController: containedViewController)
    self.overlayWindow?.rootViewController = self.overlayViewController
  }

  deinit {
    dismiss()
  }

  /** Force the dismissal of the overlay window. */
  func dismiss() {
    overlayWindow?.autoresizingMask = UIViewAutoresizing()
    overlayWindow?.autoresizesSubviews = false
    overlayWindow?.frame = CGRect.zero
    overlayWindow?.isHidden = true
    overlayWindow?.rootViewController = nil
    overlayWindow = nil
  }
}

internal extension OverlayWindow {

  /** Convenience storage for the modal overlays (likely interstitials). */
  static var sharedModalOverlay: OverlayWindow?

  /** Application-wide function used to show an interstitial screen. */
  static func presentModalOverlay(_ viewController: UIViewController) {
    OverlayWindow.sharedModalOverlay =
      OverlayWindow(containedViewController: viewController)
  }

  /** Dismiss the interstitial screen. */
  static func dismissModalOverlay() {
    OverlayWindow.sharedModalOverlay = nil
  }
}

internal class OverlayViewController: UIViewController {

  required init?(coder aDecoder: NSCoder) {
    fatalError("storyboards not supported")
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    fatalError("The default init is not available for this controller.")
  }

  fileprivate let containedViewController: UIViewController

  required init(containedViewController: UIViewController) {
    self.containedViewController = containedViewController
    super.init(nibName: nil, bundle: nil)
  }

  deinit {
    containedViewController.willMove(toParentViewController: nil)
    containedViewController.view.removeFromSuperview()
    containedViewController.removeFromParentViewController()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addChildViewController(self.containedViewController)
    containedViewController.view.frame = view.frame
    view.addSubview(containedViewController.view)
    containedViewController.didMove(toParentViewController: self)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateContainedViewControllerLayout()
  }

  fileprivate func updateContainedViewControllerLayout() {
    containedViewController.view.frame = view.bounds
    view.backgroundColor = UIColor.clear
  }

  // MARK - Forwarding Methods to Child Controllers

  override func shouldAutomaticallyForwardRotationMethods() -> Bool {
    return true
  }

  override var shouldAutomaticallyForwardAppearanceMethods : Bool {
    return true
  }

  override var shouldAutorotate : Bool {
    return true
  }

  override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.allButUpsideDown
  }

  // MARK - Status bar configuration

  override var childViewControllerForStatusBarStyle : UIViewController? {
    return containedViewController
  }

  override var childViewControllerForStatusBarHidden : UIViewController? {
    return containedViewController
  }
  
}

