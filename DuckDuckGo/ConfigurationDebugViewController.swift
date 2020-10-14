//
//  ConfigurationDebugViewController.swift
//  DuckDuckGo
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import BackgroundTasks
import Core

@available(iOS 13.0, *)
class ConfigurationDebugViewController: UITableViewController {

    private let titles = [
        Sections.refreshInformation: "Background Refresh Info",
        Sections.queuedTasks: "Queued Tasks (Earliest Execution Date)"
    ]

    enum Sections: Int, CaseIterable {

        case refreshInformation
        case queuedTasks

    }

    enum RefreshInformationRows: Int, CaseIterable {

        case lastRefreshDate
        case resetLastRefreshDate

    }

    @UserDefaultsWrapper(key: .lastConfigurationRefreshDate, defaultValue: .distantPast)
    private var lastConfigurationRefreshDate: Date
    private var queuedTasks: [BGTaskRequest] = []

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        BGTaskScheduler.shared.getPendingTaskRequests { tasks in
            self.queuedTasks = tasks

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Sections(rawValue: section) else { return nil }
        return titles[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        switch Sections(rawValue: indexPath.section) {

        case .refreshInformation:
            switch RefreshInformationRows(rawValue: indexPath.row) {
            case .lastRefreshDate:
                if lastConfigurationRefreshDate == Date.distantPast {
                    cell.textLabel?.text = "Last Refresh Date: Never"
                } else {
                    cell.textLabel?.text = "Last Refresh Date: \(dateFormatter.string(from: lastConfigurationRefreshDate))"
                }
            case .resetLastRefreshDate:
                cell.textLabel?.text = "Reset Last Refresh Date"
            default: break
            }

        case .queuedTasks:
            cell.textLabel?.text = dateFormatter.string(from: queuedTasks[indexPath.row].earliestBeginDate!)

        default: break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section) {
        case .refreshInformation: return RefreshInformationRows.allCases.count
        case .queuedTasks: return queuedTasks.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Sections(rawValue: indexPath.section) {
        case .refreshInformation:
            switch RefreshInformationRows(rawValue: indexPath.row) {
            case .resetLastRefreshDate:
                lastConfigurationRefreshDate = Date.distantPast
                tableView.reloadData()
            default: break
            }
        default: break
        }
    }

}
