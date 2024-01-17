//
//  SessionsViewController.swift
//  FaceLandmarker
//
//  Created by Hans zhu on 1/9/24.
//

import SwiftUI

class SessionsViewController: UITableViewController {
    var sessions: [(Date,Double)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure the view if needed
        print("Session Dates: \(sessions)")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let (sessionDate,ratio) = sessions[indexPath.row] //match the tuple
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        cell.textLabel?.text = "\(dateFormatter.string(from: sessionDate)), Score: \(ratio)"
        return cell
    }
}

