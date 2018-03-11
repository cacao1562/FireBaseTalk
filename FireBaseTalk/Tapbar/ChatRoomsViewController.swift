

import UIKit
import Firebase
import Kingfisher

class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    var uid : String!
    var chatrooms : [ChatModel]! = []
    var destinationUsers : [String] = []
    var keys : [String] = []
    
    @IBOutlet var tableview: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

      self.uid = Auth.auth().currentUser?.uid
      self.getChatRoomsList()
    }

  
    
    func getChatRoomsList(){
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                self.chatrooms.removeAll()
                if let chatroomdic = item.value as? [String:AnyObject] {
                    let chatmodel = ChatModel(JSON: chatroomdic)
                    self.keys.append(item.key)
                    self.chatrooms.append(chatmodel!)
                }
            }
            self.tableview.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "RowCell", for:indexPath) as! CustomCell
        var destinationUid : String?
        for item in chatrooms[indexPath.row].users {
            if(item.key != self.uid) {
                destinationUid = item.key
                destinationUsers.append(destinationUid!)
            }
        }
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: {
            (dataSnapshot) in
            let userModel = UserModel()
            userModel.setValuesForKeys(dataSnapshot.value as! [String : AnyObject])
            cell.label_title.text = userModel.name
            let url = URL(string:userModel.profileImageUrl!)
            cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
            cell.imageview.layer.masksToBounds = true
            cell.imageview.kf.setImage(with: url)
            
            if (self.chatrooms[indexPath.row].comments.keys.count == 0) { //마지막메시지 없을경우
                return
            }
//            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
//              
//                DispatchQueue.main.sync {
//                    cell.imageview.image = UIImage(data:data!)
//                    
//                }
//            }).resume()
            
            let lastMessagekey = self.chatrooms[indexPath.row].comments.keys.sorted(){$0>$1}
            cell.label_lastmessage.text = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.message
            let unixTime = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.timestamp
            cell.label_timestamp.text = unixTime?.toDayTime
        })
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        if (self.destinationUsers[indexPath.row].count > 2 ){ //3명 이상일때
            let destinationUid = self.destinationUsers[indexPath.row]
            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
            view.destinationRoom = self.keys[indexPath.row]
            
            self.navigationController?.pushViewController(view, animated: true)
        }else {
            let destinationUid = self.destinationUsers[indexPath.row]
            let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            view.destinationUid = destinationUid
            self.navigationController?.pushViewController(view, animated: true)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class CustomCell : UITableViewCell {
    
    @IBOutlet weak var label_timestamp: UILabel!
    @IBOutlet var label_title: UILabel!
    @IBOutlet var label_lastmessage: UILabel!
    @IBOutlet var imageview: UIImageView!
    
}






