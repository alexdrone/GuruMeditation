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

  public static func error(message: String,
                           includeStack: Bool = false) {
    let vc = GuruMeditationViewController()
    let message = formatMessage(message, stack: includeStack ? NSThread.callStackSymbols() : [])
    vc.errorMessage = message
    vc.style = .Error
    vc.didTapClosure = {
      fatalError(message)
    }
    OverlayWindow.presentModalOverlay(vc)
  }

  public static func warning(message: String,
                             includeStack: Bool = false,
                             closure: ((Void) -> Void)? = nil) {
    let message = formatMessage(message, stack: includeStack ? NSThread.callStackSymbols(): [])
    let vc = GuruMeditationViewController()
    vc.errorMessage = message
    vc.style = .Warning
    vc.didTapClosure = {
      OverlayWindow.dismissModalOverlay()
      closure?()
    }
    OverlayWindow.presentModalOverlay(vc)
  }

  private static func formatMessage(message: String, stack: [String]) -> String {
    return stack.isEmpty
      ? message
      : "\(message)\n\n\(stack.map({"\n\($0)\n"}).joinWithSeparator("\n"))"
  }
}

// MARK: - Controller

internal class GuruMeditationViewController: UIViewController {

  internal enum Style: String {
    case Warning = "Software Warning. Tap to continue.\n\n"
    case Error = "Software Failure. Tap to crash.\n\nGuru Meditation \n\n"
  }

  override internal class func initialize() {
    NSBundle.loadTopazFont()
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

  private func updateErrorLabelText(message: String = "No error description.") {
    self.errorLabel.text = self.style.rawValue + message
  }

  private lazy var errorLabel: InsetLabel = {
    let label = InsetLabel()
    label.numberOfLines = 0
    label.font = UIFont.topazFontOfSize(14)
    label.textColor = UIColor.redColor()
    label.layer.borderColor = label.textColor.CGColor
    label.backgroundColor = UIColor.blackColor()
    label.textAlignment = .Center
    return label
  }()

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.backgroundColor = UIColor.blackColor()
    scrollView.bounces = false
    return scrollView
  }()

  internal var didTapClosure: ((Void) -> (Void))?

  private dynamic func gestureRecognizerDidTap() {
    self.didTapClosure?()
  }

  internal required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.updateErrorLabelText()
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.updateErrorLabelText()
  }

  override internal func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.blackColor()
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
    self.scrollView.contentSize.height = CGRectGetMaxY(self.errorLabel.frame)
    self.errorLabel.frame = frame
  }

  internal override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    flash()
  }

  private func flash() {
    self.errorLabel.textColor = self.style == .Error
        ? UIColor.redColor()
        : UIColor.yellowColor()
    self.errorLabel.layer.borderColor = self.errorLabel.textColor.CGColor
    self.errorLabel.layer.borderWidth = self.errorLabel.layer.borderWidth > 0 ? 0 : 6
    delay(0.5) { [weak self] in
      self?.flash()
    }
  }
}

private func delay(delay: Double, closure:()->()) {
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
      dispatch_get_main_queue(),
      closure)
}

// MARK: - Extensions

private extension NSBundle {

  class func guruMeditationFaultBundle() -> NSBundle {
    var bundle = NSBundle()
    var predicate = dispatch_once_t()
    dispatch_once(&predicate) {
      let mainBundlePath = NSBundle.mainBundle().bundlePath
      let frameworkBundlePath =
        mainBundlePath.stringByAppendingString("/Frameworks/GuruMeditation.framework/")
      bundle = NSBundle(path: frameworkBundlePath)!
    }
    return bundle
  }

  class func loadTopazFont() -> Bool {
    let fontPath = self.guruMeditationFaultBundle().pathForResource("Topaz", ofType: "ttf")!
    let inData = NSData(contentsOfFile:fontPath)
    var error: Unmanaged<CFError>?
    let provider = CGDataProviderCreateWithCFData(inData)
    if let font = CGFontCreateWithDataProvider(provider) {
      CTFontManagerRegisterGraphicsFont(font, &error)
      return error != nil
    }
    return true
  }
}

private extension UIFont {

  class func topazFontOfSize(size: CGFloat) -> UIFont {
    let font: UIFont? = UIFont(name: "TopazPlus a600a1200a4000", size: size)
    return font ?? UIFont.boldSystemFontOfSize(size)
  }
}

private class InsetLabel: UILabel {

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  override func drawTextInRect(rect: CGRect) {
    let margin: CGFloat = 16
    let insets = UIEdgeInsets.init(top: margin, left: margin, bottom: margin, right: margin)
    super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
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

  private var overlayWindow: UIWindow? = {
    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window.hidden = false
    return window
  }()

  private let overlayViewController: OverlayViewController

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
    overlayWindow?.autoresizingMask = .None
    overlayWindow?.autoresizesSubviews = false
    overlayWindow?.frame = CGRect.zero
    overlayWindow?.hidden = true
    overlayWindow?.rootViewController = nil
    overlayWindow = nil
  }
}

internal extension OverlayWindow {

  /** Convenience storage for the modal overlays (likely interstitials). */
  static var sharedModalOverlay: OverlayWindow?

  /** Application-wide function used to show an interstitial screen. */
  static func presentModalOverlay(viewController: UIViewController) {
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

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    fatalError("The default init is not available for this controller.")
  }

  private let containedViewController: UIViewController

  required init(containedViewController: UIViewController) {
    self.containedViewController = containedViewController
    super.init(nibName: nil, bundle: nil)
  }

  deinit {
    containedViewController.willMoveToParentViewController(nil)
    containedViewController.view.removeFromSuperview()
    containedViewController.removeFromParentViewController()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addChildViewController(self.containedViewController)
    containedViewController.view.frame = view.frame
    view.addSubview(containedViewController.view)
    containedViewController.didMoveToParentViewController(self)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    updateContainedViewControllerLayout()
  }

  private func updateContainedViewControllerLayout() {
    containedViewController.view.frame = view.bounds
    view.backgroundColor = UIColor.clearColor()
  }

  // MARK - Forwarding Methods to Child Controllers

  override func shouldAutomaticallyForwardRotationMethods() -> Bool {
    return true
  }

  override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
    return true
  }

  override func shouldAutorotate() -> Bool {
    return true
  }

  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.AllButUpsideDown
  }

  // MARK - Status bar configuration

  override func childViewControllerForStatusBarStyle() -> UIViewController? {
    return containedViewController
  }

  override func childViewControllerForStatusBarHidden() -> UIViewController? {
    return containedViewController
  }
  
}

