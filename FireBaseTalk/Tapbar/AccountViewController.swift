

import UIKit

class AccountViewController: UIViewController {

    @IBOutlet weak var conditionsCommentButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        conditionsCommentButton.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func showAlert() {
        
        let alertController = UIAlertController(title: "상태메시지", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textfield) in
            textfield.placeholder = "상태메시지를 입력해주세요."
        }
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { (action) in
            
        }))
        self.present(alertController, animated: true, completion: nil)
    }

}
