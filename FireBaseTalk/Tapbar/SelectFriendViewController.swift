

import UIKit
import Firebase
import BEMCheckBox

class SelectFriendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BEMCheckBoxDelegate {
    
    var users = Dictionary<String,Bool>()
    var array: [UserModel] = []
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let view = tableView.dequeueReusableCell(withIdentifier: "SelectFriendCell", for: indexPath) as! SelectFriendCell
        view.labelName.text = array[indexPath.row].name
        view.imageviewProfile.kf.setImage(with: URL(string:array[indexPath.row].profileImageUrl!))
        view.checkbox.delegate = self
        view.checkbox.tag = indexPath.row
        
        return view
    }
    
    func didTap(_ checkBox: BEMCheckBox) {
        
        if (checkBox.on) {
            users[self.array[checkBox.tag].uid!] = true
        }else {
            users.removeValue(forKey: self.array[checkBox.tag].uid!)
        }
    }
    
    func createRoom(){
        var myUid = Auth.auth().currentUser?.uid
        users[myUid!] = true
        let nsDic = users as! NSDictionary
        Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Database.database().reference().child("users").observe(DataEventType.value, with: { (snapshot) in
            
            self.array.removeAll()  //중복삭제
            
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children{
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                userModel.setValuesForKeys(fchild.value as! [String : Any])
                
                if(userModel.uid == myUid) {
                    continue
                }
                
                self.array.append(userModel)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData();
                
            }
        })
        button.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    



}

class SelectFriendCell : UITableViewCell {
    
    @IBOutlet weak var imageviewProfile: UIImageView!
    @IBOutlet weak var checkbox: BEMCheckBox!
    @IBOutlet weak var labelName: UILabel!
}




