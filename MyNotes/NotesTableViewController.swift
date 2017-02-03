import UIKit
import os.log

func CreateStorage(isLocal : Bool) -> Storage {
    if isLocal {
        return LocalStorage()
    } else {
        return GoogleStorage()
    }
}
class NotesTableViewController: UITableViewController {
    
    // MARK: Properties
    var notes = [Note]()
    var storage : Storage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let background = UIImage(named: "BackgroundTableView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        navigationItem.leftBarButtonItem = editButtonItem
        
        if UserDefaults.standard.bool(forKey: "is_local") {
            self.storage = CreateStorage(isLocal: true)
            self.storage?.load(handler: { notes in
                self.notes = notes!
            })
        } else {
            let alertController = UIAlertController(title: "Google SignIn",
                                                    message: "Do you want to use google sheets for store your notes?",
                                                    preferredStyle: .alert)
            
            let noAction = UIAlertAction(title: "No", style: .default, handler: { action in
                self.storage = CreateStorage(isLocal: true)
                UserDefaults.standard.set(true, forKey: "is_local")
            })
            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.present(OAuthViewController(), animated: true, completion: nil)
            })
            
            alertController.addAction(noAction)
            alertController.addAction(yesAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "NoteTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? NoteTableViewCell else {
            fatalError("The dequeue cell is not an instance of NoteTableViewCell")
        }
        
        let note = notes[indexPath.row]
        cell.setNote(note)
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            notes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            storage?.delete(index: indexPath.row )
        } else if editingStyle == .insert {}
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddNote":
            os_log("Adding a new note", log: OSLog.default, type: .debug)
            
        case "Edit":
            guard let noteEditViewController = segue.destination as? NoteViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedNoteCell = sender as? NoteTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedNoteCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedNote = notes[indexPath.row]
            noteEditViewController.note = selectedNote
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    @IBAction func unwindToNotesTable(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NoteViewController, let note = sourceViewController.note {
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                let oldNote = notes[selectedIndexPath.row]
                
                //TODO check how to compare two objects by fields
                if oldNote.title != note.title ||
                    oldNote.text != note.text ||
                    oldNote.date != note.date {
                    notes[selectedIndexPath.row] = note
                    tableView.reloadRows(at: [selectedIndexPath], with: .none)
                    
                    storage?.update(index: selectedIndexPath.row, note: note)
                }
            } else {
                let newIndexPath = IndexPath(row: notes.count, section: 0)
                notes.append(note)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
                storage?.add(index: newIndexPath.row, note:  note)
            }
        }
    }
}
