 
import UIKit

class ViewController: UIViewController {
  
  var lastPoint = CGPoint.zero
  var color = UIColor.black
  var brushWidth: CGFloat = 10.0
  var opacity: CGFloat = 1.0
  var swiped = false  // indicates if the brush stroke is continuous.
    
  @IBOutlet weak var mainImageView: UIImageView!
  @IBOutlet weak var tempImageView: UIImageView!
  
  // MARK: - Actions
  
  @IBAction func resetPressed(_ sender: Any) {
    // you drew lines into the image view’s image context, so clearing that out to nil here will reset everything.
    mainImageView.image = nil
  }
  
  @IBAction func sharePressed(_ sender: Any) {
    guard let image = mainImageView.image else {
      return
    }
    let activity = UIActivityViewController(activityItems: [image],
                                            applicationActivities: nil)
    present(activity, animated: true)

  }
  
  @IBAction func pencilPressed(_ sender: UIButton) {
    // make sure its pencil
    guard let pencil = Pencil(tag: sender.tag) else {
      return
    }
    color = pencil.color

    // color white, opacity = 1
    if pencil == .eraser {
      opacity = 1.0
    }
  }
  
  // All touch-notifying methods come from the parent class UIResponder; they fire in response to a touch beginning, moving or ending.

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    swiped = false
    // when the user starts drawing, you can keep track of where the stroke started.
    lastPoint = touch.location(in: view)
  }

  func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
    // app has two image views: mainImageView, which holds the “drawing so far”, and tempImageView, which holds the “line you’re currently drawing”
    UIGraphicsBeginImageContext(view.frame.size)
    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }
    tempImageView.image?.draw(in: view.bounds)
      
    // you get the current touch point and then draw a line from lastPoint to currentPoint
    context.move(to: fromPoint)
    context.addLine(to: toPoint)
    
    // set some drawing parameters for brush size and stroke color
    context.setLineCap(.round)
    context.setBlendMode(.normal)
    context.setLineWidth(brushWidth)
    context.setStrokeColor(color.cgColor)
    
    // DRAW
    context.strokePath()
    
    // wrap up the drawing context to render the new line into the temporary image view.
    tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
    tempImageView.alpha = opacity
    UIGraphicsEndImageContext()
  }

  // The system calls touchesMoved(_:with:) when the user drags a finger along the screen.
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
 
    swiped = true
    let currentPoint = touch.location(in: view)
    drawLine(from: lastPoint, to: currentPoint)
    
    // Finally, you update lastPoint so the next touch event will continue where you just left off.
    lastPoint = currentPoint
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if !swiped {
      // draw a single point
      drawLine(from: lastPoint, to: lastPoint)
    }
      
    // Merge tempImageView into mainImageView. using tempView so we can arrange opacity later.
    UIGraphicsBeginImageContext(mainImageView.frame.size)
    mainImageView.image?.draw(in: view.bounds, blendMode: .normal, alpha: 1.0)
    tempImageView?.image?.draw(in: view.bounds, blendMode: .normal, alpha: opacity)
    mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
      
    tempImageView.image = nil
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard
      let navController = segue.destination as? UINavigationController,
      let settingsController = navController.topViewController as? SettingsViewController
    else {
        return
    }
    settingsController.delegate = self
    settingsController.brush = brushWidth
    settingsController.opacity = opacity
    
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: nil)
    settingsController.red = red
    settingsController.green = green
    settingsController.blue = blue

  }

  
  
}

 // MARK: - SettingsViewControllerDelegate

 extension ViewController: SettingsViewControllerDelegate {
   func settingsViewControllerFinished(_ settingsViewController: SettingsViewController) {
     brushWidth = settingsViewController.brush
     opacity = settingsViewController.opacity
    color = UIColor(red: settingsViewController.red,
                    green: settingsViewController.green,
                    blue: settingsViewController.blue,
                    alpha: opacity)

     dismiss(animated: true)
   }
 }
