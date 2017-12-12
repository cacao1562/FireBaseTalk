

import UIKit
import Firebase


class SignupViewController: UIViewController , UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    
    @IBOutlet var email: UITextField!
    @IBOutlet var name: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var signup: UIButton!
    @IBOutlet var cancel: UIButton!
    @IBOutlet var imageView: UIImageView!
    private var imgCheck : Int = 0
    private var spinner : UIActivityIndicatorView!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            m.height.equalTo(20)
            
            spinner = UIActivityIndicatorView()
            spinner.frame = CGRect(x: view.frame.width/2-50, y: view.frame.height/2-50, width: 100, height: 100)
            spinner.color = UIColor.black
            spinner.hidesWhenStopped = true
            self.view.addSubview(spinner)
        }
        
        color = remoteConfig["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color!)
        
        imageView.isUserInteractionEnabled = true //사용자로부터 발생하는 이벤트를 받을것인지
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectPicker)))
        
        signup.backgroundColor = UIColor(hex: color!)
        cancel.backgroundColor = UIColor(hex: color!)
        
        signup.addTarget(self, action: #selector(singupEvent), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
    }
    
    func selectPicker(){
        let alert = UIAlertController(title: "", message: "이미지를 선택하세요", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "camera", style: .default) { (_) in self.cameraPicker() } )
        alert.addAction(UIAlertAction(title: "album", style: .default) { (_) in self.imagePicker() } )
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel))
        self.present(alert, animated: true)
        
    }
    
    
    
    func imagePicker(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        self.present(imagePicker, animated: true)
    }
    
    func cameraPicker(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = true
 
        self.present(picker, animated: false)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageView.image = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismiss(animated: true, completion: nil)
        imgCheck = 1
    }
    
    func singupEvent(){
        
        if ((email.text?.isEmpty)! || (name.text?.isEmpty)! || (password.text?.isEmpty)! || (imgCheck == 0)){
            self.view.makeToast("모두입력 또는 사진선택 하세요", duration: 1.0, position: .top)
            return
        }
        spinner.startAnimating()
        
        Auth.auth().createUser(withEmail: email.text!, password: password.text!) { (user, err) in
            let uid = user?.uid
            
            let image = UIImageJPEGRepresentation(self.imageView.image!, 0.1)
            user?.createProfileChangeRequest().displayName = self.name.text!
            user?.createProfileChangeRequest().commitChanges(completion: nil)
            
            Storage.storage().reference().child("userImage").child(uid!).putData(image!, metadata: nil, completion: { (data, error) in
            let imageUrl = data?.downloadURL()?.absoluteString
                
                let values = ["name":self.name.text!,"profileImageUrl":imageUrl,"uid":Auth.auth().currentUser?.uid]
                
                Database.database().reference().child("users").child(uid!).setValue(values, withCompletionBlock:{ (err,ref) in
                if(err==nil){
                    self.cancelEvent()
                }
                    
                })

            })
            
        }
        
        
    }
    
    func cancelEvent() {
        spinner.stopAnimating()
        self.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}
