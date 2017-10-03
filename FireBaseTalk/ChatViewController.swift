

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet var textfield_message: UITextField!
    @IBOutlet var sendButton: UIButton!
    var uid : String?
    var chatRoomUid : String?
    
    public var destinationUid: String?  //채팅할 대상의 uid
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        checkChatRoom()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createRoom() {
        let createRoomInfo : Dictionary<String,Any> = [ "users" : [
            uid! : true,
            destinationUid! : true
            ]
        ]
        if (chatRoomUid == nil) {
            //방 생성 코드
              Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo)
        } else {
            let value : Dictionary<String,Any> = [
                "comments":[
                    "uid" : uid!,
                    "message" : textfield_message.text!
                ]
            ]
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value)
        }
      
    }
  
    func checkChatRoom() {
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value,with: { (datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                self.chatRoomUid = item.key
            }
        })
    }

}
