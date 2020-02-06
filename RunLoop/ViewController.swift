//
//  ViewController.swift
//  RunLoop
//
//  Created by Anson on 2020/1/25.
//  Copyright © 2020 Anson. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    typealias RunloopBlock = () -> (Bool)

    /// 是否使用 Runloop 优化
    fileprivate let useRunloop: Bool = true

    /// cell 的高度
    fileprivate let rowHeight: CGFloat = 120

    /// runloop 空闲时执行的代码
    fileprivate var runloopBlockArr: [RunloopBlock] = [RunloopBlock]()

    /// runloopBlockArr 中的最大任务数
    fileprivate var maxQueueLength: Int {
        return (Int(UIScreen.main.bounds.height / rowHeight) + 2)
    }
    
    fileprivate let runLoopBeforeWaitingCallBack = { (ob: CFRunLoopObserver?, ac: CFRunLoopActivity) in
            print("runloop 循环完毕")
        }

  fileprivate lazy var fpsLabel: V2FPSLabel = {
      return V2FPSLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
  }()
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        addRunLoopObServer()
        view.addSubview(fpsLabel)
    }


    fileprivate func addRunLoopObServer() {
        let runloop = CFRunLoopGetCurrent()
            // 需要监听 Runloop 的哪个状态
            let activities = CFRunLoopActivity.beforeWaiting.rawValue
            // 创建 Runloop 观察者
            let observer = CFRunLoopObserverCreateWithHandler(nil, activities, true, 0) { [weak self] (ob, ac) in
                guard let `self` = self else { return }
                guard self.runloopBlockArr.count != 0 else { return }
                // 是否退出任务组
                var quit = false
                // 如果不退出且任务组中有任务存在
                while quit == false && self.runloopBlockArr.count > 0 {
                    // 执行任务
                    guard let block = self.runloopBlockArr.first else { return }
                    // 是否退出任务组
                    quit = block()
                    // 删除已完成的任务
                    let _ = self.runloopBlockArr.removeFirst()
                }
            }
            // 注册 Runloop 观察者
            CFRunLoopAddObserver(runloop, observer, .defaultMode)

      
    }
    
    fileprivate func createRunloopObserver(block: @escaping (CFRunLoopObserver?, CFRunLoopActivity) -> Void) throws -> CFRunLoopObserver {

        /*
         *
         allocator: 分配空间给新的对象。默认情况下使用NULL或者kCFAllocatorDefault。

         activities: 设置Runloop的运行阶段的标志，当运行到此阶段时，CFRunLoopObserver会被调用。

             public struct CFRunLoopActivity : OptionSet {
                 public init(rawValue: CFOptionFlags)
                 public static var entry             //进入工作
                 public static var beforeTimers      //即将处理Timers事件
                 public static var beforeSources     //即将处理Source事件
                 public static var beforeWaiting     //即将休眠
                 public static var afterWaiting      //被唤醒
                 public static var exit              //退出RunLoop
                 public static var allActivities     //监听所有事件
             }

         repeats: CFRunLoopObserver是否循环调用

         order: CFRunLoopObserver的优先级，正常情况下使用0。

         block: 这个block有两个参数：observer：正在运行的run loop observe。activity：runloop当前的运行阶段。返回值：新的CFRunLoopObserver对象。
         */
        let ob = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0, block)
        guard let observer = ob else {
            throw RunloopError.canNotCreate
        }
        return observer
    }

    enum RunloopError:Error {
        case canNotCreate
    }

    
    fileprivate func addRunloopBlock(block: @escaping RunloopBlock) {
        runloopBlockArr.append(block)
        // 快速滚动时，没有来得及显示的 cell 不会进行渲染，只渲染屏幕中出现的 cell
        if runloopBlockArr.count > maxQueueLength {
           let _ = runloopBlockArr.removeFirst()
        }
    }

}

extension ViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if useRunloop {
            return loadCellWithRunloop()
        }
        else {
            return loadCell()
        }
    }
    
    func loadCellWithRunloop() -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell") as? TableViewCell else {
            return UITableViewCell()
        }
        addRunloopBlock { () -> (Bool) in
            let path = Bundle.main.path(forResource: "rose", ofType: "jpg")
            let image = UIImage(contentsOfFile: path ?? "") ?? UIImage()
            cell.config(image: image)
            return false
        }
        return cell
    }

  func loadCell() -> UITableViewCell {
         guard let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell") as? TableViewCell else {
             return UITableViewCell()
         }
         let path = Bundle.main.path(forResource: "rose", ofType: "jpg")
         let image = UIImage(contentsOfFile: path ?? "") ?? UIImage()
         cell.config(image: image)
         return cell
     }
     
}


class TableViewCell: UITableViewCell {
    
    let w = UIScreen.main.bounds.size.width / 3
    var imageViews: [UIImageView] = [UIImageView]()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        for i in 0 ..< 3 {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(i) * w, y: 0, width: w, height: w / 4 * 3))
            imageView.layer.borderWidth = 2
            imageView.layer.borderColor = UIColor.blue.cgColor
            imageView.clipsToBounds = true
            imageViews.append(imageView)
            contentView.addSubview(imageView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func config(image: UIImage) {
        for imageView in imageViews {
            imageView.image = image
        }
    }
    
    func configWithRunloop(image: UIImage, index: Int) {
        imageViews[index].image = image
    }
}
