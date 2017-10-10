

import UIKit
import Firebase

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
  
    

    @IBOutlet var tableview: UITableView!
    
    @IBOutlet var textfield_message: UITextField!
    @IBOutlet var sendButton: UIButton!
    var uid : String?
    var chatRoomUid : String?
    
    var comments : [ChatModel.Comment] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let view = tableview.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        view.textLabel?.text = self.comments[indexPath.row].message
        return view
    }
    
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
        checkChatRoom()
        let createRoomInfo : Dictionary<String,Any> = [ "users" : [
            uid! : true,
            destinationUid! : true
            ]
        ]
        if (chatRoomUid == nil) {
            self.sendButton.isEnabled = false
            //방 생성 코드
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock: { (err, rf) in
                if (err == nil) {
                    self.checkChatRoom()
                }
            })
        } else {
            let value : Dictionary<String,Any> = [
               
                    "uid" : uid!,
                    "message" : textfield_message.text!
                
            ]
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value)
        }
      
    }
  
    func checkChatRoom() {
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value,with: { (datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatRoomdic = item.value as? [String:AnyObject] {
                    let chatModel = ChatModel(JSON: chatRoomdic)
                    if(chatModel?.users[self.destinationUid!] == true) {
                        self.chatRoomUid = item.key
                        self.getMessageList()
                    }
                }
                self.chatRoomUid = item.key
                self.sendButton.isEnabled = true
            }
        })
    }
    
    
    func getMessageList() {
        Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments").observe(DataEventType.value , with: { (datasnapshot) in
            self.comments.removeAll()
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                let comment = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                self.comments.append(comment!)
            }
            self.tableview.reloadData()
        })
    }
    
    

}
