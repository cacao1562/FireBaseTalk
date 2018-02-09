

import UIKit
import Firebase

class GroupChatRoomViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with:
            { (datasnapshot) in
                let dic = datasnapshot.value as! [String:AnyObject]
                print(dic.count)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
