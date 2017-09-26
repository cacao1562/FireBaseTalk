

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet var sendButton: UIButton!
    
    
    public var destinationUid: String?  //채팅할 대상의 uid
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createRoom() {
        let createRoomInfo = [
            "uid":Auth.auth().currentUser?.uid,
            "destinationUid" : destinationUid
        ]
        Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo)
    }
  

}
