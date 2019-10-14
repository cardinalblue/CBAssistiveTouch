# CBAssistiveTouch

A custom assistive button like system AssistiveTouch. 

## 🧰 Installation

- Set up [cardinalblue cocoapods private repo](https://github.com/cardinalblue/CocoaPodsSpecs)

- `pod install CBAssistiveTouch`

## 📖 Usage

#### Enable assistiveTouch.

Create an assistiveTouch with custom layout and content on application window.
 
```swift

// AppDelegate.swift

private lazy var assistiveTouch: AssistiveTouch = {
  let layout = DefaultAssitiveTouchLayout(keyWindow: self.window)
  let contentViewController = ViewController()
  return AssistiveTouch(applicationWindow: window, 
                                   layout: layout, 
                    contentViewController: contentViewController)
}()

 func application(_ application: UIApplication,
                  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  assistiveTouch.show()   
}
```

### Display content

The content will show on touch the button and content size is defined by the viewController's `preferredContentSize`  

```swift
 let contentViewController = ViewController()
contentViewController.preferredContentSize = CGSize(width: 300, height: 300)
```

### Customize layout

Passing a custom layout that comfort AssitiveTouchLayout protocol .

```swift
public protocol AssitiveTouchLayout {
    var safeAreaInsets: UIEdgeInsets { get }
    var customView: UIView? { get }
    var margin: CGFloat { get }
    var animationDuration: TimeInterval { get }
    var assitiveTouchSize: CGSize { get }
    var assitiveTouchInitialPosition: CGPoint { get }
}
```

### Change `assistiveTouch` appearence

```swift
  // Example: Use 🛠️ emoji
  let layout = DefaultAssitiveTouchLayout(keyWindow: self.window)
  layout.customView = { () -> UIView in
    let label = UILabel(frame: .zero)
    label.text = "🛠️"
    label.sizeToFit()
    return label
  }()
```

